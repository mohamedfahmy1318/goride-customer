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

class GoogleMapSearchPlacesApi extends StatefulWidget {
  const GoogleMapSearchPlacesApi({super.key});

  @override
  GoogleMapSearchPlacesApiState createState() =>
      GoogleMapSearchPlacesApiState();
}

class GoogleMapSearchPlacesApiState extends State<GoogleMapSearchPlacesApi> {
  static const LatLng _fallbackLatLng = LatLng(18.0735, -15.9582); // Nouakchott

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
      if (_focusNode.hasFocus) {
        setState(() => _showSuggestions = true);
      }
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

  Future<void> _fetchSuggestions(String input) async {
    setState(() => _isSearching = true);
    try {
      final url = StringBuffer(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json');
      url.write('?input=${Uri.encodeComponent(input)}');
      url.write('&key=${Constant.mapAPIKey}');
      url.write('&sessiontoken=$_sessionToken');
      url.write('&language=ar');
      if (Constant.currentLocation != null) {
        url.write(
            '&location=${Constant.currentLocation!.latitude},${Constant.currentLocation!.longitude}');
        url.write('&radius=100000');
      }
      if (Constant.regionCode.isNotEmpty && Constant.regionCode != 'all') {
        url.write('&components=country:${Constant.regionCode}');
      }
      final res = await http.get(Uri.parse(url.toString()));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          if (mounted) {
            setState(() {
              _suggestions = data['predictions'] ?? [];
              _isSearching = false;
            });
          }
          return;
        }
        log('Places API error: ${data['status']}');
      }
    } catch (e) {
      log('Suggestion error: $e');
    }
    if (mounted) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _selectSuggestion(dynamic prediction) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _showSuggestions = false;
      _isResolvingAddress = true;
    });
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/details/json?placeid=${prediction['place_id']}&key=${Constant.mapAPIKey}&language=ar';
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
          final formatted = AddressFormatter.formatFromComponents(components,
              fallback: result['formatted_address']);
          setState(() {
            _pinLatLng = LatLng(lat, lng);
            _resolvedComponents = components;
            _resolvedAddress = formatted;
            _searchController.text = formatted;
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
        final url =
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=${Constant.mapAPIKey}&language=ar';
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final body = json.decode(res.body);
          if (body['status'] == 'OK' &&
              (body['results'] as List).isNotEmpty) {
            final first = body['results'][0];
            final components =
                (first['address_components'] as List? ?? [])
                    .map((c) => AddressComponents.fromJson(c))
                    .toList();
            final formatted = AddressFormatter.formatFromComponents(components,
                fallback: first['formatted_address']);
            if (mounted) {
              setState(() {
                _resolvedComponents = components;
                _resolvedAddress = formatted;
              });
            }
            return;
          }
        }
        if (mounted) {
          setState(() {
            _resolvedComponents = [];
            _resolvedAddress =
                '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
          });
        }
      } catch (e) {
        log('Reverse geocode error: $e');
      } finally {
        if (mounted) setState(() => _isResolvingAddress = false);
      }
    });
  }

  Future<void> _animateTo(LatLng target) async {
    final controller = await _mapCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ),
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
            onMapCreated: (c) {
              if (!_mapCompleter.isCompleted) _mapCompleter.complete(c);
            },
            onCameraMove: (pos) {
              _pinLatLng = pos.target;
            },
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
          child: Icon(
            Icons.location_pin,
            color: AppColors.darkModePrimary,
            size: 48,
            shadows: [
              Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
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
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
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
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                  itemBuilder: (context, i) {
                    final p = _suggestions[i];
                    final main =
                        p['structured_formatting']?['main_text'] ?? '';
                    final secondary =
                        p['structured_formatting']?['secondary_text'] ?? '';
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined,
                          color: AppColors.darkModePrimary, size: 20),
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
                          ? Text(
                              secondary,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => _selectSuggestion(p),
                    );
                  },
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
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
                          ? Text(
                              'Resolving address...'.tr,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            )
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: canConfirm ? _confirm : null,
                  child: Text(
                    'Confirm Location'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
