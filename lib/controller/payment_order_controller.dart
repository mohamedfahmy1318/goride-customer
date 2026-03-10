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
import 'package:customer/ui/dashboard_screen.dart';
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
    ShowToastDialog.showLoader("Please wait");
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
          titleAr: 'تم استلام الدفع',
          body:
              '${userModel.value.fullName}  has paid ${Constant.amountShow(amount: total.value.toString())} for the completed ride.Check your earnings for details.',
          bodyAr:
              '${userModel.value.fullName} دفع ${Constant.amountShow(amount: total.value.toString())} للرحلة المكتملة. تحقق من أرباحك.',
          payload: playLoad,
          recipientId: orderModel.value.driverId,
          recipientType: 'driver');
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
        Get.offAll(() => const DashBoardScreen());
      }
    });
  }

  completeCashOrder() async {
    orderModel.value.paymentType = selectedPaymentMethod.value;
    orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;

    await SendNotification.sendOneNotification(
        token: driverUserModel.value.fcmToken.toString(),
        title: 'Payment changed',
        titleAr: 'تم تغيير طريقة الدفع',
        body: '${userModel.value.fullName} has changed payment method.',
        bodyAr: '${userModel.value.fullName} قام بتغيير طريقة الدفع.',
        payload: {},
        recipientId: orderModel.value.driverId,
        recipientType: 'driver');

    FireStoreUtils.setOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.showToast(
            "Your payment request sent to driver please wait to the conformation"
                .tr);
        Get.offAll(() => const DashBoardScreen());
      }
    });
  }

  completeWalletOrder() async {
    ShowToastDialog.showLoader("Please wait");

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
          titleAr: 'تم استلام الدفع',
          body:
              '${userModel.value.fullName} has paid ${Constant.amountShow(amount: total.value.toString())} from wallet.',
          bodyAr:
              '${userModel.value.fullName} دفع ${Constant.amountShow(amount: total.value.toString())} من المحفظة.',
          payload: playLoad,
          recipientId: orderModel.value.driverId,
          recipientType: 'driver');
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
        Get.offAll(() => const DashBoardScreen());
      }
    });
  }

  Rx<CouponModel> selectedCouponModel = CouponModel().obs;
  RxString couponAmount = "0.0".obs;

  RxDouble amount = 0.0.obs;
  RxDouble subTotal = 0.0.obs;
  RxDouble total = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble totalChargeOfMinute = 0.0.obs;
  RxDouble holdingCharge = 0.0.obs;
  RxDouble meterStartCharge = 0.0.obs;

  calculateAmount() async {
    taxAmount.value = 0.0;
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
      amount.value = double.parse(orderModel.value.finalRate.toString()) -
          meterStartCharge.value -
          totalChargeOfMinute.value -
          holdingCharge.value;
    }

    subTotal.value = amount.value +
        meterStartCharge.value +
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
