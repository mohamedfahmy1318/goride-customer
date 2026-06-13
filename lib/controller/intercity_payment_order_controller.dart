import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class IntercityPaymentOrderController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    getArgument();
    getPaymentData();
    super.onInit();
  }

  Rx<InterCityOrderModel> orderModel = InterCityOrderModel().obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
    }
    update();
  }

  Rx<UserModel> userModel = UserModel().obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;

  RxString selectedPaymentMethod = "".obs;

  getPaymentData() async {
    selectedPaymentMethod.value = orderModel.value.paymentType.toString();

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
    isLoading.value = false;
    update();
  }

  completeOrder() async {
    ShowToastDialog.showLoader("Please wait");
    orderModel.value.paymentStatus = true;
    orderModel.value.paymentType = selectedPaymentMethod.value;
    orderModel.value.status = Constant.rideComplete;
    orderModel.value.coupon = selectedCouponModel.value;

    // Driver-wallet settlement (earnings credit + admin commission) is now
    // SERVER-SIDE via the settleIntercityCommissionOnCompletion Cloud Function.
    // Legacy client-side credit + commission debit removed (all-cash).

    await FireStoreUtils.getIntercityFirstOrderOrNOt(orderModel.value)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateIntercityReferralAmount(orderModel.value);
      }
    });

    if (driverUserModel.value.fcmToken != null) {
      Map<String, dynamic> playLoad = <String, dynamic>{
        "type": "intercity_order_payment_complete",
        "orderId": orderModel.value.id
      };

      await SendNotification.sendOneNotification(
          token: driverUserModel.value.fcmToken.toString(),
          title: 'Payment Received',
          titleAr: 'تم استلام الدفع',
          body:
              '${userModel.value.fullName}  has paid ${Constant.amountShow(amount: calculateAmount().toString())} for the completed ride.Check your earnings for details.',
          bodyAr:
              '${userModel.value.fullName} دفع ${Constant.amountShow(amount: calculateAmount().toString())} للرحلة المكتملة. تحقق من أرباحك.',
          payload: playLoad,
          recipientId: orderModel.value.driverId,
          recipientType: 'driver');
    }

    await FireStoreUtils.setInterCityOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Ride Complete successfully");
        Get.offAll(() => const DashBoardScreen());
      }
    });
  }

  completeCashOrder() async {
    ShowToastDialog.showLoader("Please wait");

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

    await FireStoreUtils.setInterCityOrder(orderModel.value).then((value) {
      if (value == true) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Payment method update successfully");
        Get.offAll(() => const DashBoardScreen());
      }
    });
  }

  Rx<CouponModel> selectedCouponModel = CouponModel().obs;
  RxString couponAmount = "0.0".obs;

  double calculateAmount() {
    RxString taxAmount = "0.0".obs;
    if (orderModel.value.taxList != null) {
      for (var element in orderModel.value.taxList!) {
        taxAmount.value = (double.parse(taxAmount.value) +
                Constant().calculateTax(
                    amount:
                        (double.parse(orderModel.value.finalRate.toString()) -
                                double.parse(couponAmount.value.toString()))
                            .toString(),
                    taxModel: element))
            .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
      }
    }
    return (double.parse(orderModel.value.finalRate.toString()) -
            double.parse(couponAmount.value.toString())) +
        double.parse(taxAmount.value);
  }
}
