import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/place_picker_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/address_formatter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class _GeoResult {
  final List<AddressComponents> components;
  final String formatted;
  _GeoResult(this.components, this.formatted);
}

class GoogleMapSearchPlacesApi extends StatefulWidget {
  const GoogleMapSearchPlacesApi({super.key});

  @override
  GoogleMapSearchPlacesApiState createState() =>
      GoogleMapSearchPlacesApiState();
}

class GoogleMapSearchPlacesApiState extends State<GoogleMapSearchPlacesApi> {
  static const LatLng _fallbackLatLng = LatLng(18.0735, -15.9582); // Nouakchott

  // Mauritania bounding box — constrains the map camera and search bias
  static final LatLngBounds _mauritaniaBounds = LatLngBounds(
    southwest: const LatLng(14.75, -17.10),
    northeast: const LatLng(27.30, -4.75),
  );
  // Center of Mauritania (used as search bias when GPS is unavailable)
  static const LatLng _mauritaniaCenter = LatLng(20.25, -10.95);

  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _uuid = const Uuid();
  final Completer<GoogleMapController> _mapCompleter = Completer();

  String? _sessionToken;
  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  List<dynamic> _suggestions = [];
  bool _isSearching = false;
  bool _isResolvingAddress = false;
  bool _showSuggestions = false;

  LatLng? _pinLatLng;
  String _resolvedAddress = '';
  List<AddressComponents> _resolvedComponents = [];

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) setState(() => _showSuggestions = true);
    });
    final loc = Constant.currentLocation;
    _pinLatLng = loc != null
        ? LatLng(loc.latitude, loc.longitude)
        : _fallbackLatLng;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reverseGeocode(_pinLatLng!);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final text = _searchController.text.trim();
      if (text.length >= 2) {
        _fetchSuggestions(text);
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  // ── Dual-language parallel search (Arabic + French) ──────────────────────
  // Mauritania uses both Arabic and French for business names. Searching in
  // both languages in parallel and merging results maximises place coverage.
  Future<void> _fetchSuggestions(String input) async {
    setState(() => _isSearching = true);
    try {
      final results = await Future.wait([
        _fetchFromLanguage(input, 'ar'),
        _fetchFromLanguage(input, 'fr'),
      ]);

      // Merge Arabic + French results, deduplicating by place_id.
      // Arabic results come first so their display name wins on duplicates.
      final seen = <String>{};
      final merged = <dynamic>[];
      for (final list in results) {
        for (final p in list) {
          final id = (p['place_id'] ?? '').toString();
          if (id.isNotEmpty && seen.add(id)) merged.add(p);
        }
      }

      if (mounted) {
        setState(() {
          _suggestions = merged;
          _isSearching = false;
        });
      }
    } catch (e) {
      log('Suggestion error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<List<dynamic>> _fetchFromLanguage(String input, String lang) async {
    try {
      final url = StringBuffer(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json');
      url.write('?input=${Uri.encodeComponent(input)}');
      url.write('&key=${Constant.mapAPIKey}');
      url.write('&sessiontoken=$_sessionToken');
      url.write('&language=$lang');
      // Bias by GPS location if available, otherwise use Mauritania's center.
      // radius=1100000 covers the full country so all cities/streets are found.
      final biasLat = Constant.currentLocation?.latitude ?? _mauritaniaCenter.latitude;
      final biasLng = Constant.currentLocation?.longitude ?? _mauritaniaCenter.longitude;
      url.write('&location=$biasLat,$biasLng');
      url.write('&radius=1100000');
      // Strict country restriction to Mauritania
      if (Constant.regionCode.isNotEmpty && Constant.regionCode != 'all') {
        url.write('&components=country:${Constant.regionCode}');
      }
      final res = await http.get(Uri.parse(url.toString()));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          return data['predictions'] ?? [];
        }
      }
    } catch (e) {
      log('[$lang] fetch error: $e');
    }
    return [];
  }

  Future<void> _selectSuggestion(dynamic prediction) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _showSuggestions = false;
      _isResolvingAddress = true;
    });
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?placeid=${prediction['place_id']}&key=${Constant.mapAPIKey}&language=ar&fields=name,geometry,formatted_address,address_components';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final result = body['result'];
        final loc = result?['geometry']?['location'];
        if (loc?['lat'] != null && loc?['lng'] != null) {
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final components = (result['address_components'] as List? ?? [])
              .map((c) => AddressComponents.fromJson(c))
              .toList();

          // Preserve business/place name — it lives in result['name'], never
          // in address_components (so AddressFormatter would strip it).
          final placeName = (result['name'] ?? '').toString().trim();
          final shortAddr = AddressFormatter.formatFromComponents(
            components,
            fallback: (result['formatted_address'] ?? '').toString(),
          );
          final displayAddress =
              (placeName.isNotEmpty && !shortAddr.startsWith(placeName))
                  ? (shortAddr.isNotEmpty ? '$placeName, $shortAddr' : placeName)
                  : (shortAddr.isNotEmpty
                      ? shortAddr
                      : (result['formatted_address'] ?? '').toString());

          setState(() {
            _pinLatLng = LatLng(lat, lng);
            _resolvedComponents = components;
            _resolvedAddress = displayAddress;
            _searchController.text = displayAddress;
            _suggestions = [];
          });
          _sessionToken = _uuid.v4();
          await _animateTo(LatLng(lat, lng));
        }
      }
    } catch (e) {
      log('Place details error: $e');
    }
    if (mounted) setState(() => _isResolvingAddress = false);
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    if (_geocodeDebounce?.isActive ?? false) _geocodeDebounce!.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isResolvingAddress = true);
      try {
        // Run street-address geocoding + nearby place name in parallel
        final geoFuture = _geocodeToAddress(latLng);
        final nameFuture = _nearbyPlaceName(latLng);
        final geo = await geoFuture;
        final placeName = await nameFuture;

        if (!mounted) return;

        final components = geo?.components ?? <AddressComponents>[];
        final shortAddr = geo?.formatted ??
            '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';

        String displayAddress;
        if (placeName != null && placeName.isNotEmpty) {
          // Prepend the business name only if it's not already in the street address
          displayAddress = shortAddr.isNotEmpty && !shortAddr.startsWith(placeName)
              ? '$placeName، $shortAddr'
              : placeName;
        } else {
          displayAddress = shortAddr;
        }

        setState(() {
          _resolvedComponents = components;
          _resolvedAddress = displayAddress;
        });
      } catch (e) {
        log('Reverse geocode error: $e');
        if (mounted) {
          setState(() {
            _resolvedComponents = [];
            _resolvedAddress =
                '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
          });
        }
      } finally {
        if (mounted) setState(() => _isResolvingAddress = false);
      }
    });
  }

  // Returns street/neighborhood address from Google Geocoding API
  Future<_GeoResult?> _geocodeToAddress(LatLng latLng) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=${Constant.mapAPIKey}&language=ar';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['status'] == 'OK' && (body['results'] as List).isNotEmpty) {
          final first = body['results'][0];
          final components = (first['address_components'] as List? ?? [])
              .map((c) => AddressComponents.fromJson(c))
              .toList();
          final formatted = AddressFormatter.formatFromComponents(
            components,
            fallback: first['formatted_address'],
          );
          return _GeoResult(components, formatted);
        }
      }
    } catch (e) {
      log('Geocode error: $e');
    }
    return null;
  }

  // Returns the name of the nearest named establishment within 25 m of the pin
  Future<String?> _nearbyPlaceName(LatLng latLng) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${latLng.latitude},${latLng.longitude}'
          '&radius=25'
          '&key=${Constant.mapAPIKey}'
          '&language=ar';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final places = body['results'] as List? ?? [];
        // Skip pure geographic/administrative types — we only want named venues
        const geoTypes = {
          'country', 'locality', 'sublocality', 'sublocality_level_1',
          'neighborhood', 'route', 'street_address', 'intersection',
          'administrative_area_level_1', 'administrative_area_level_2',
          'administrative_area_level_3', 'political', 'postal_code',
          'natural_feature', 'geocode',
        };
        for (final place in places) {
          final types = (place['types'] as List?)?.cast<String>() ?? <String>[];
          if (types.any((t) => !geoTypes.contains(t))) {
            final name = (place['name'] ?? '').toString().trim();
            if (name.isNotEmpty) return name;
          }
        }
      }
    } catch (e) {
      log('Nearby search error: $e');
    }
    return null;
  }

  Future<void> _animateTo(LatLng target) async {
    final controller = await _mapCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
    );
  }

  Future<void> _useMyLocation() async {
    final loc = Constant.currentLocation;
    if (loc == null) {
      ShowToastDialog.showToast('Current location not available'.tr);
      return;
    }
    final target = LatLng(loc.latitude, loc.longitude);
    setState(() => _pinLatLng = target);
    await _animateTo(target);
    _reverseGeocode(target);
  }

  void _confirm() {
    if (_pinLatLng == null || _resolvedAddress.isEmpty) return;
    final details = PlaceDetailsModel(
      status: 'OK',
      result: Result(
        formattedAddress: _resolvedAddress,
        addressComponents: _resolvedComponents,
        types: const [],
        geometry: Geometry(
          location: Location(
              lat: _pinLatLng!.latitude, lng: _pinLatLng!.longitude),
        ),
      ),
    );
    Get.back(result: details);
  }

  // ── Place type → icon / colour mapping ───────────────────────────────────
  static IconData _iconForTypes(dynamic types) {
    final t = (types as List?)?.cast<String>() ?? <String>[];
    if (t.any((x) => x == 'restaurant' || x == 'food')) return Icons.restaurant;
    if (t.contains('cafe')) return Icons.coffee;
    if (t.any((x) =>
        x == 'grocery_or_supermarket' ||
        x == 'supermarket' ||
        x == 'convenience_store')) { return Icons.shopping_basket; }
    if (t.any((x) => x == 'store' || x == 'shopping_mall')) return Icons.store;
    if (t.any((x) => x == 'hospital' || x == 'pharmacy')) return Icons.local_hospital;
    if (t.any((x) => x == 'school' || x == 'university')) return Icons.school;
    if (t.any((x) => x == 'bank' || x == 'atm')) return Icons.account_balance;
    if (t.contains('gas_station')) return Icons.local_gas_station;
    if (t.any((x) => x == 'lodging' || x == 'hotel')) return Icons.hotel;
    if (t.any((x) => x == 'mosque' || x == 'place_of_worship')) return Icons.account_balance;
    if (t.any((x) => x == 'locality' || x == 'administrative_area_level_1')) return Icons.location_city;
    if (t.any((x) => x == 'route' || x == 'street_address')) return Icons.alt_route;
    return Icons.location_on;
  }

  static Color _colorForTypes(dynamic types) {
    final t = (types as List?)?.cast<String>() ?? <String>[];
    if (t.any((x) => x == 'restaurant' || x == 'food')) return Colors.orange;
    if (t.contains('cafe')) return const Color(0xFF795548);
    if (t.any((x) =>
        x == 'grocery_or_supermarket' ||
        x == 'supermarket' ||
        x == 'convenience_store')) { return Colors.green; }
    if (t.any((x) => x == 'hospital' || x == 'pharmacy')) return Colors.red;
    if (t.any((x) => x == 'school' || x == 'university')) return Colors.blue;
    if (t.any((x) => x == 'bank' || x == 'atm')) return Colors.indigo;
    if (t.contains('gas_station')) return Colors.deepPurple;
    if (t.any((x) => x == 'lodging' || x == 'hotel')) return Colors.teal;
    return AppColors.darkModePrimary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();
    final initialPosition = _pinLatLng ?? _fallbackLatLng;
    final canConfirm = _resolvedAddress.isNotEmpty && !_isResolvingAddress;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: initialPosition, zoom: 15),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            cameraTargetBounds: CameraTargetBounds(_mauritaniaBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
            onMapCreated: (c) {
              if (!_mapCompleter.isCompleted) _mapCompleter.complete(c);
            },
            onCameraMove: (pos) => _pinLatLng = pos.target,
            onCameraIdle: () {
              if (_pinLatLng != null) _reverseGeocode(_pinLatLng!);
            },
          ),
          _buildCenterPin(),
          _buildSearchCard(isDark),
          _buildLocateMeButton(isDark),
          _buildBottomCard(isDark, canConfirm),
        ],
      ),
    );
  }

  Widget _buildCenterPin() {
    return const IgnorePointer(
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 36),
          child: Icon(Icons.location_pin,
              color: AppColors.darkModePrimary,
              size: 48,
              shadows: [
                Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
              ]),
        ),
      ),
    );
  }

  Widget _buildSearchCard(bool isDark) {
    final cardColor = isDark ? AppColors.darkTextField : Colors.white;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────────────────
            Material(
              color: cardColor,
              elevation: 6,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search your location'.tr,
                          hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[500], fontSize: 14),
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.darkModePrimary),
                        ),
                      )
                    else if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                      ),
                  ],
                ),
              ),
            ),

            // ── Suggestions list ─────────────────────────────────────────────
            if (_showSuggestions && _suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                constraints:
                    BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                  itemBuilder: (context, i) {
                    final p = _suggestions[i];
                    final types = p['types'];
                    final main =
                        p['structured_formatting']?['main_text'] ?? '';
                    final secondary =
                        p['structured_formatting']?['secondary_text'] ?? '';
                    final icon = _iconForTypes(types);
                    final color = _colorForTypes(types);

                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      title: Text(
                        main.isNotEmpty
                            ? main
                            : (p['description'] ?? '').toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: secondary.isNotEmpty
                          ? Text(secondary,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          : null,
                      onTap: () => _selectSuggestion(p),
                    );
                  },
                ),
              ),

            // ── Empty state ──────────────────────────────────────────────────
            if (_showSuggestions &&
                _suggestions.isEmpty &&
                !_isSearching &&
                _searchController.text.trim().length >= 2)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.grey[500]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'لم يُعثر على النتائج — حرّك الدبوس على الخريطة لاختيار الموقع يدوياً',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocateMeButton(bool isDark) {
    return Positioned(
      right: 16,
      bottom: 200,
      child: Material(
        color: isDark ? AppColors.darkTextField : Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _useMyLocation,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.my_location,
                color: AppColors.darkModePrimary, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard(bool isDark, bool canConfirm) {
    final cardColor = isDark ? AppColors.darkBackground : Colors.white;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkTextField
                      : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        color: AppColors.darkModePrimary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _isResolvingAddress
                          ? Text('Resolving address...'.tr,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.grey[600]))
                          : Text(
                              _resolvedAddress.isEmpty
                                  ? 'Move the map to pick a location'.tr
                                  : _resolvedAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canConfirm
                        ? AppColors.darkModePrimary
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    elevation: canConfirm ? 2 : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: canConfirm ? _confirm : null,
                  child: Text(
                    'Confirm Location'.tr,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
