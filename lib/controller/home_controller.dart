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

  getServiceType() async {
    await FireStoreUtils.getService().then((value) {
      // ترتيب المركبات حسب حقل position اللي بيتحدد من لوحة التحكم
      List<ServiceModel> sortedList = List.from(value);
      sortedList.sort((a, b) => a.position.compareTo(b.position));
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
  RxDouble totalAmount = 0.0.obs;
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
    log('🔢 calculateAmount called: distance="${distance.value}", selectedType.id=${selectedType.value.id}, kmCharge=${selectedType.value.kmCharge}, meterStart=${selectedType.value.meterStart}');
    // Guard: don't calculate if distance or service data not ready yet
    if (distance.value.isEmpty ||
        (double.tryParse(distance.value) ?? 0.0) <= 0.0) {
      log('⚠️ calculateAmount: distance empty or zero, skipping');
      amount.value = "";
      update();
      return;
    }
    if (selectedType.value.id == null || selectedType.value.kmCharge == null) {
      log('⚠️ calculateAmount: selectedType not ready (id=${selectedType.value.id}, kmCharge=${selectedType.value.kmCharge})');
      amount.value = "";
      update();
      return;
    }
    try {
      // New formula: meterStart + (distance × kmCharge) + (optional: minutes × perMinuteCharge)
      double distanceVal = double.tryParse(distance.value) ?? 0.0;
      double meterStartVal =
          double.tryParse(selectedType.value.meterStart ?? '0') ?? 0.0;
      double kmChargeVal =
          double.tryParse(selectedType.value.kmCharge ?? '0') ?? 0.0;
      double perMinuteChargeVal =
          double.tryParse(selectedType.value.perMinuteCharge ?? '0') ?? 0.0;
      bool enableMinuteCharge = selectedType.value.enableMinuteCharge ?? true;

      double durationValueInMinutes = convertToMinutes(duration.value);

      double kmAmount = distanceVal * kmChargeVal;
      double minuteAmount = enableMinuteCharge
          ? (durationValueInMinutes * perMinuteChargeVal)
          : 0.0;

      totalAmount.value = meterStartVal + kmAmount + minuteAmount;
      amount.value = totalAmount.value
          .toStringAsFixed(Constant.currencyModel!.decimalDigits!);

      offerYourRateController.value.text = amount.value;
      log('✅ calculateAmount result: amount=${amount.value}, meterStart=$meterStartVal, kmAmount=$kmAmount, minuteAmount=$minuteAmount');
    } catch (e) {
      log('❌ calculateAmount error: $e');
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
