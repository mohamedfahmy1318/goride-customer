import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;
import 'dart:ui' as ui;
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingController extends GetxController {
  GoogleMapController? mapController;
  StreamSubscription? _orderSubscription;
  StreamSubscription? _driverSubscription;
  String _activeDriverId = '';
  bool _isControllerClosed = false;
  bool _hasNavigatedAway = false;

  void setMapController(GoogleMapController controller) {
    if (_isControllerClosed) {
      try {
        controller.dispose();
      } catch (_) {}
      return;
    }

    if (!identical(mapController, controller)) {
      try {
        mapController?.dispose();
      } catch (_) {}
    }

    mapController = controller;
  }

  @override
  void onInit() {
    _isControllerClosed = false;
    _hasNavigatedAway = false;
    addMarkerSetup();
    if (Constant.selectedMapType == 'osm') {
      ShowToastDialog.showLoader("Please wait");
      mapOsmController = MapController(
          initPosition: GeoPoint(latitude: 20.9153, longitude: -100.7439),
          useExternalTracking: false); //OSM
    } else {
      getArgument();
    }

    super.onInit();
  }

  @override
  void onClose() {
    _isControllerClosed = true;
    ShowToastDialog.closeLoader();

    _orderSubscription?.cancel();
    _driverSubscription?.cancel();
    _orderSubscription = null;
    _driverSubscription = null;

    try {
      mapController?.dispose();
    } catch (_) {}

    if (Constant.selectedMapType == 'osm') {
      try {
        mapOsmController.dispose();
      } catch (_) {}
    }

    super.onClose();
  }

  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;
  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<InterCityOrderModel> intercityOrderModel = InterCityOrderModel().obs;

  RxBool isLoading = true.obs;
  RxString type = "".obs;

  getArgument() async {
    log("=====argumentData====");
    dynamic argumentData = Get.arguments;
    log("=====argumentData====$argumentData");
    if (argumentData != null) {
      type.value = argumentData['type'];

      if (type.value == "orderModel") {
        OrderModel argumentOrderModel = argumentData['orderModel'];
        _listenToCityOrder(argumentOrderModel.id);
      } else {
        InterCityOrderModel argumentOrderModel =
            argumentData['interCityOrderModel'];
        _listenToIntercityOrder(argumentOrderModel.id);
      }
    }
    isLoading.value = false;
    update();
  }

  void _listenToCityOrder(String? orderId) {
    final String resolvedOrderId = (orderId ?? '').trim();
    if (resolvedOrderId.isEmpty) {
      return;
    }

    _orderSubscription?.cancel();
    _orderSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.orders)
        .doc(resolvedOrderId)
        .snapshots()
        .listen((event) {
      if (_isControllerClosed || event.data() == null) {
        return;
      }

      orderModel.value = OrderModel.fromJson(event.data()!);
      _listenToDriverUpdates(orderModel.value.driverId, isIntercity: false);

      if (orderModel.value.status == Constant.rideComplete) {
        _navigateBackOnce();
      }
    }, onError: (Object error) {
      log('City order stream error: $error');
    });
  }

  void _listenToIntercityOrder(String? orderId) {
    final String resolvedOrderId = (orderId ?? '').trim();
    if (resolvedOrderId.isEmpty) {
      return;
    }

    _orderSubscription?.cancel();
    _orderSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(resolvedOrderId)
        .snapshots()
        .listen((event) {
      if (_isControllerClosed || event.data() == null) {
        return;
      }

      intercityOrderModel.value = InterCityOrderModel.fromJson(event.data()!);
      _listenToDriverUpdates(intercityOrderModel.value.driverId,
          isIntercity: true);

      if (intercityOrderModel.value.status == Constant.rideComplete) {
        _navigateBackOnce();
      }
    }, onError: (Object error) {
      log('Intercity order stream error: $error');
    });
  }

  void _listenToDriverUpdates(String? driverId,
      {required bool isIntercity}) {
    if (_isControllerClosed) {
      return;
    }

    final String resolvedDriverId = (driverId ?? '').trim();
    if (resolvedDriverId.isEmpty) {
      _driverSubscription?.cancel();
      _driverSubscription = null;
      _activeDriverId = '';
      return;
    }

    if (_activeDriverId == resolvedDriverId && _driverSubscription != null) {
      return;
    }

    _driverSubscription?.cancel();
    _activeDriverId = resolvedDriverId;

    _driverSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(resolvedDriverId)
        .snapshots()
        .listen((event) {
      if (_isControllerClosed || event.data() == null) {
        return;
      }

      driverUserModel.value = DriverUserModel.fromJson(event.data()!);

      if (isIntercity) {
        _handleIntercityDriverUpdate();
      } else {
        _handleCityDriverUpdate();
      }
    }, onError: (Object error) {
      log('Driver stream error: $error');
    });
  }

  void _handleCityDriverUpdate() {
    if (_isControllerClosed) {
      return;
    }

    final double? driverLat = driverUserModel.value.location?.latitude;
    final double? driverLng = driverUserModel.value.location?.longitude;
    if (driverLat == null || driverLng == null) {
      return;
    }

    final bool isInProgress = orderModel.value.status == Constant.rideInProgress;
    final double? targetLat = isInProgress
        ? orderModel.value.destinationLocationLAtLng?.latitude
        : orderModel.value.sourceLocationLAtLng?.latitude;
    final double? targetLng = isInProgress
        ? orderModel.value.destinationLocationLAtLng?.longitude
        : orderModel.value.sourceLocationLAtLng?.longitude;

    if (targetLat == null || targetLng == null) {
      return;
    }

    if (Constant.selectedMapType != 'osm') {
      getPolyline(
          sourceLatitude: driverLat,
          sourceLongitude: driverLng,
          destinationLatitude: targetLat,
          destinationLongitude: targetLng);
      return;
    }

    final GeoPoint departure = GeoPoint(
        latitude: orderModel.value.sourceLocationLAtLng?.latitude ?? 0.0,
        longitude: orderModel.value.sourceLocationLAtLng?.longitude ?? 0.0);
    final GeoPoint destination = isInProgress
        ? GeoPoint(
            latitude:
                orderModel.value.destinationLocationLAtLng?.latitude ?? 0.0,
            longitude:
                orderModel.value.destinationLocationLAtLng?.longitude ?? 0.0)
        : departure;

    getOSMPolyline(
      GeoPoint(latitude: driverLat, longitude: driverLng),
      GeoPoint(latitude: targetLat, longitude: targetLng),
    );
    setOsmMarker(departure: departure, destination: destination);
  }

  void _handleIntercityDriverUpdate() {
    if (_isControllerClosed) {
      return;
    }

    final double? driverLat = driverUserModel.value.location?.latitude;
    final double? driverLng = driverUserModel.value.location?.longitude;
    if (driverLat == null || driverLng == null) {
      return;
    }

    final bool isInProgress =
        intercityOrderModel.value.status == Constant.rideInProgress;
    final double? targetLat = isInProgress
        ? intercityOrderModel.value.destinationLocationLAtLng?.latitude
        : intercityOrderModel.value.sourceLocationLAtLng?.latitude;
    final double? targetLng = isInProgress
        ? intercityOrderModel.value.destinationLocationLAtLng?.longitude
        : intercityOrderModel.value.sourceLocationLAtLng?.longitude;

    if (targetLat == null || targetLng == null) {
      return;
    }

    if (Constant.selectedMapType != 'osm') {
      getPolyline(
          sourceLatitude: driverLat,
          sourceLongitude: driverLng,
          destinationLatitude: targetLat,
          destinationLongitude: targetLng);
      return;
    }

    final GeoPoint departure = GeoPoint(
        latitude: intercityOrderModel.value.sourceLocationLAtLng?.latitude ??
            0.0,
        longitude: intercityOrderModel.value.sourceLocationLAtLng?.longitude ??
            0.0);
    final GeoPoint destination = GeoPoint(
        latitude:
            intercityOrderModel.value.destinationLocationLAtLng?.latitude ??
                0.0,
        longitude:
            intercityOrderModel.value.destinationLocationLAtLng?.longitude ??
                0.0);

    getOSMPolyline(
      GeoPoint(latitude: driverLat, longitude: driverLng),
      GeoPoint(latitude: targetLat, longitude: targetLng),
    );
    setOsmMarker(departure: departure, destination: destination);
  }

  void _navigateBackOnce() {
    if (_hasNavigatedAway || _isControllerClosed) {
      return;
    }

    _hasNavigatedAway = true;
    Future.microtask(() {
      if (_isControllerClosed) {
        return;
      }

      if (Get.key.currentState?.canPop() ?? false) {
        Get.back();
      }
    });
  }

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? driverIcon;

  void getPolyline(
      {required double? sourceLatitude,
      required double? sourceLongitude,
      required double? destinationLatitude,
      required double? destinationLongitude}) async {
    if (sourceLatitude != null &&
        sourceLongitude != null &&
        destinationLatitude != null &&
        destinationLongitude != null) {
      List<LatLng> polylineCoordinates = [];
      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(sourceLatitude, sourceLongitude),
        destination: PointLatLng(destinationLatitude, destinationLongitude),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: polylineRequest,
        googleApiKey: Constant.mapAPIKey,
      );
      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        log(result.errorMessage.toString());
      }

      if (type.value == "orderModel") {
        addMarker(
            latitude: orderModel.value.sourceLocationLAtLng!.latitude,
            longitude: orderModel.value.sourceLocationLAtLng!.longitude,
            id: "Departure",
            descriptor: departureIcon!,
            rotation: 0.0);
        addMarker(
            latitude: orderModel.value.destinationLocationLAtLng!.latitude,
            longitude: orderModel.value.destinationLocationLAtLng!.longitude,
            id: "Destination",
            descriptor: destinationIcon!,
            rotation: 0.0);
        addMarker(
            latitude: driverUserModel.value.location!.latitude,
            longitude: driverUserModel.value.location!.longitude,
            id: "Driver",
            descriptor: driverIcon!,
            rotation: driverUserModel.value.rotation);

        if (polylineCoordinates.isNotEmpty) {
          _addPolyLine(polylineCoordinates);
        }
      } else {
        addMarker(
            latitude: intercityOrderModel.value.sourceLocationLAtLng!.latitude,
            longitude:
                intercityOrderModel.value.sourceLocationLAtLng!.longitude,
            id: "Departure",
            descriptor: departureIcon!,
            rotation: 0.0);
        addMarker(
            latitude:
                intercityOrderModel.value.destinationLocationLAtLng!.latitude,
            longitude:
                intercityOrderModel.value.destinationLocationLAtLng!.longitude,
            id: "Destination",
            descriptor: destinationIcon!,
            rotation: 0.0);
        addMarker(
            latitude: driverUserModel.value.location!.latitude,
            longitude: driverUserModel.value.location!.longitude,
            id: "Driver",
            descriptor: driverIcon!,
            rotation: driverUserModel.value.rotation);

        if (polylineCoordinates.isNotEmpty) {
          _addPolyLine(polylineCoordinates);
        }
      }
    }
  }

  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;

  addMarker(
      {required double? latitude,
      required double? longitude,
      required String id,
      required BitmapDescriptor descriptor,
      required double? rotation}) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
        markerId: markerId,
        icon: descriptor,
        position: LatLng(latitude ?? 0.0, longitude ?? 0.0),
        rotation: rotation ?? 0.0);
    markers[markerId] = marker;
  }

  // Create custom marker with circle and icon
  Future<BitmapDescriptor> createCustomMarker({
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    double size = 120,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = backgroundColor;
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Draw shadow
    canvas.drawCircle(Offset(size / 2, size / 2 + 4), size / 2.5, shadowPaint);

    // Draw main circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.5, paint);

    // Draw white inner circle
    final Paint innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 3, innerPaint);

    // Draw icon
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size / 2.5,
        fontFamily: icon.fontFamily,
        color: backgroundColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
          size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2),
    );

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // Create pickup marker (green with person icon)
  Future<BitmapDescriptor> createPickupMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xff86E837), // Green
      icon: Icons.person,
      iconColor: Colors.white,
      size: 100,
    );
  }

  // Create destination marker (red with flag icon)
  Future<BitmapDescriptor> createDestinationMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xffE74C3C), // Red
      icon: Icons.flag,
      iconColor: Colors.white,
      size: 100,
    );
  }

  // Create driver marker (blue with car icon)
  Future<BitmapDescriptor> createDriverMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xff3498DB), // Blue
      icon: Icons.directions_car,
      iconColor: Colors.white,
      size: 100,
    );
  }

  addMarkerSetup() async {
    if (Constant.selectedMapType != 'osm') {
      // Create custom markers programmatically
      departureIcon = await createPickupMarker();
      destinationIcon = await createDestinationMarker();
      driverIcon = await createDriverMarker();
    } else {
      departureOsmIcon =
          Image.asset("assets/images/pickup.png", width: 30, height: 30); //OSM
      destinationOsmIcon =
          Image.asset("assets/images/dropoff.png", width: 30, height: 30); //OSM
      driverOsmIcon =
          Image.asset("assets/images/ic_cab.png", width: 30, height: 30); //OSM
    }
  }

  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  PolylinePoints polylinePoints = PolylinePoints();

  _addPolyLine(List<LatLng> polylineCoordinates) {
    // Clear previous polylines
    polyLines.clear();

    // Shadow polyline for depth effect
    PolylineId shadowId = const PolylineId("poly_shadow");
    Polyline shadowPolyline = Polyline(
      polylineId: shadowId,
      points: polylineCoordinates,
      width: 10,
      color: Colors.black.withOpacity(0.2),
    );
    polyLines[shadowId] = shadowPolyline;

    // Main polyline with dashed pattern (arrows effect)
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      consumeTapEvents: true,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
      width: 6,
      color: const Color(0xff86E837), // Green color matching app theme
      patterns: [
        PatternItem.dash(20),
        PatternItem.gap(10),
      ],
    );
    polyLines[id] = polyline;

    // Solid polyline underneath for better visibility
    PolylineId solidId = const PolylineId("poly_solid");
    Polyline solidPolyline = Polyline(
      polylineId: solidId,
      points: polylineCoordinates,
      width: 4,
      color: const Color(0xff4CAF50), // Darker green
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
    polyLines[solidId] = solidPolyline;

    updateCameraLocation(
        polylineCoordinates.first, polylineCoordinates.last, mapController);
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (_isControllerClosed || mapController == null) return;

    LatLngBounds bounds;

    if (source.latitude > destination.latitude &&
        source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(source.latitude, destination.longitude),
          northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destination.latitude, source.longitude),
          northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 10);

    return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(
      CameraUpdate cameraUpdate, GoogleMapController mapController,
      {int retryCount = 0}) async {
    if (_isControllerClosed || this.mapController == null) {
      return;
    }

    if (!identical(this.mapController, mapController)) {
      return;
    }

    try {
      await mapController.animateCamera(cameraUpdate);
      if (_isControllerClosed) {
        return;
      }

      LatLngBounds l1 = await mapController.getVisibleRegion();
      LatLngBounds l2 = await mapController.getVisibleRegion();

      if ((l1.southwest.latitude == -90 || l2.southwest.latitude == -90) &&
          retryCount < 3) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return checkCameraLocation(cameraUpdate, mapController,
            retryCount: retryCount + 1);
      }
    } on PlatformException catch (error) {
      final String message = (error.message ?? '').toLowerCase();
      if (error.code == 'channel-error' ||
          message.contains('unable to establish connection on channel')) {
        return;
      }
      log('checkCameraLocation platform error: $error');
    } catch (error) {
      log('checkCameraLocation error: $error');
    }
  }

  //OSM
  late MapController mapOsmController;
  Rx<RoadInfo> roadInfo = RoadInfo().obs;
  Map<String, GeoPoint> osmMarkers = <String, GeoPoint>{};
  Image? departureOsmIcon; //OSM
  Image? destinationOsmIcon; //OSM
  Image? driverOsmIcon;

  void getOSMPolyline(
    GeoPoint location,
    GeoPoint destinationlocation,
  ) async {
    if (_isControllerClosed) {
      return;
    }

    try {
      // GeoPoint destinationLocation;
      // if (type.value == "orderModel") {
      //   if (orderModel.value.status == Constant.rideInProgress) {
      //     destinationLocation =
      //         GeoPoint(latitude: orderModel.value.destinationLocationLAtLng!.latitude ?? 0, longitude: orderModel.value.destinationLocationLAtLng!.longitude ?? 0);
      //   } else {
      //     destinationLocation = GeoPoint(latitude: orderModel.value.sourceLocationLAtLng!.latitude ?? 0, longitude: orderModel.value.sourceLocationLAtLng!.longitude ?? 0);
      //   }
      // } else {
      //   if (type.value == "orderModel") {
      //     destinationLocation =
      //         GeoPoint(latitude: intercityOrderModel.value.destinationLocationLAtLng!.latitude ?? 0, longitude: intercityOrderModel.value.destinationLocationLAtLng!.latitude ?? 0);
      //   } else {
      //     destinationLocation =
      //         GeoPoint(latitude: intercityOrderModel.value.sourceLocationLAtLng!.latitude ?? 0, longitude: intercityOrderModel.value.sourceLocationLAtLng!.latitude ?? 0);
      //   }
      // }
      log("======${location.latitude}==${location.longitude}");
      log("======${destinationlocation.latitude}==${destinationlocation.longitude}");

      await mapOsmController.removeLastRoad();
      roadInfo.value = await mapOsmController.drawRoad(
        location,
        destinationlocation,
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadWidth: 15,
          roadColor:
              AppColors.primary, //themeChange ? AppColors.darkModePrimary :
          zoomInto: false,
        ),
      );
      mapOsmController.moveTo(
        GeoPoint(latitude: location.latitude, longitude: location.longitude),
        animate: true,
      );
    } catch (e) {
      log('Error: $e');
    }
  }

  Future<void> updateOSMCameraLocation(
      {required GeoPoint source, required GeoPoint destination}) async {
    BoundingBox bounds;

    if (source.latitude > destination.latitude &&
        source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.longitude > destination.longitude) {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: source.longitude,
        west: destination.longitude,
      );
    } else if (source.latitude > destination.latitude) {
      bounds = BoundingBox(
        north: source.latitude,
        south: destination.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    } else {
      bounds = BoundingBox(
        north: destination.latitude,
        south: source.latitude,
        east: destination.longitude,
        west: source.longitude,
      );
    }

    await mapOsmController.zoomToBoundingBox(bounds, paddinInPixel: 100);
  }

  setOsmMarker(
      {required GeoPoint departure, required GeoPoint destination}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isControllerClosed) {
        return;
      }

      if (osmMarkers.containsKey('Driver')) {
        await mapOsmController.removeMarker(osmMarkers['Driver']!);
      }

      await mapOsmController
          .addMarker(
              GeoPoint(
                  latitude: driverUserModel.value.location!.latitude!,
                  longitude: driverUserModel.value.location!.longitude!),
              markerIcon: MarkerIcon(iconWidget: driverOsmIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        osmMarkers['Driver'] = GeoPoint(
            latitude: driverUserModel.value.location!.latitude!,
            longitude: driverUserModel.value.location!.longitude!);
      });

      if (osmMarkers.containsKey('Source')) {
        await mapOsmController.removeMarker(osmMarkers['Source']!);
      }
      await mapOsmController
          .addMarker(departure,
              markerIcon: MarkerIcon(iconWidget: departureOsmIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        osmMarkers['Source'] = departure;
      });

      if (osmMarkers.containsKey('Destination')) {
        await mapOsmController.removeMarker(osmMarkers['Destination']!);
      }

      await mapOsmController
          .addMarker(destination,
              markerIcon: MarkerIcon(iconWidget: destinationOsmIcon),
              angle: pi / 3,
              iconAnchor: IconAnchor(
                anchor: Anchor.top,
              ))
          .then((v) {
        osmMarkers['Destination'] = destination;
      });
    });
    // getOSMPolyline();
  }
}
