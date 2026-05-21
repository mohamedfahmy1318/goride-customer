import 'dart:async';
import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/model/place_picker_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:provider/provider.dart';

/// Full-screen OSM map picker that returns [PlaceDetailsModel] — same type as
/// the Google Maps picker — so callers don't need two separate result paths.
class OsmMapPickerPage extends StatefulWidget {
  const OsmMapPickerPage({super.key});

  @override
  State<OsmMapPickerPage> createState() => _OsmMapPickerPageState();
}

class _OsmMapPickerPageState extends State<OsmMapPickerPage> {
  // Nouakchott city center
  static final GeoPoint _fallback = GeoPoint(latitude: 18.0735, longitude: -15.9582);

  late final MapController _mapController;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  List<Place> _suggestions = [];
  bool _isSearching = false;
  bool _isResolving = false;
  bool _showSuggestions = false;

  GeoPoint _center = _fallback;
  String _address = '';

  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  // After the user explicitly picks a search suggestion, the moveTo()
  // animation fires region-change events that would otherwise trigger a
  // reverse geocode and overwrite the chosen name with a Plus Code-style
  // address. Skip reverse geocoding until this timestamp passes.
  DateTime? _skipGeocodeUntil;

  @override
  void initState() {
    super.initState();
    final loc = Constant.currentLocation;
    _center = loc != null
        ? GeoPoint(latitude: loc.latitude, longitude: loc.longitude)
        : _fallback;
    _mapController = MapController.withPosition(initPosition: _center);
    _searchController.addListener(_onSearchTextChanged);
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus && mounted) setState(() => _showSuggestions = true);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _mapController.listenerRegionIsChanging.removeListener(_onRegionChanging);
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapReady(bool ready) {
    if (!ready) return;
    _mapController.listenerRegionIsChanging.addListener(_onRegionChanging);
    _reverseGeocode(_center);
  }

  void _onRegionChanging() {
    final region = _mapController.listenerRegionIsChanging.value;
    if (region == null) return;
    _center = region.center;
    final skipUntil = _skipGeocodeUntil;
    if (skipUntil != null && DateTime.now().isBefore(skipUntil)) {
      // User just picked from search — keep their chosen name, don't overwrite.
      return;
    }
    if (_geocodeDebounce?.isActive ?? false) _geocodeDebounce!.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 700), () {
      _reverseGeocode(_center);
    });
  }

  Future<void> _reverseGeocode(GeoPoint point) async {
    if (!mounted) return;
    setState(() => _isResolving = true);
    try {
      final place = await Nominatim.reverseSearch(
        lat: point.latitude,
        lon: point.longitude,
        addressDetails: true,
        nameDetails: true,
        language: 'ar',
        zoom: 14,
      );
      if (mounted) setState(() { _address = _formatPlace(place); _isResolving = false; });
    } catch (e) {
      log('OSM reverse geocode: $e');
      if (mounted) setState(() => _isResolving = false);
    }
  }

  void _onSearchTextChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final text = _searchController.text.trim();
      if (text.length >= 2) {
        _fetchSuggestions(text);
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (mounted) setState(() => _isSearching = true);
    try {
      final code = Constant.regionCode.toLowerCase();
      final results = await Nominatim.searchByName(
        query: query,
        limit: 10,
        addressDetails: true,
        nameDetails: true,
        language: 'ar',
        countryCodes: (code.isNotEmpty && code != 'all') ? [code] : null,
      );
      if (mounted) setState(() { _suggestions = results; _isSearching = false; });
    } catch (e) {
      log('OSM search: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSuggestion(Place place) async {
    FocusScope.of(context).unfocus();
    final point = GeoPoint(latitude: place.lat, longitude: place.lon);
    final addr = _formatPlace(place);
    // Block reverse geocode for the next 2s so the moveTo animation doesn't
    // overwrite the user's chosen name with a generic reverse-geocoded one.
    _skipGeocodeUntil = DateTime.now().add(const Duration(seconds: 2));
    if (_geocodeDebounce?.isActive ?? false) _geocodeDebounce!.cancel();
    setState(() {
      _showSuggestions = false;
      _searchController.text = addr;
      _suggestions = [];
      _center = point;
      _address = addr;
    });
    await _mapController.moveTo(point, animate: true);
    await _mapController.setZoom(zoomLevel: 15);
  }

  Future<void> _useMyLocation() async {
    final loc = Constant.currentLocation;
    if (loc == null) return;
    final point = GeoPoint(latitude: loc.latitude, longitude: loc.longitude);
    _center = point;
    await _mapController.moveTo(point, animate: true);
    _reverseGeocode(point);
  }

  void _confirm() {
    if (_address.isEmpty) return;
    Get.back(
      result: PlaceDetailsModel(
        status: 'OK',
        result: Result(
          formattedAddress: _address,
          addressComponents: const [],
          types: const [],
          geometry: Geometry(
            location: Location(lat: _center.latitude, lng: _center.longitude),
          ),
        ),
      ),
    );
  }

  static String _formatPlace(Place place) {
    final addr = place.address;
    final nameAr = (place.nameDetails?['name:ar'] ?? place.nameDetails?['name'] ?? '')
        .toString()
        .trim();
    final suburb = (addr?['suburb'] ?? addr?['neighbourhood'] ?? addr?['quarter'] ?? '')
        .toString()
        .trim();
    final city = (addr?['city'] ?? addr?['town'] ?? addr?['village'] ?? addr?['county'] ?? '')
        .toString()
        .trim();

    final parts = <String>[];
    if (nameAr.isNotEmpty) {
      parts.add(nameAr);
    } else if (suburb.isNotEmpty) {
      parts.add(suburb);
    }
    if (city.isNotEmpty && city != (parts.isNotEmpty ? parts[0] : '')) {
      parts.add(city);
    }
    if (parts.isNotEmpty) return parts.join('، ');

    return place.displayName.split(',').take(2).map((s) => s.trim()).join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();
    final canConfirm = _address.isNotEmpty && !_isResolving;
    return Scaffold(
      body: Stack(
        children: [
          OSMFlutter(
            controller: _mapController,
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            osmOption: const OSMOption(
              isPicker: true,
              zoomOption: ZoomOption(initZoom: 14, minZoomLevel: 5, maxZoomLevel: 19),
            ),
            onMapIsReady: _onMapReady,
          ),
          _buildSearchOverlay(isDark),
          Positioned(
            right: 16,
            bottom: 180,
            child: Material(
              color: isDark ? AppColors.darkTextField : Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _useMyLocation,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.my_location, color: AppColors.darkModePrimary, size: 24),
                ),
              ),
            ),
          ),
          _buildBottomCard(isDark, canConfirm),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay(bool isDark) {
    final cardColor = isDark ? AppColors.darkTextField : Colors.white;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          children: [
            Material(
              color: cardColor,
              elevation: 6,
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
                        focusNode: _searchFocus,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search your location here'.tr,
                          hintStyle:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
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
                              strokeWidth: 2,
                              color: AppColors.darkModePrimary),
                        ),
                      )
                    else if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (_showSuggestions && _suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6),
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.42),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.15)),
                  itemBuilder: (context, i) {
                    final p = _suggestions[i];
                    final mainText = (p.nameDetails?['name:ar'] ??
                            p.nameDetails?['name'] ??
                            p.displayName.split(',').first)
                        .toString()
                        .trim();
                    final sub =
                        (p.address?['suburb'] ?? p.address?['neighbourhood'] ?? '')
                            .toString()
                            .trim();
                    final city =
                        (p.address?['city'] ?? p.address?['town'] ?? p.address?['village'] ?? '')
                            .toString()
                            .trim();
                    final secondary = [sub, city]
                        .where((s) => s.isNotEmpty && s != mainText)
                        .join('، ');
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              AppColors.darkModePrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on,
                            size: 18, color: AppColors.darkModePrimary),
                      ),
                      title: Text(mainText,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'لم يُعثر على نتائج — حرّك الخريطة لاختيار الموقع يدوياً',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600], height: 1.4),
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
                offset: const Offset(0, -4))
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
                      child: _isResolving
                          ? Text('Resolving address...'.tr,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]))
                          : Text(
                              _address.isEmpty
                                  ? 'Move the map to pick a location'.tr
                                  : _address,
                              style: TextStyle(
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: canConfirm ? _confirm : null,
                  child: Text('Confirm Location'.tr,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
