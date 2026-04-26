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
import 'package:flutter/material.dart';
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
    // Only overwrite the coupon from post-placement selection on LEGACY
    // orders. Company-absorbs orders lock the coupon at booking time — the
    // persisted breakdown on the doc is authoritative.
    if (!hasPersistedBreakdown) {
      orderModel.value.coupon = selectedCouponModel.value;
    }
    orderModel.value.updateDate = Timestamp.now();

    // Driver wallet credit — gross fare + tax under company-absorbs so the
    // net delta after the commission debit equals persisted driverEarnings.
    final double driverCreditAmount = _driverWalletCreditAmount();

    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: driverCreditAmount.toString(),
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
            amount: driverCreditAmount.toString(),
            driverId: orderModel.value.driverId.toString());
      }
    });

    if (driverUserModel.value.subscriptionPlan?.id ==
        Constant.commissionSubscriptionID) {
      // Commission is computed on the GROSS fare under company-absorbs —
      // promos don't shrink the platform's take here; they shrink it via
      // the discount absorbed below the line (delta = commission − discount).
      final double commissionAmount = _commissionForSettlement();

      WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: "-$commissionAmount",
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
              amount: "-$commissionAmount",
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
    try {
      await _completeWalletOrderInternal();
    } catch (e, st) {
      log('completeWalletOrder failed: $e\n$st');
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Payment failed. Please contact support.");
    }
  }

  Future<void> _completeWalletOrderInternal() async {
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
    if (!hasPersistedBreakdown) {
      orderModel.value.coupon = selectedCouponModel.value;
    }
    orderModel.value.updateDate = Timestamp.now();

    // Credit driver wallet — see completeOrder for the company-absorbs rationale.
    final double driverCreditAmount = _driverWalletCreditAmount();
    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: driverCreditAmount.toString(),
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
            amount: driverCreditAmount.toString(),
            driverId: orderModel.value.driverId.toString());
      }
    });

    // Admin commission — on gross fare under company-absorbs.
    if (driverUserModel.value.subscriptionPlan?.id ==
        Constant.commissionSubscriptionID) {
      final double commissionAmount = _commissionForSettlement();

      WalletTransactionModel adminCommissionWallet = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: "-$commissionAmount",
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
              amount: "-$commissionAmount",
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

    final bool orderSaved =
        (await FireStoreUtils.setOrder(orderModel.value)) ?? false;
    ShowToastDialog.closeLoader();
    if (!orderSaved) {
      ShowToastDialog.showToast(
          "Payment was sent but the order failed to update. Please contact support.");
      return;
    }
    await _showWalletPaymentSuccessDialog();
    Get.offAll(() => const DashBoardScreen());
  }

  Future<void> _showWalletPaymentSuccessDialog() async {
    await Get.dialog<void>(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Text(
          'Paid ${Constant.amountShow(amount: total.value.toString())} from your wallet. The ride is now complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
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

  // ── Persisted fare breakdown (company-absorbs model) ────────────────────
  // These come straight off the OrderModel when the ride was booked under
  // the new flow (home_screen._proceedWithBooking populates them). When
  // present, they ARE the truth — we stop recomputing commission/earnings.
  // Legacy orders (placed before the company-absorbs migration) leave these
  // at zero and the old driver-absorbs math kicks in as a fallback.
  double _parseOrderField(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  double get persistedTotalFare =>
      _parseOrderField(orderModel.value.totalFare);
  double get persistedAdminCommission =>
      _parseOrderField(orderModel.value.adminCommissionAmount);
  double get persistedDriverEarnings =>
      _parseOrderField(orderModel.value.driverEarnings);
  double get persistedDiscountAmount =>
      _parseOrderField(orderModel.value.discountAmount);
  double get persistedFinalPayable =>
      _parseOrderField(orderModel.value.finalPayableAmount);

  /// True when the order carries the company-absorbs breakdown. Any order
  /// placed after the Laravel+customer-app migration has this; older orders
  /// don't and fall through to the legacy driver-absorbs math.
  bool get hasPersistedBreakdown =>
      persistedTotalFare > 0 || persistedFinalPayable > 0;

  /// Commission used for wallet settlement. Under company-absorbs the
  /// driver's wallet is debited the commission computed on the GROSS fare
  /// (persisted), not the discounted amount — so promos never reduce the
  /// driver's take.
  double _commissionForSettlement() {
    if (hasPersistedBreakdown) return persistedAdminCommission;
    // Legacy fallback — kept so older orders settle the way they were booked.
    return Constant.calculateOrderAdminCommission(
      amount: (subTotal.value - double.parse(couponAmount.value)).toString(),
      adminCommission: orderModel.value.adminCommission,
    );
  }

  /// Amount credited to the driver's wallet for the ride (before the
  /// commission debit that's posted as a separate transaction). Under
  /// company-absorbs this is the GROSS fare + tax so that the net wallet
  /// delta after the commission debit equals the persisted driverEarnings,
  /// independent of any coupon.
  double _driverWalletCreditAmount() {
    if (hasPersistedBreakdown) {
      return persistedTotalFare + taxAmount.value;
    }
    return total.value; // legacy: subTotal − coupon + tax
  }

  calculateAmount() async {
    taxAmount.value = 0.0;

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

      subTotal.value = amount.value +
          meterStartCharge.value +
          totalChargeOfMinute.value +
          holdingCharge.value;
    }

    log("===>Subtotal${subTotal.value}");

    // Under company-absorbs, prefer the persisted discount (fixed at booking)
    // over any post-placement coupon selection — the breakdown on the order
    // doc is immutable for the driver/dashboard and we shouldn't diverge.
    if (hasPersistedBreakdown && persistedDiscountAmount > 0) {
      couponAmount.value = persistedDiscountAmount.toStringAsFixed(2);
    }

    if (orderModel.value.taxList != null) {
      for (var element in orderModel.value.taxList!) {
        taxAmount.value = taxAmount.value +
            Constant().calculateTax(
                amount: (subTotal.value - double.parse(couponAmount.value))
                    .toString(),
                taxModel: element);
      }
    }

    // Customer-facing total: under company-absorbs it's the persisted
    // finalPayableAmount + tax (what the customer actually pays). Legacy
    // orders fall back to the pre-migration formula.
    if (hasPersistedBreakdown) {
      total.value = persistedFinalPayable + taxAmount.value;
    } else {
      total.value =
          (subTotal.value - double.parse(couponAmount.value)) + taxAmount.value;
    }
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
