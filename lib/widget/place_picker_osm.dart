import 'dart:developer';

import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/osm_map_search_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:provider/provider.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GeoPoint? selectedLocation;
  late MapController mapController;
  Place? place;
  TextEditingController textController = TextEditingController();
  List<GeoPoint> _markers = [];

  @override
  void initState() {
    super.initState();
    mapController = MapController(
      initMapWithUserPosition:
          const UserTrackingOption(enableTracking: false, unFollowUser: true),
    );
  }

  _listerTapPosition() async {
    // Tap on map disabled - use search only, no red pin
  }

  addMarker(GeoPoint? position) async {
    if (position != null) {
      for (var marker in _markers) {
        await mapController.removeMarker(marker);
      }
      setState(() {
        _markers.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await mapController
            .addMarker(position,
                markerIcon: MarkerIcon(
                  icon: Icon(Icons.location_on,
                      size: 26, color: AppColors.primary),
                ))
            .then((v) {
          _markers.add(position);
        });

        try {
          place = await Nominatim.reverseSearch(
            lat: position.latitude,
            lon: position.longitude,
            zoom: 14,
            addressDetails: true,
            extraTags: true,
            nameDetails: true,
          );
        } catch (e) {
          log("Error with Nominatim reverseSearch: $e");
        }
        setState(() {});
        mapController.moveTo(position, animate: true);
      });
    }
  }

  Future<void> _setUserLocation() async {
    try {
      final locationData = await Utils.getCurrentLocation();
      selectedLocation = GeoPoint(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
      );
      // Just move camera to user location, no marker/pin
      await mapController.moveTo(selectedLocation!, animate: true);
      try {
        place = await Nominatim.reverseSearch(
          lat: selectedLocation!.latitude,
          lon: selectedLocation!.longitude,
          zoom: 14,
          addressDetails: true,
          extraTags: true,
          nameDetails: true,
        );
        setState(() {});
      } catch (e) {
        log("Error with Nominatim: $e");
      }
    } catch (e) {
      log("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.getThem()
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            themeChange.getThem() ? AppColors.darkBackground : Colors.white,
        title: Text('Location Picker',
            style: TextStyle(
                color: themeChange.getThem() ? Colors.white : Colors.black)),
        iconTheme: IconThemeData(
            color: themeChange.getThem() ? Colors.white : Colors.black),
      ),
      body: Stack(
        children: [
          OSMFlutter(
            controller: mapController,
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            osmOption: OSMOption(
              userLocationMarker: UserLocationMaker(
                  personMarker: MarkerIcon(
                      iconWidget: Image.asset("assets/images/pickup.png")),
                  directionArrowMarker: MarkerIcon(
                      iconWidget: Image.asset("assets/images/pickup.png"))),
              isPicker: false,
              zoomOption: const ZoomOption(initZoom: 14),
            ),
            onMapIsReady: (active) {
              if (active) {
                _setUserLocation();
                _listerTapPosition();
              }
            },
          ),
          if (place?.displayName != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place?.displayName ?? '',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          Get.back(result: place);
                        },
                        icon: const Icon(
                          Icons.check_circle,
                          size: 40,
                          color: Colors.black,
                        ))
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 00),
                  child: InkWell(
                    onTap: () async {
                      Get.to(const OsmSearchPlacesApi())?.then((value) async {
                        if (value != null) {
                          SearchInfo searchInfo = value;
                          // Auto-confirm: reverse geocode and return immediately
                          try {
                            place = await Nominatim.reverseSearch(
                              lat: searchInfo.point!.latitude,
                              lon: searchInfo.point!.longitude,
                              zoom: 14,
                              addressDetails: true,
                              extraTags: true,
                              nameDetails: true,
                            );
                            // Return the place directly without waiting for user to confirm
                            Get.back(result: place);
                          } catch (e) {
                            log("Error with Nominatim: $e");
                            // Fallback: add marker and let user confirm manually
                            textController = TextEditingController(
                                text: searchInfo.address.toString());
                            await addMarker(searchInfo.point);
                          }
                        }
                      });
                    },
                    child: buildTextField(
                      title: "Search Address".tr,
                      textController: textController,
                    ),
                  ),
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setUserLocation,
        child: Icon(Icons.my_location,
            color: themeChange.getThem()
                ? AppColors.darkModePrimary
                : AppColors.primary),
      ),
    );
  }

  Widget buildTextField(
      {required title, required TextEditingController textController}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: const Icon(
              Icons.location_on,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: title,
          hintStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabled: false,
        ),
      ),
    );
  }
}
