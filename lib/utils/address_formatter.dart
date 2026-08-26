import 'package:customer/model/place_picker_model.dart';

/// Turns raw geocoder output into the two-line address shape every rider- and
/// driver-facing surface uses: a short [title] (the venue / street the driver
/// actually looks for) and a [subtitle] that places it (neighbourhood, city).
///
/// This is the single source of truth for address text in the customer app —
/// the home screen, the place picker and the order we ship to the driver all
/// go through it, so a pickup reads the same everywhere.
class AddressFormatter {
  // Google address_component types, most specific first.
  static const List<String> _poiTypes = [
    'point_of_interest',
    'establishment',
    'premise',
    'airport',
  ];

  static const List<String> _neighborhoodTypes = [
    'sublocality_level_1',
    'sublocality',
    'neighborhood',
    'sublocality_level_2',
    'sublocality_level_3',
  ];

  static const List<String> _cityTypes = [
    'locality',
    'postal_town',
    'administrative_area_level_2',
    'administrative_area_level_1',
  ];

  /// Open Location Code ("322R+6P2") — the native geocoder emits these when a
  /// point has no friendly name. Useless to a driver, so they never survive.
  static final RegExp plusCodeRe = RegExp(
    r'^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{2,7}$',
    caseSensitive: false,
  );

  /// Country-level noise: every ride in this deployment is in the same
  /// country, so repeating it costs a line and tells the driver nothing.
  static const Set<String> _countryNoise = {
    'mauritania',
    'mauritanie',
    'موريتانيا',
    'الجمهورية الإسلامية الموريتانية',
  };

  /// True for segments a driver can't navigate by: plus codes, postal codes,
  /// bare numbers. A street number glued to a street name ("12 شارع X") is
  /// NOT numeric noise — only standalone digit runs are.
  static bool isNoise(String segment) {
    final s = segment.trim();
    if (s.isEmpty) return true;
    if (plusCodeRe.hasMatch(s)) return true;
    if (_countryNoise.contains(s.toLowerCase())) return true;
    // Standalone number / postal code (allows separators, no letters).
    if (RegExp(r'^[\d\s\-/]+$').hasMatch(s)) return true;
    return false;
  }

  /// The venue or street a driver navigates to.
  static String titleFromComponents(List<AddressComponents>? components) {
    final poi = _firstMatch(components, _poiTypes);
    if (poi != null) return poi;

    final route = _firstMatch(components, const ['route']);
    if (route != null) {
      // Read the street number raw: on its own it is noise, but attached to
      // the street it is the most useful thing on the line.
      final number =
          _firstMatch(components, const ['street_number'], allowNumeric: true);
      return number == null ? route : '$route $number';
    }

    final neighborhood = _firstMatch(components, _neighborhoodTypes);
    if (neighborhood != null) return neighborhood;

    return _firstMatch(components, _cityTypes) ?? '';
  }

  /// Where that venue/street sits — "neighbourhood, city", minus whatever the
  /// title already said.
  static String subtitleFromComponents(
      List<AddressComponents>? components, String title) {
    final parts = <String>[];
    final neighborhood = _firstMatch(components, _neighborhoodTypes);
    final city = _firstMatch(components, _cityTypes);
    for (final part in [neighborhood, city]) {
      if (part == null || part.isEmpty) continue;
      if (part == title) continue;
      if (parts.contains(part)) continue;
      parts.add(part);
    }
    return parts.join('، ');
  }

  /// Formats Google address_components to "[District/Neighborhood], [City]".
  /// Falls back to filtered formattedAddress (without numeric segments) if
  /// neighborhood/city aren't found, never returns an empty string when input
  /// has any usable text.
  static String formatFromComponents(List<AddressComponents>? components,
      {String? fallback}) {
    final neighborhood = _firstMatch(components, _neighborhoodTypes);
    final city = _firstMatch(components, _cityTypes);

    final parts = <String>[];
    if (neighborhood != null && neighborhood.isNotEmpty)
      parts.add(neighborhood);
    if (city != null && city.isNotEmpty && city != neighborhood)
      parts.add(city);

    if (parts.isNotEmpty) return parts.join('، ');
    final filtered = clean(fallback);
    if (filtered.isNotEmpty) return filtered;
    return (fallback ?? '').trim();
  }

  static String formatFromPlaceDetails(PlaceDetailsModel? details) {
    if (details?.result == null) return '';
    return formatFromComponents(
      details!.result!.addressComponents,
      fallback: details.result!.formattedAddress,
    );
  }

  /// Drops noise segments and consecutive duplicates from a comma-separated
  /// address, keeping at most the two most specific parts.
  static String clean(String? address, {int maxParts = 2}) {
    if (address == null || address.trim().isEmpty) return '';
    final parts = <String>[];
    for (final raw in address.split(RegExp(r'[,،]'))) {
      final part = raw.trim();
      if (isNoise(part)) continue;
      if (parts.isNotEmpty && parts.last == part) continue;
      if (parts.contains(part)) continue;
      parts.add(part);
    }
    if (parts.isEmpty) return address.trim();
    return parts.take(maxParts).join('، ');
  }

  static String? _firstMatch(
      List<AddressComponents>? components, List<String> wanted,
      {bool allowNumeric = false}) {
    if (components == null) return null;
    for (final type in wanted) {
      for (final c in components) {
        if (c.types?.contains(type) != true) continue;
        final name = c.longName?.trim();
        if (name == null || name.isEmpty) continue;
        if (!allowNumeric && isNoise(name)) continue;
        return name;
      }
    }
    return null;
  }
}
