import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/ui/auth_screen/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  RxString countryCode = "+20".obs;

  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;

  sendCode() async {
    ShowToastDialog.showLoader("Please wait".tr);
    await FirebaseAuth.instance
        .verifyPhoneNumber(
      phoneNumber: countryCode + phoneNumberController.value.text,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        debugPrint("FirebaseAuthException--->${e.message}");
        ShowToastDialog.closeLoader();
        if (e.code == 'invalid-phone-number') {
          ShowToastDialog.showToast("The provided phone number is not valid.".tr);
        } else if (e.code == 'missing-client-identifier') {
          ShowToastDialog.showToast(
              "Please check your internet connection and try again.".tr);
        } else if (e.code == 'too-many-requests') {
          ShowToastDialog.showToast(
              "Too many requests. Please try again later.".tr);
        } else if (e.code == 'app-not-authorized') {
          ShowToastDialog.showToast(
              "This app is not authorized to use Firebase Authentication.".tr);
        } else {
          ShowToastDialog.showToast(e.message ?? "Something went wrong.".tr);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        ShowToastDialog.closeLoader();
        Get.to(const OtpScreen(), arguments: {
          "countryCode": countryCode.value,
          "phoneNumber": phoneNumberController.value.text,
          "verificationId": verificationId,
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    )
        .catchError((error) {
      debugPrint("catchError--->$error");
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          "You have try many time please send otp after some time".tr);
    });
  }
}
