import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class CompleteOrderController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  getDriver() async {
    await FireStoreUtils.getDriver(orderModel.value.driverId.toString()).then(
      (value) {
        if (value != null) {
          driverModel.value = value;
        }
      },
    );
  }

  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;

  RxString couponAmount = "0.0".obs;

  // double calculateAmount() {
  //   RxString taxAmount = "0.0".obs;
  //   if (orderModel.value.taxList != null) {
  //     for (var element in orderModel.value.taxList!) {
  //       taxAmount.value = (double.parse(taxAmount.value) +
  //               Constant().calculateTax(
  //                   amount:
  //                       (double.parse(orderModel.value.finalRate.toString()) -
  //                               double.parse(couponAmount.value.toString()))
  //                           .toString(),
  //                   taxModel: element))
  //           .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
  //     }
  //   }
  //   String totalHoldingCharge = orderModel.value.totalHoldingCharges != null
  //       ? orderModel.value.totalHoldingCharges.toString()
  //       : "0.0";
  //   return (double.parse(orderModel.value.finalRate.toString()) -
  //           double.parse(couponAmount.value.toString())) +
  //       double.parse(totalHoldingCharge.toString()) +
  //       double.parse(taxAmount.value);
  // }

  RxDouble amount = 0.0.obs;
  RxDouble subTotal = 0.0.obs;
  RxDouble total = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble totalChargeOfMinute = 0.0.obs;
  RxDouble meterStartCharge = 0.0.obs;
  RxDouble holdingCharge = 0.0.obs;

  calculateAmount() async {
    final persistedGross =
        double.tryParse(orderModel.value.totalFare ?? '');
    if (persistedGross != null) {
      final discount =
          double.tryParse(orderModel.value.discountAmount ?? '0') ?? 0;
      subTotal.value = persistedGross;
      amount.value = persistedGross;
      meterStartCharge.value = 0;
      totalChargeOfMinute.value = 0;
      holdingCharge.value = 0;
      total.value = orderModel.value.customerPayableFare;
      taxAmount.value = (total.value - (persistedGross - discount))
          .clamp(0, double.infinity)
          .toDouble();
      return;
    }

    // Admin-created rides: the admin's manually-entered fare (finalRate) is the
    // sole source of truth. Skip distance/per-minute/holding computation entirely.
    if (orderModel.value.isAdminCreated == true) {
      double adminFare =
          double.tryParse(orderModel.value.finalRate?.toString() ?? '0') ??
              double.tryParse(orderModel.value.offerRate?.toString() ?? '0') ??
              0.0;

      meterStartCharge.value = 0.0;
      totalChargeOfMinute.value = 0.0;
      holdingCharge.value = 0.0;
      amount.value = adminFare;
      subTotal.value = adminFare;
    } else {
      // Customer-initiated rides: keep existing distance-based calculation.
      // New formula: meterStart + (distance × kmCharge) + (optional: minutes × perMinuteCharge) + holdingCharge
      double durationValueInMinutes =
          convertToMinutes(orderModel.value.duration.toString());
      // Use actual distance/duration if available (from GPS tracking during ride)
      double distance = double.tryParse(orderModel.value.actualDistance ??
              orderModel.value.distance.toString()) ??
          0.0;
      if (orderModel.value.actualDuration != null) {
        durationValueInMinutes =
            double.tryParse(orderModel.value.actualDuration!) ??
                durationValueInMinutes;
      }

      double kmCharge =
          double.tryParse(orderModel.value.service!.kmCharge ?? '0.0') ?? 0.0;
      double meterStartVal =
          double.tryParse(orderModel.value.service!.meterStart ?? '0.0') ?? 0.0;
      double perMinuteChargeVal =
          double.tryParse(orderModel.value.service!.perMinuteCharge ?? '0') ??
              0.0;
      bool enableMinuteCharge =
          orderModel.value.service!.enableMinuteCharge ?? true;
      bool enableHoldingCharge =
          orderModel.value.service!.enableHoldingCharge ?? true;

      meterStartCharge.value = meterStartVal;
      amount.value = distance * kmCharge;
      totalChargeOfMinute.value = enableMinuteCharge
          ? (durationValueInMinutes * perMinuteChargeVal)
          : 0.0;
      holdingCharge.value = enableHoldingCharge
          ? (double.tryParse(orderModel.value.totalHoldingCharges.toString()) ??
              0.0)
          : 0.0;

      // If finalRate is set by driver, use it and derive km-charge portion for display
      if (orderModel.value.finalRate != null &&
          orderModel.value.finalRate != '0.0') {
        double finalRateVal =
            double.parse(orderModel.value.finalRate.toString());
        amount.value =
            finalRateVal - meterStartCharge.value - totalChargeOfMinute.value;
      } else if (orderModel.value.offerRate != null &&
          orderModel.value.offerRate != '0.0' &&
          orderModel.value.offerRate != '') {
        // Use the pre-calculated price from booking
        double offerRateVal =
            double.tryParse(orderModel.value.offerRate.toString()) ?? 0.0;
        amount.value =
            offerRateVal - meterStartCharge.value - totalChargeOfMinute.value;
      }

      subTotal.value = amount.value +
          meterStartCharge.value +
          totalChargeOfMinute.value +
          holdingCharge.value;
    }

    if (orderModel.value.isAdminCreated == true) {
      // Admin-defined fare is the absolute total. Do not add tax on top.
      taxAmount.value = 0.0;
      total.value = subTotal.value;
    } else {
      if (orderModel.value.taxList != null) {
        for (var element in orderModel.value.taxList!) {
          taxAmount.value = taxAmount.value +
              Constant().calculateTax(
                  amount: (double.parse(subTotal.value.toString()) -
                          double.parse(couponAmount.value.toString()))
                      .toString(),
                  taxModel: element);
        }
      }
      total.value = subTotal.value + taxAmount.value;
    }
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];

      if (orderModel.value.coupon != null) {
        if (orderModel.value.coupon?.code != null) {
          if (orderModel.value.coupon!.type == "fix") {
            couponAmount.value = orderModel.value.coupon!.amount.toString();
          } else {
            couponAmount.value =
                ((double.parse(orderModel.value.finalRate.toString()) *
                            double.parse(
                                orderModel.value.coupon!.amount.toString())) /
                        100)
                    .toString();
          }
        }
      }
    }
    await getDriver();
    calculateAmount();
    isLoading.value = false;
    update();
  }

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
}
