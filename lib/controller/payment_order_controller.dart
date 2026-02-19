import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class PaymentOrderController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    getPaymentData();
    super.onInit();
  }

  Rx<OrderModel> orderModel = OrderModel().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
    }
    update();
  }

  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;

  RxString selectedPaymentMethod = "".obs;

  getPaymentData() async {
    await FireStoreUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
        selectedPaymentMethod.value = orderModel.value.paymentType.toString();
      }
    });

    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });
    await FireStoreUtils.getDriver(orderModel.value.driverId.toString())
        .then((value) {
      if (value != null) {
        driverUserModel.value = value;
      }
    });

    calculateAmount();
    isLoading.value = false;
    update();
  }

  completeOrder() async {
    ShowToastDialog.showLoader("Please wait..");
    orderModel.value.paymentStatus = true;
    orderModel.value.paymentType = selectedPaymentMethod.value;
    orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;
    orderModel.value.updateDate = Timestamp.now();

    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: total.value.toString(),
        createdDate: Timestamp.now(),
        paymentType: selectedPaymentMethod.value,
        transactionId: orderModel.value.id,
        userId: orderModel.value.driverId.toString(),
        orderType: "city",
        userType: "driver",
        note: "Ride amount credited");

    await FireStoreUtils.setWalletTransaction(transactionModel)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateDriverWallet(
            amount: total.value.toString(),
            driverId: orderModel.value.driverId.toString());
      }
    });

    if (driverUserModel.value.subscriptionPlan!.id ==
        Constant.commissionSubscriptionID) {
      WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          id: Constant.getUuid(),
          amount:
              "-${Constant.calculateOrderAdminCommission(amount: (subTotal.value - double.parse(couponAmount.value)).toString(), adminCommission: orderModel.value.adminCommission)}",
          createdDate: Timestamp.now(),
          paymentType: selectedPaymentMethod.value,
          transactionId: orderModel.value.id,
          orderType: "city",
          userType: "driver",
          userId: orderModel.value.driverId.toString(),
          note: "Admin commission debited");

      await FireStoreUtils.setWalletTransaction(adminCommissionWallet)
          .then((value) async {
        if (value == true) {
          await FireStoreUtils.updateDriverWallet(
              amount:
                  "-${Constant.calculateOrderAdminCommission(amount: (subTotal.value - double.parse(couponAmount.value)).toString(), adminCommission: orderModel.value.adminCommission)}",
              driverId: orderModel.value.driverId.toString());
        }
      });
    }

    if (driverUserModel.value.fcmToken != null) {
      Map<String, dynamic> playLoad = <String, dynamic>{
        "type": "city_order_payment_complete",
        "orderId": orderModel.value.id
      };

      await SendNotification.sendOneNotification(
          token: driverUserModel.value.fcmToken.toString(),
          title: 'Payment Received',
          body:
              '${userModel.value.fullName}  has paid ${Constant.amountShow(amount: total.value.toString())} for the completed ride.Check your earnings for details.',
          payload: playLoad);
    }

    await FireStoreUtils.getFirestOrderOrNOt(orderModel.value)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateReferralAmount(orderModel.value);
      }
    });

    await FireStoreUtils.setOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Ride Complete successfully");
      }
    });
  }

  completeCashOrder() async {
    orderModel.value.paymentType = selectedPaymentMethod.value;
    orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;

    await SendNotification.sendOneNotification(
        token: driverUserModel.value.fcmToken.toString(),
        title: 'Payment changed.',
        body: '${userModel.value.fullName} has changed payment method.',
        payload: {});

    FireStoreUtils.setOrder(orderModel.value).then((value) {
      if (value == true) {
        Get.back();
        ShowToastDialog.showToast(
            "Your payment request sent to driver please wait to the conformation"
                .tr);
      }
    });
  }

  completeWalletOrder() async {
    ShowToastDialog.showLoader("Please wait..");

    // Check wallet balance
    double walletBalance =
        double.tryParse(userModel.value.walletAmount?.toString() ?? '0') ?? 0;
    if (walletBalance < total.value) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          'رصيد المحفظة غير كافي. الرصيد الحالي: ${Constant.amountShow(amount: walletBalance.toString())}');
      return;
    }

    // Deduct from customer wallet
    await FireStoreUtils.updateUserWallet(amount: "-${total.value}");

    // Record customer wallet transaction
    WalletTransactionModel customerTransaction = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: "-${total.value}",
        createdDate: Timestamp.now(),
        paymentType: "Wallet",
        transactionId: orderModel.value.id,
        userId: FireStoreUtils.getCurrentUid(),
        orderType: "city",
        userType: "customer",
        note: "Ride payment from wallet");
    await FireStoreUtils.setWalletTransaction(customerTransaction);

    // Complete order (same as completeOrder but with Wallet payment type)
    orderModel.value.paymentStatus = true;
    orderModel.value.paymentType = "Wallet";
    orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;
    orderModel.value.updateDate = Timestamp.now();

    // Credit driver wallet
    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: total.value.toString(),
        createdDate: Timestamp.now(),
        paymentType: "Wallet",
        transactionId: orderModel.value.id,
        userId: orderModel.value.driverId.toString(),
        orderType: "city",
        userType: "driver",
        note: "Ride amount credited");

    await FireStoreUtils.setWalletTransaction(transactionModel)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateDriverWallet(
            amount: total.value.toString(),
            driverId: orderModel.value.driverId.toString());
      }
    });

    // Admin commission
    if (driverUserModel.value.subscriptionPlan!.id ==
        Constant.commissionSubscriptionID) {
      WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          id: Constant.getUuid(),
          amount:
              "-${Constant.calculateOrderAdminCommission(amount: (subTotal.value - double.parse(couponAmount.value)).toString(), adminCommission: orderModel.value.adminCommission)}",
          createdDate: Timestamp.now(),
          paymentType: "Wallet",
          transactionId: orderModel.value.id,
          orderType: "city",
          userType: "driver",
          userId: orderModel.value.driverId.toString(),
          note: "Admin commission debited");

      await FireStoreUtils.setWalletTransaction(adminCommissionWallet)
          .then((value) async {
        if (value == true) {
          await FireStoreUtils.updateDriverWallet(
              amount:
                  "-${Constant.calculateOrderAdminCommission(amount: (subTotal.value - double.parse(couponAmount.value)).toString(), adminCommission: orderModel.value.adminCommission)}",
              driverId: orderModel.value.driverId.toString());
        }
      });
    }

    // Notify driver
    if (driverUserModel.value.fcmToken != null) {
      Map<String, dynamic> playLoad = <String, dynamic>{
        "type": "city_order_payment_complete",
        "orderId": orderModel.value.id
      };
      await SendNotification.sendOneNotification(
          token: driverUserModel.value.fcmToken.toString(),
          title: 'Payment Received',
          body:
              '${userModel.value.fullName} has paid ${Constant.amountShow(amount: total.value.toString())} from wallet.',
          payload: playLoad);
    }

    // Referral check
    await FireStoreUtils.getFirestOrderOrNOt(orderModel.value)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateReferralAmount(orderModel.value);
      }
    });

    await FireStoreUtils.setOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Ride Complete successfully");
      }
    });
  }

  Rx<CouponModel> selectedCouponModel = CouponModel().obs;
  RxString couponAmount = "0.0".obs;

  RxDouble amount = 0.0.obs;
  RxDouble subTotal = 0.0.obs;
  RxDouble total = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxString startNightTime = "".obs;
  RxString endNightTime = "".obs;
  RxDouble totalNightFare = 0.0.obs;
  RxDouble totalChargeOfMinute = 0.0.obs;
  RxDouble holdingCharge = 0.0.obs;
  RxDouble basicFareCharge = 0.0.obs;
  DateTime currentTime = DateTime.now();
  DateTime currentDate = DateTime.now();
  DateTime startNightTimeString = DateTime.now();
  DateTime endNightTimeString = DateTime.now();

  calculateAmount() async {
    taxAmount.value = 0.0;
    String formatTime(String? time) {
      if (time == null || !time.contains(":")) {
        return "00:00";
      }
      List<String> parts = time.split(':');
      if (parts.length != 2) return "00:00";
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }

    startNightTime.value = formatTime(orderModel.value.service!.startNightTime);
    endNightTime.value = formatTime(orderModel.value.service!.endNightTime);

    List<String> startParts = startNightTime.split(':');
    List<String> endParts = endNightTime.split(':');

    startNightTimeString = DateTime(currentDate.year, currentDate.month,
        currentDate.day, int.parse(startParts[0]), int.parse(startParts[1]));
    endNightTimeString = DateTime(currentDate.year, currentDate.month,
        currentDate.day, int.parse(endParts[0]), int.parse(endParts[1]));

    double durationValueInMinutes =
        convertToMinutes(orderModel.value.duration.toString());
    double distance =
        double.tryParse(orderModel.value.distance.toString()) ?? 0.0;
    double nonAcChargeValue = 0.0;
    double acChargeValue = 0.0;
    double kmCharge = 0.0;

    if (orderModel.value.driverId != null &&
        orderModel.value.driverId!.isNotEmpty) {
      nonAcChargeValue = double.tryParse(driverUserModel
              .value.vehicleInformation!.nonAcPerKmRate
              .toString()) ??
          0.0;
      acChargeValue = double.tryParse(driverUserModel
              .value.vehicleInformation!.nonAcPerKmRate
              .toString()) ??
          0.0;
      kmCharge = double.tryParse(
              driverUserModel.value.vehicleInformation!.perKmRate ?? '0.0') ??
          0.0;
    } else {
      nonAcChargeValue =
          double.tryParse(orderModel.value.service!.nonAcCharge.toString()) ??
              0.0;
      acChargeValue =
          double.tryParse(orderModel.value.service!.acCharge.toString()) ?? 0.0;
      kmCharge =
          double.tryParse(orderModel.value.service!.kmCharge ?? '0.0') ?? 0.0;
    }

    totalChargeOfMinute.value =
        double.parse(durationValueInMinutes.toString()) *
            double.parse(orderModel.value.service!.perMinuteCharge.toString());
    basicFareCharge.value =
        double.parse(orderModel.value.service!.basicFareCharge.toString());
    holdingCharge.value =
        double.parse(orderModel.value.totalHoldingCharges.toString());
    if (distance <=
        double.parse(orderModel.value.service!.basicFare.toString())) {
      if (currentTime.isAfter(startNightTimeString) &&
          currentTime.isBefore(endNightTimeString)) {
        amount.value = amount.value *
            double.parse(orderModel.value.service!.nightCharge.toString());
      } else {
        amount.value =
            double.parse(orderModel.value.service!.basicFareCharge.toString());
      }
    } else {
      double distanceValue =
          double.tryParse(orderModel.value.distance.toString()) ?? 0.0;
      double basicFareValue =
          double.tryParse(orderModel.value.service!.basicFare.toString()) ??
              0.0;
      double extraDist = distanceValue - basicFareValue;

      double perKmCharge = orderModel.value.service!.isAcNonAc == true
          ? orderModel.value.isAcSelected == false
              ? nonAcChargeValue
              : acChargeValue
          : kmCharge;
      amount.value = (perKmCharge * extraDist);

      if (currentTime.isAfter(startNightTimeString) &&
          currentTime.isBefore(endNightTimeString)) {
        totalChargeOfMinute.value = totalChargeOfMinute.value *
            double.parse(orderModel.value.service!.nightCharge.toString());
        basicFareCharge.value = basicFareCharge.value *
            double.parse(orderModel.value.service!.nightCharge.toString());
        holdingCharge.value = holdingCharge.value *
            double.parse(orderModel.value.service!.nightCharge.toString());
      }
    }

    if (orderModel.value.finalRate != null &&
        orderModel.value.finalRate != '0.0') {
      amount.value = double.parse(orderModel.value.finalRate.toString()) -
          basicFareCharge.value -
          totalChargeOfMinute.value -
          holdingCharge.value;
    } else {
      amount.value = amount.value *
          double.parse(orderModel.value.service!.nightCharge.toString());
    }

    subTotal.value = amount.value +
        basicFareCharge.value +
        totalChargeOfMinute.value +
        holdingCharge.value;

    log("===>Subtotal${subTotal.value}");
    if (orderModel.value.taxList != null) {
      for (var element in orderModel.value.taxList!) {
        taxAmount.value = taxAmount.value +
            Constant().calculateTax(
                amount: (subTotal.value - double.parse(couponAmount.value))
                    .toString(),
                taxModel: element);
      }
    }
    total.value =
        (subTotal.value - double.parse(couponAmount.value)) + taxAmount.value;
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
