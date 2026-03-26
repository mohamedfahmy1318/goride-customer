import 'dart:convert';
import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/intercity_service_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class InterCityController extends GetxController {
  DashBoardController dashboardController = Get.put(DashBoardController());

  Rx<TextEditingController> sourceCityController = TextEditingController().obs;
  Rx<TextEditingController> sourceLocationController =
      TextEditingController().obs;
  Rx<LocationLatLng> sourceLocationLAtLng = LocationLatLng().obs;

  Rx<TextEditingController> destinationCityController =
      TextEditingController().obs;
  Rx<TextEditingController> destinationLocationController =
      TextEditingController().obs;
  Rx<LocationLatLng> destinationLocationLAtLng = LocationLatLng().obs;

  Rx<TextEditingController> parcelWeight = TextEditingController().obs;
  Rx<TextEditingController> parcelDimension = TextEditingController().obs;

  Rx<TextEditingController> noOfPassengers = TextEditingController().obs;
  Rx<TextEditingController> offerYourRateController =
      TextEditingController().obs;
  Rx<TextEditingController> whenController = TextEditingController().obs;
  Rx<TextEditingController> commentsController = TextEditingController().obs;

  RxList<IntercityServiceModel> intercityService =
      <IntercityServiceModel>[].obs;
  Rx<IntercityServiceModel> selectedInterCityType = IntercityServiceModel().obs;
  RxList zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;

  Rx<bool> loaderNeeded = false.obs;

  DateTime? dateAndTime;

  RxList<XFile> images = <XFile>[].obs;

  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  @override
  void onInit() {
    // TODO: implement onInit
    getPaymentData();
    getIntercityService();

    super.onInit();
  }

  RxBool isLoading = true.obs;

  getIntercityService() async {
    await FireStoreUtils.getIntercityService().then((value) {
      intercityService.value = value;
      if (intercityService.isNotEmpty) {
        selectedInterCityType.value = intercityService.first;
      }
    });
    isLoading.value = false;
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<UserModel> userModel = UserModel().obs;

  RxString selectedPaymentMethod = "".obs;

  getPaymentData() async {
    await FireStoreUtils().getZone().then((value) {
      if (value != null) {
        zoneList.value = value;
      }
    });
    await FireStoreUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
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

  RxString duration = "".obs;
  RxString distance = "".obs;
  RxString amount = "".obs;

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
      log('convertToMinutes error: $e');
    }
    return durationValue;
  }

  double _calculateTotalAmount(double distanceVal, double durationMinutes) {
    double meterStartVal =
        double.tryParse(selectedInterCityType.value.meterStart ?? '0') ?? 0.0;
    double kmChargeVal =
        double.tryParse(selectedInterCityType.value.kmCharge ?? '0') ?? 0.0;
    double perMinuteChargeVal =
        double.tryParse(selectedInterCityType.value.perMinuteCharge ?? '0') ??
            0.0;
    bool enableMinuteCharge =
        selectedInterCityType.value.enableMinuteCharge ?? false;

    double kmAmount = distanceVal * kmChargeVal;
    double minuteAmount =
        enableMinuteCharge ? (durationMinutes * perMinuteChargeVal) : 0.0;

    return meterStartVal + kmAmount + minuteAmount;
  }

  calculateOsmAmount() async {
    log("${sourceLocationLAtLng.value.latitude}::: duration sourceLocationLAtLng :::${sourceLocationLAtLng.value.longitude}");
    log("${destinationLocationLAtLng.value.latitude}::: duration destinationLocationLAtLng :::${destinationLocationLAtLng.value.longitude}");
    amount.value = "0.0";
    offerYourRateController.value.text = "0.0";
    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
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
          duration.value = '$hours hours $minutes minutes';
          if (Constant.distanceType == "Km") {
            distance.value =
                (value['routes'].first['distance'] / 1000).toString();
          } else {
            distance.value =
                (value['routes'].first['distance'] / 1609.34).toString();
          }
          double distanceVal = double.tryParse(distance.value) ?? 0.0;
          double durationMinutes = convertToMinutes(duration.value);
          double total = _calculateTotalAmount(distanceVal, durationMinutes);
          amount.value =
              total.toStringAsFixed(Constant.currencyModel!.decimalDigits!);
          offerYourRateController.value.text = amount.value;
        }
      });
    }
  }

  calculateAmount() async {
    amount.value = "0.0";
    offerYourRateController.value.text = "0.0";
    if (sourceLocationLAtLng.value.latitude != null &&
        destinationLocationLAtLng.value.latitude != null) {
      await Constant.getDurationDistance(
              LatLng(sourceLocationLAtLng.value.latitude!,
                  sourceLocationLAtLng.value.longitude!),
              LatLng(destinationLocationLAtLng.value.latitude!,
                  destinationLocationLAtLng.value.longitude!))
          .then((value) {
        if (value != null) {
          duration.value =
              value.rows!.first.elements!.first.duration!.text.toString();
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
          double distanceVal = double.tryParse(distance.value) ?? 0.0;
          double durationMinutes = convertToMinutes(duration.value);
          double total = _calculateTotalAmount(distanceVal, durationMinutes);
          amount.value =
              total.toStringAsFixed(Constant.currencyModel!.decimalDigits!);
          offerYourRateController.value.text = amount.value;
        }
      });
    }
  }

  RxList<ContactModel> contactList = <ContactModel>[].obs;
  Rx<ContactModel> selectedTakingRide =
      ContactModel(fullName: "Myself", contactNumber: "").obs;

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
