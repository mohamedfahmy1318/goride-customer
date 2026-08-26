import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/model/place_picker_model.dart';
import 'package:customer/utils/address_formatter.dart';
import 'package:geocoding/geocoding.dart' as native;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:osm_nominatim/osm_nominatim.dart';

/// A pickup/drop-off point resolved to text a driver can act on.
///
/// [title] is what the driver looks for on the street (a venue, a street, a
/// neighbourhood); [subtitle] places it (neighbourhood, city). Everything
/// downstream — the home screen field, the order document, the driver card —
/// renders these two lines, never a raw geocoder string.
class ResolvedAddress {
  final String title;
  final String subtitle;
  final List<AddressComponents> components;

  const ResolvedAddress({
    required this.title,
    this.subtitle = '',
    this.components = const [],
  });

  static const ResolvedAddress empty = ResolvedAddress(title: '');

  bool get isEmpty => title.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Single-line form kept for the legacy `sourceLocationName` wire field and
  /// for text inputs. The separator is the Arabic comma so the driver app can
  /// split it back into two lines for orders placed before the structured
  /// fields existed.
  String get display => subtitle.isEmpty ? title : '$title، $subtitle';

  factory ResolvedAddress.fromCoordinates(double lat, double lng) =>
      ResolvedAddress(
        title: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      );

  ResolvedAddress copyWith({String? title, String? subtitle}) =>
      ResolvedAddress(
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        components: components,
      );
}

/// Thrown when we cannot get a fix at all. [reason] distinguishes the cases
/// the UI has to handle differently (services off vs. permission refused).
class LocationUnavailable implements Exception {
  final String
      reason; // 'service_off' | 'denied' | 'denied_forever' | 'timeout'
  const LocationUnavailable(this.reason);
  @override
  String toString() => 'LocationUnavailable($reason)';
}

/// GPS acquisition + reverse geocoding, the way the big ride-hailing apps do
/// it: never trust the first fix the OS hands back, and never show the raw
/// geocoder string.
///
/// Acquisition waits for a fix that is actually accurate enough to place a
/// pickup pin (<= [_targetAccuracyMeters]) instead of accepting whatever cell
/// tower estimate `getCurrentPosition()` returns first, with a fresh
/// last-known fix as the instant-start fast path and the best sample seen as
/// the timeout fallback.
class LocationResolver {
  LocationResolver._();

  /// A pickup pin drawn from a fix worse than this is visibly wrong on the
  /// map, so we keep waiting for a better sample until [_fixTimeout].
  static const double _targetAccuracyMeters = 50;

  /// Beyond this a cached fix is stale enough that the rider may have moved.
  static const Duration _lastKnownMaxAge = Duration(seconds: 30);

  static const Duration _fixTimeout = Duration(seconds: 12);

  static Position? _lastGoodFix;

  /// The most recent fix we accepted, for callers that want a synchronous
  /// starting point (map camera, search bias) without awaiting a new one.
  static Position? get lastGoodFix => _lastGoodFix ?? Constant.currentLocation;

  // ── Acquisition ─────────────────────────────────────────────────────────

  /// Returns the rider's position, waiting (up to [_fixTimeout]) for a fix
  /// accurate enough to book from.
  ///
  /// Throws [LocationUnavailable] rather than a bare string so callers can
  /// tell "turn on GPS" apart from "grant permission".
  static Future<Position> currentPosition({bool forceFresh = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationUnavailable('service_off');
      }
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable('denied_forever');
    }
    if (permission == LocationPermission.denied) {
      throw const LocationUnavailable('denied');
    }

    if (!forceFresh) {
      final last = await _freshLastKnown();
      if (last != null) {
        _lastGoodFix = last;
        Constant.currentLocation = last;
        return last;
      }
    }

    final position = await _awaitAccurateFix();
    _lastGoodFix = position;
    Constant.currentLocation = position;
    return position;
  }

  static Future<Position?> _freshLastKnown() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) return null;
      final age = DateTime.now().difference(last.timestamp);
      if (age > _lastKnownMaxAge) return null;
      if (last.accuracy <= 0 || last.accuracy > _targetAccuracyMeters) {
        return null;
      }
      return last;
    } catch (_) {
      return null;
    }
  }

  /// Listens to the position stream and settles on the first sample accurate
  /// enough to book from; on timeout it settles for the best sample seen, and
  /// only if the stream produced nothing does it fall back to a one-shot fix.
  static Future<Position> _awaitAccurateFix() async {
    final completer = Completer<Position>();
    Position? best;
    StreamSubscription<Position>? sub;
    Timer? timer;

    void finish(Position position) {
      if (completer.isCompleted) return;
      timer?.cancel();
      sub?.cancel();
      completer.complete(position);
    }

    void fail(Object error) {
      if (completer.isCompleted) return;
      timer?.cancel();
      sub?.cancel();
      completer.completeError(error);
    }

    bool better(Position candidate) =>
        best == null ||
        (candidate.accuracy > 0 && candidate.accuracy < best!.accuracy);

    try {
      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).listen(
        (position) {
          if (better(position)) best = position;
          if (position.accuracy > 0 &&
              position.accuracy <= _targetAccuracyMeters) {
            finish(position);
          }
        },
        onError: (Object e) => log('LocationResolver stream error: $e'),
        cancelOnError: false,
      );
    } catch (e) {
      log('LocationResolver stream unavailable: $e');
    }

    timer = Timer(_fixTimeout, () async {
      final sample = best;
      if (sample != null) {
        finish(sample);
        return;
      }
      try {
        final oneShot = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        finish(oneShot);
      } catch (_) {
        final stale = await Geolocator.getLastKnownPosition();
        if (stale != null) {
          finish(stale);
        } else {
          fail(const LocationUnavailable('timeout'));
        }
      }
    });

    return completer.future;
  }

  // ── Reverse geocoding ───────────────────────────────────────────────────

  // ~11 m buckets: repeated pin nudges and rebuilds reuse one lookup instead
  // of burning a Geocoding call each time.
  static final Map<String, ResolvedAddress> _cache = {};
  static const int _cacheLimit = 60;

  /// Resolves coordinates to a two-line address, trying (in order) the Google
  /// Geocoding + Places pair, the platform geocoder, Nominatim, and finally
  /// the coordinates themselves — so this never returns nothing.
  static Future<ResolvedAddress> resolve(
    double latitude,
    double longitude, {
    String language = 'ar',
  }) async {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}:$language';
    final cached = _cache[key];
    if (cached != null) return cached;

    ResolvedAddress result = ResolvedAddress.empty;

    if (Constant.mapAPIKey.isNotEmpty && Constant.selectedMapType != 'osm') {
      result = await _googleResolve(latitude, longitude, language);
    }
    if (result.isEmpty) {
      result = await _platformResolve(latitude, longitude, language);
    }
    if (result.isEmpty) {
      result = await _nominatimResolve(latitude, longitude);
    }
    if (result.isEmpty) {
      result = ResolvedAddress.fromCoordinates(latitude, longitude);
    }

    if (_cache.length >= _cacheLimit) _cache.remove(_cache.keys.first);
    _cache[key] = result;
    return result;
  }

  /// Google Geocoding (street/neighbourhood) and Places nearby (the venue the
  /// rider is standing at) run in parallel — the venue name is what makes a
  /// pickup findable, and it never appears in address_components.
  static Future<ResolvedAddress> _googleResolve(
      double lat, double lng, String language) async {
    try {
      final results = await Future.wait([
        _geocode(lat, lng, language),
        _nearbyVenueName(lat, lng, language),
      ]);
      final geo = results[0] as _GeoResult?;
      final venue = results[1] as String?;

      final components = geo?.components ?? const <AddressComponents>[];
      final componentTitle = AddressFormatter.titleFromComponents(components);
      final title =
          (venue != null && venue.isNotEmpty) ? venue : componentTitle;
      if (title.isEmpty) return ResolvedAddress.empty;

      var subtitle = AddressFormatter.subtitleFromComponents(components, title);
      // With a venue as the title, the street it sits on is the most useful
      // second line — prepend it before the neighbourhood/city.
      if (venue != null &&
          venue.isNotEmpty &&
          componentTitle.isNotEmpty &&
          componentTitle != venue) {
        subtitle =
            subtitle.isEmpty ? componentTitle : '$componentTitle، $subtitle';
      }
      if (subtitle.isEmpty) {
        subtitle = AddressFormatter.clean(geo?.formatted, maxParts: 2);
        if (subtitle == title) subtitle = '';
      }

      return ResolvedAddress(
        title: title,
        subtitle: AddressFormatter.clean(subtitle, maxParts: 2),
        components: components,
      );
    } catch (e) {
      log('LocationResolver google error: $e');
      return ResolvedAddress.empty;
    }
  }

  static Future<_GeoResult?> _geocode(
      double lat, double lng, String language) async {
    try {
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng'
          '&key=${Constant.mapAPIKey}&language=$language');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      if (body['status'] != 'OK') return null;
      final list = (body['results'] as List?) ?? const [];
      if (list.isEmpty) return null;

      // Google returns coarser and coarser results; the first entry whose
      // types name a building or street is the one a driver can use.
      const preferred = [
        'street_address',
        'premise',
        'subpremise',
        'point_of_interest',
        'establishment',
        'route',
      ];
      Map<String, dynamic>? chosen;
      for (final type in preferred) {
        for (final r in list) {
          final types = (r['types'] as List?)?.cast<String>() ?? const [];
          if (types.contains(type)) {
            chosen = r as Map<String, dynamic>;
            break;
          }
        }
        if (chosen != null) break;
      }
      chosen ??= list.first as Map<String, dynamic>;

      final components = ((chosen['address_components'] as List?) ?? const [])
          .map((c) => AddressComponents.fromJson(c))
          .toList();
      for (final c in components) {
        final types = c.types ?? const [];
        if (types.contains('country')) Constant.country = c.longName;
        if (types.contains('locality')) Constant.city = c.longName;
      }
      return _GeoResult(
        components,
        (chosen['formatted_address'] ?? '').toString(),
      );
    } catch (e) {
      log('LocationResolver geocode error: $e');
      return null;
    }
  }

  /// Name of the nearest named venue. Kept tight (50 m) so we label the pin
  /// with a place the rider is actually at, not a landmark down the road.
  static Future<String?> _nearbyVenueName(
      double lat, double lng, String language) async {
    try {
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$lat,$lng&radius=50&key=${Constant.mapAPIKey}'
          '&language=$language');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final places = (body['results'] as List?) ?? const [];
      const geoTypes = {
        'country',
        'locality',
        'sublocality',
        'sublocality_level_1',
        'neighborhood',
        'route',
        'street_address',
        'intersection',
        'administrative_area_level_1',
        'administrative_area_level_2',
        'administrative_area_level_3',
        'political',
        'postal_code',
        'natural_feature',
        'geocode',
        'plus_code',
      };
      for (final place in places) {
        final types = (place['types'] as List?)?.cast<String>() ?? const [];
        if (types.every(geoTypes.contains)) continue;
        final name = (place['name'] ?? '').toString().trim();
        if (name.isNotEmpty && !AddressFormatter.isNoise(name)) return name;
      }
    } catch (e) {
      log('LocationResolver nearby error: $e');
    }
    return null;
  }

  /// Platform geocoder, asked in the rider's language — without
  /// `setLocaleIdentifier` iOS/Android answer in the device locale, which is
  /// how mixed Arabic/French pickups reached drivers.
  static Future<ResolvedAddress> _platformResolve(
      double lat, double lng, String language) async {
    try {
      try {
        await native.setLocaleIdentifier(language);
      } catch (_) {
        // Not supported everywhere; the lookup below still works.
      }
      final marks = await native.placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return ResolvedAddress.empty;
      final pm = marks.first;
      Constant.country = pm.country;
      Constant.city = pm.locality;

      final candidates = <String>[
        (pm.name ?? '').trim(),
        (pm.thoroughfare ?? '').trim(),
        (pm.subLocality ?? '').trim(),
        (pm.locality ?? '').trim(),
      ].where((c) => c.isNotEmpty && !AddressFormatter.isNoise(c)).toList();
      if (candidates.isEmpty) return ResolvedAddress.empty;

      final title = candidates.first;
      final subtitle =
          candidates.skip(1).where((c) => c != title).take(2).join('، ');
      return ResolvedAddress(title: title, subtitle: subtitle);
    } catch (e) {
      log('LocationResolver platform geocode error: $e');
      return ResolvedAddress.empty;
    }
  }

  static Future<ResolvedAddress> _nominatimResolve(
      double lat, double lng) async {
    try {
      final place = await Nominatim.reverseSearch(
        lat: lat,
        lon: lng,
        zoom: 18,
        addressDetails: true,
        nameDetails: true,
      );
      final address = place.address ?? const {};
      Constant.country = (address['country'] ?? Constant.country)?.toString();
      Constant.city =
          (address['city'] ?? address['town'] ?? Constant.city)?.toString();

      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key]?.toString().trim();
          if (value != null &&
              value.isNotEmpty &&
              !AddressFormatter.isNoise(value)) {
            return value;
          }
        }
        return null;
      }

      final title = pick([
            'amenity',
            'shop',
            'building',
            'road',
            'neighbourhood',
            'suburb',
            'city',
            'town',
            'village'
          ]) ??
          AddressFormatter.clean(place.displayName, maxParts: 1);
      if (title.isEmpty) return ResolvedAddress.empty;

      final subtitleParts = <String>[];
      for (final part in [
        pick(['neighbourhood', 'suburb', 'quarter']),
        pick(['city', 'town', 'village', 'state']),
      ]) {
        if (part != null && part != title && !subtitleParts.contains(part)) {
          subtitleParts.add(part);
        }
      }
      return ResolvedAddress(title: title, subtitle: subtitleParts.join('، '));
    } catch (e) {
      log('LocationResolver nominatim error: $e');
      return ResolvedAddress.empty;
    }
  }
}

class _GeoResult {
  final List<AddressComponents> components;
  final String formatted;
  _GeoResult(this.components, this.formatted);
}
