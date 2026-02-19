import 'dart:convert';
import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';

class HomeController extends GetxController {
  DashBoardController dashboardController = Get.put(DashBoardController());

  Rx<TextEditingController> sourceLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> destinationLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> offerYourRateController =
      TextEditingController().obs;
  Rx<ServiceModel> selectedType = ServiceModel().obs;

  Rx<LocationLatLng> sourceLocationLAtLng = LocationLatLng().obs;
  Rx<LocationLatLng> destinationLocationLAtLng = LocationLatLng().obs;

  RxString currentLocation = "".obs;
  RxBool isLoading = true.obs;
  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  RxList bannerList = <BannerModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxBool isAcSelected = false.obs;
  RxBool isBookingInProgress = false.obs;
  RxDouble extraDistance = 0.0.obs;
  final PageController pageController =
      PageController(viewportFraction: 0.96, keepPage: true);

  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  String? startNightTime;
  String? endNightTime;
  DateTime startNightTimeString = DateTime.now();
  DateTime endNightTimeString = DateTime.now();

  @override
  void onInit() {
    // TODO: implement onInit
    getLocation();
    getServiceType();
    getPaymentData();
    getContact();
    super.onInit();
  }

  Future<void> getLocation() async {
    try {
      debugPrint('🔍 Getting current location...');
      Constant.currentLocation = await Utils.getCurrentLocation();
      debugPrint(
          '📍 Location: ${Constant.currentLocation?.latitude}, ${Constant.currentLocation?.longitude}');

      if (Constant.currentLocation == null) {
        debugPrint('❌ Location is null');
        return;
      }

      // Try geocoding to get address from coordinates
      String address = '';
      bool geocoded = false;

      // Method 1: Google geocoding (native platform)
      if (Constant.selectedMapType == 'google') {
        try {
          debugPrint('🗺️ Trying Google geocoding...');
          List<Placemark> placeMarks = await placemarkFromCoordinates(
            Constant.currentLocation!.latitude,
            Constant.currentLocation!.longitude,
          );
          if (placeMarks.isNotEmpty) {
            Constant.country = placeMarks.first.country;
            Constant.city = placeMarks.first.locality;
            address =
                "${placeMarks.first.name}, ${placeMarks.first.subLocality}, ${placeMarks.first.locality}, ${placeMarks.first.administrativeArea}, ${placeMarks.first.postalCode}, ${placeMarks.first.country}";
            geocoded = true;
            debugPrint('✅ Google geocoding success: $address');
          }
        } catch (geoError) {
          debugPrint('⚠️ Google geocoding failed: $geoError');
        }
      }

      // Method 2: Nominatim fallback (or primary if OSM selected)
      if (!geocoded) {
        try {
          debugPrint('🗺️ Trying Nominatim geocoding...');
          Place place = await Nominatim.reverseSearch(
            lat: Constant.currentLocation!.latitude,
            lon: Constant.currentLocation!.longitude,
            zoom: 14,
            addressDetails: true,
            extraTags: true,
            nameDetails: true,
          );
          address = place.displayName.toString();
          Constant.country = place.address?['country'] ?? '';
          Constant.city = place.address?['city'] ?? '';
          geocoded = true;
          debugPrint('✅ Nominatim geocoding success: $address');
        } catch (nomError) {
          debugPrint('⚠️ Nominatim geocoding failed: $nomError');
        }
      }

      // Method 3: Use raw coordinates if all geocoding fails
      if (!geocoded) {
        address =
            '${Constant.currentLocation!.latitude.toStringAsFixed(4)}, ${Constant.currentLocation!.longitude.toStringAsFixed(4)}';
        debugPrint('📍 Using raw coordinates as address: $address');
      }

      currentLocation.value = address;

      // Always set source location from current location
      sourceLocationLAtLng.value = LocationLatLng(
        latitude: Constant.currentLocation!.latitude,
        longitude: Constant.currentLocation!.longitude,
      );
      sourceLocationController.value.text = currentLocation.value;
    } catch (e) {
      debugPrint('❌ Location Error: $e');
      ShowToastDialog.showToast(
        "Location access permission is currently unavailable. You're unable to retrieve any location data. Please grant permission from your device settings.",
        duration: const Duration(seconds: 3),
      );
    }
  }

  // دالة مساعدة لترتيب المركبات حسب الأولوية
  // الترتيب: سيارة (Car) أولاً، ثم تكتوك (TukTuk/Rickshaw)، ثم دباب (Bike/Motorcycle)
  int _getVehiclePriority(ServiceModel service) {
    String title = service.title?.first.title?.toLowerCase() ?? '';
    if (title.contains('car') ||
        title.contains('سيارة') ||
        title.contains('sedan')) {
      return 1; // السيارة أولاً
    } else if (title.contains('tuktuk') ||
        title.contains('tuk tuk') ||
        title.contains('تكتوك') ||
        title.contains('rickshaw') ||
        title.contains('auto')) {
      return 2; // تكتوك ثانياً
    } else if (title.contains('bike') ||
        title.contains('دباب') ||
        title.contains('motor') ||
        title.contains('scooter')) {
      return 3; // دباب ثالثاً
    }
    return 4; // أي نوع آخر في النهاية
  }

  getServiceType() async {
    await FireStoreUtils.getService().then((value) {
      // ترتيب المركبات: سيارة أولاً، ثم تكتوك، ثم دباب
      List<ServiceModel> sortedList = List.from(value);
      sortedList.sort(
          (a, b) => _getVehiclePriority(a).compareTo(_getVehiclePriority(b)));
      serviceList.value = sortedList;
      if (serviceList.isNotEmpty) {
        selectedType.value = serviceList.first;
      }
    });

    await FireStoreUtils.getBanner().then((value) {
      bannerList.value = value;
    });

    await FireStoreUtils().getTaxList().then((value) {
      if (value != null) {
        Constant.taxList = value;
      }
    });

    await FireStoreUtils().getAirports().then((value) {
      if (value != null) {
        Constant.airaPortList = value;
      }
    });

    String token = await NotificationService.getToken();
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      userModel.value = value!;
      userModel.value.fcmToken = token;
      FireStoreUtils.updateUser(userModel.value);
    });

    isLoading.value = false;
  }

  RxString duration = "".obs;
  RxString distance = "".obs;
  RxString amount = "".obs;
  RxString acCharge = "".obs;
  RxString nonAcCharge = "".obs;
  RxString basicFare = "".obs;
  RxString basicFareCharge = "".obs;
  RxString nightCharge = "".obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble totalNightFare = 0.0.obs;
  RxBool isAcNonAc = false.obs;
  DateTime currentTime = DateTime.now();
  DateTime currentDate = DateTime.now();

  double convertToMinutes(String duration) {
    double durationValue = 0.0;

    try {
      final RegExp hoursRegex = RegExp(r"(\d+)\s*hour");
      final RegExp minutesRegex = RegExp(r"(\d+)\s*min");

      final Match? hoursMatch = hoursRegex.firstMatch(duration);
      if (hoursMatch != null) {
        int hours = int.parse(hoursMatch.group(1)!.trim());
        durationValue += hours * 60;
      }

      final Match? minutesMatch = minutesRegex.firstMatch(duration);
      if (minutesMatch != null) {
        int minutes = int.parse(minutesMatch.group(1)!.trim());
        durationValue += minutes;
      }
    } catch (e) {
      log("Exception: $e");
      throw FormatException("Invalid duration format: $duration");
    }

    return durationValue;
  }

  calculateDurationAndDistance() async {
    if (Constant.selectedMapType == 'osm') {
      if (sourceLocationLAtLng.value.latitude != null &&
          destinationLocationLAtLng.value.latitude != null) {
        ShowToastDialog.showLoader("Please wait");
        await Constant.getDurationOsmDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .then((value) {
          if (value != {} && value.isNotEmpty) {
            int hours = value['routes'].first['duration'] ~/ 3600;
            int minutes =
                ((value['routes'].first['duration'] % 3600) / 60).round();
            duration.value =
                '$hours ${'hours'.tr} $minutes ${'minutes'.tr}'.trim();
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value['routes'].first['distance'] / 1000).toString();
            } else {
              distance.value =
                  (value['routes'].first['distance'] / 1609.34).toString();
            }
          }
          update();
        });
      }
      ShowToastDialog.closeLoader();
    } else {
      if (sourceLocationLAtLng.value.latitude != null &&
          destinationLocationLAtLng.value.latitude != null) {
        ShowToastDialog.showLoader("Please wait");
        await Constant.getDurationDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .then((value) {
          if (value != null) {
            duration.value =
                value.rows!.first.elements!.first.duration!.text.toString();
            log("duration :: 00 :: ${duration.value}");
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value.rows!.first.elements!.first.distance!.value!.toInt() /
                          1000)
                      .toString();
            } else {
              distance.value =
                  (value.rows!.first.elements!.first.distance!.value!.toInt() /
                          1609.34)
                      .toString();
            }
          }
          update();
        });
        ShowToastDialog.closeLoader();
      }
    }
  }

  calculateAmount() async {
    try {
    log('🔢 calculateAmount called: serviceList.length=${serviceList.length}, selectedType.id=${selectedType.value.id}, kmCharge=${selectedType.value.kmCharge}, basicFare=${selectedType.value.basicFare}, basicFareCharge=${selectedType.value.basicFareCharge}, perMinuteCharge=${selectedType.value.perMinuteCharge}, isAcNonAc=${selectedType.value.isAcNonAc}, distance=${distance.value}, duration=${duration.value}');
    acCharge.value = selectedType.value.acCharge?.toString() ?? '0.0';
    nonAcCharge.value = selectedType.value.nonAcCharge?.toString() ?? '0.0';
    basicFare.value = selectedType.value.basicFare?.toString() ?? '0.0';
    basicFareCharge.value = selectedType.value.basicFareCharge?.toString() ?? '0.0';
    isAcNonAc.value = selectedType.value.isAcNonAc ?? false;
    String formatTime(String? time) {
      if (time == null || !time.contains(":")) {
        return "00:00";
      }
      List<String> parts = time.split(':');
      if (parts.length != 2) return "00:00";
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }

    startNightTime = formatTime(selectedType.value.startNightTime);
    endNightTime = formatTime(selectedType.value.endNightTime);

    List<String> startParts = startNightTime!.split(':');
    List<String> endParts = endNightTime!.split(':');

    startNightTimeString = DateTime(currentDate.year, currentDate.month,
        currentDate.day, int.parse(startParts[0]), int.parse(startParts[1]));
    endNightTimeString = DateTime(currentDate.year, currentDate.month,
        currentDate.day, int.parse(endParts[0]), int.parse(endParts[1]));

    nightCharge.value = selectedType.value.nightCharge.toString();
    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
      double durationValueInMinutes = convertToMinutes(duration.toString());
      double distanceVal = double.tryParse(distance.value) ?? 0.0;
      double basicFareVal = double.tryParse(basicFare.value) ?? 0.0;
      if (distanceVal <= basicFareVal) {
        double basicFareChargeVal =
            double.tryParse(basicFareCharge.value.toString()) ?? 0.0;
        double perMinuteChargeVal =
            double.tryParse(selectedType.value.perMinuteCharge.toString()) ??
                0.0;
        amount.value =
            (basicFareChargeVal + (durationValueInMinutes * perMinuteChargeVal))
                .toStringAsFixed(Constant.currencyModel!.decimalDigits!);

        totalNightFare.value = double.tryParse(amount.value) ?? 0.0;
        if (currentTime.isAfter(startNightTimeString) &&
            currentTime.isBefore(endNightTimeString)) {
          double nightChargeVal =
              double.tryParse(nightCharge.value.toString()) ?? 1.0;
          amount.value =
              (totalNightFare.value * nightChargeVal).toStringAsFixed(2);
        }
      } else {
        double distanceValue = double.tryParse(distance.value) ?? 0.0;
        double basicFareValue = double.tryParse(basicFare.value) ?? 0.0;
        double extraDist = distanceValue - basicFareValue;
        extraDistance.value = extraDist;
        double nonAcChargeValue =
            double.tryParse(nonAcCharge.value.toString()) ?? 0.0;
        double acChargeValue =
            double.tryParse(acCharge.value.toString()) ?? 0.0;
        double perKmCharge = isAcNonAc.value == true
            ? isAcSelected.value == false
                ? nonAcChargeValue
                : acChargeValue
            : double.tryParse(selectedType.value.kmCharge.toString()) ?? 0.0;
        double perMinuteCharge =
            double.tryParse(selectedType.value.perMinuteCharge.toString()) ??
                0.0;
        double durationInMinutes =
            double.tryParse(durationValueInMinutes.toString()) ?? 0.0;
        double basicFareChargeValue =
            double.tryParse(basicFareCharge.value.toString()) ?? 0.0;
        totalAmount.value = (perKmCharge * extraDist) +
            (durationInMinutes * perMinuteCharge) +
            basicFareChargeValue;

        totalNightFare.value = totalAmount.value;
        amount.value = totalNightFare.value.toStringAsFixed(2);

        if (currentTime.isAfter(startNightTimeString) &&
            currentTime.isBefore(endNightTimeString)) {
          double nightChargeVal =
              double.tryParse(nightCharge.value.toString()) ?? 1.0;
          amount.value =
              (totalNightFare.value * nightChargeVal).toStringAsFixed(2);
        }
      }
      offerYourRateController.value.text = amount.value;
    }
    } catch (e) {
      log('❌ calculateAmount error: $e');
      log('   selectedType: id=${selectedType.value.id}, kmCharge=${selectedType.value.kmCharge}, basicFare=${selectedType.value.basicFare}, basicFareCharge=${selectedType.value.basicFareCharge}, perMinuteCharge=${selectedType.value.perMinuteCharge}, isAcNonAc=${selectedType.value.isAcNonAc}');
    }
    update();
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;

  RxString selectedPaymentMethod = "".obs;

  RxList airPortList = <AriPortModel>[].obs;

  getPaymentData() async {
    await FireStoreUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
      }
    });

    await FireStoreUtils().getZone().then((value) {
      if (value != null) {
        zoneList.value = value;
      }
    });

    await getUser();
  }

  getUser() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });
  }

  RxList<ContactModel> contactList = <ContactModel>[].obs;
  Rx<ContactModel> selectedTakingRide =
      ContactModel(fullName: "Myself", contactNumber: "").obs;
  Rx<AriPortModel> selectedAirPort = AriPortModel().obs;

  setContact() {
    log(jsonEncode(contactList));
    Preferences.setString(
        Preferences.contactList,
        json.encode(contactList
            .map<Map<String, dynamic>>((music) => music.toJson())
            .toList()));
    getContact();
  }

  getContact() {
    String contactListJson = Preferences.getString(Preferences.contactList);

    if (contactListJson.isNotEmpty) {
      log("---->");
      contactList.clear();
      contactList.value = (json.decode(contactListJson) as List<dynamic>)
          .map<ContactModel>((item) => ContactModel.fromJson(item))
          .toList();
    }
  }
}
