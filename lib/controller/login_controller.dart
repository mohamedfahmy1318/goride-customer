import 'dart:async';
import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/services/apple_sign_in_service.dart';
import 'package:customer/services/google_sign_in_service.dart';
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/ui/auth_screen/otp_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Known-good phone-number lengths per country code. Firebase returns
// `invalid-phone-number` for bad lengths, but each rejected attempt still
// counts toward the device's abuse budget — so we validate locally first.
// Extend this map as the app enters new markets.
const Map<String, int> _expectedPhoneDigitsByCountry = {
  '+222': 8, // Mauritania
  '+20': 10, // Egypt
  '+966': 9, // Saudi Arabia
  '+971': 9, // UAE
};

class LoginController extends GetxController {
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  RxString countryCode = "+20".obs;

  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;

  // Local rate-limit mirror: after Firebase tells us the number/device is
  // rate-limited, block new OTP requests for a cooldown so the user doesn't
  // tap "التالي" repeatedly and make Firebase's abuse detection worse.
  final RxBool isInCooldown = false.obs;
  final RxInt cooldownSecondsRemaining = 0.obs;
  Timer? _cooldownTimer;

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    super.onClose();
  }

  /// Strip whitespace, dashes, parens. Returns null if the input is empty
  /// or contains non-digit characters after sanitization.
  static String? _sanitizePhoneDigits(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s\-().]'), '');
    if (cleaned.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return null;
    return cleaned;
  }

  /// True when [digits] is a plausible local number for [countryCode].
  static bool _isValidLengthForCountry(String countryCode, String digits) {
    final expected = _expectedPhoneDigitsByCountry[countryCode];
    if (expected == null) {
      // Unknown country → fall back to the ITU general bounds.
      return digits.length >= 6 && digits.length <= 15;
    }
    return digits.length == expected;
  }

  String _phoneLengthErrorMessage(String countryCode) {
    final expected = _expectedPhoneDigitsByCountry[countryCode];
    if (expected == null) {
      return "Please enter a valid phone number".tr;
    }
    return "${"Phone number must be".tr} $expected ${"digits for".tr} $countryCode";
  }

  /// Map Firebase Auth errors to messages users can act on. The raw
  /// `e.message` strings are English-only and sometimes overly technical.
  String _friendlyAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return "The provided phone number is not valid.".tr;
      case 'too-many-requests':
        // Firebase returns this for both "too many attempts for this number"
        // and "device blocked due to unusual activity" — same remediation.
        return "Too many attempts. Please wait a minute and try again.".tr;
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return "App verification failed. Please reinstall and try again, or contact support if it keeps happening."
            .tr;
      case 'quota-exceeded':
        return "Service is busy. Please try again in a few minutes.".tr;
      case 'captcha-check-failed':
        return "Verification check failed. Please try again.".tr;
      case 'network-request-failed':
        return "No internet connection. Please check your network.".tr;
      default:
        return e.message ?? "Something went wrong. Please try again.".tr;
    }
  }

  void _startCooldown({int seconds = 60}) {
    _cooldownTimer?.cancel();
    isInCooldown.value = true;
    cooldownSecondsRemaining.value = seconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (cooldownSecondsRemaining.value <= 1) {
        t.cancel();
        _cooldownTimer = null;
        isInCooldown.value = false;
        cooldownSecondsRemaining.value = 0;
      } else {
        cooldownSecondsRemaining.value -= 1;
      }
    });
  }

  sendCode() async {
    // 1. Local cooldown check.
    if (isInCooldown.value) {
      ShowToastDialog.showToast(
          "${"Please wait".tr} ${cooldownSecondsRemaining.value}s");
      return;
    }

    // 2. Client-side validation — never call Firebase with obviously-bad
    //    input. Each invalid-format rejection still counts against the
    //    device's abuse quota.
    final rawInput = phoneNumberController.value.text;
    final digits = _sanitizePhoneDigits(rawInput);
    if (digits == null) {
      ShowToastDialog.showToast("Please enter a valid phone number".tr);
      return;
    }
    if (!_isValidLengthForCountry(countryCode.value, digits)) {
      ShowToastDialog.showToast(_phoneLengthErrorMessage(countryCode.value));
      return;
    }

    // Store the sanitized form back so downstream screens see clean digits.
    phoneNumberController.value.text = digits;

    ShowToastDialog.showLoader("Please wait".tr);

    const bool forceRecaptchaForDebug = bool.fromEnvironment(
      'FORCE_RECAPTCHA_FOR_DEBUG',
      defaultValue: false,
    );
    const bool disableAppVerificationForTesting = bool.fromEnvironment(
      'DISABLE_APP_VERIFICATION_FOR_TESTING',
      defaultValue: false,
    );

    if (kDebugMode &&
        (forceRecaptchaForDebug || disableAppVerificationForTesting)) {
      // Debug behavior is opt-in through dart-define flags.
      await FirebaseAuth.instance.setSettings(
        forceRecaptchaFlow: forceRecaptchaForDebug,
        appVerificationDisabledForTesting: disableAppVerificationForTesting,
      );
    }

    await FirebaseAuth.instance
        .verifyPhoneNumber(
          phoneNumber: countryCode.value + digits,
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            debugPrint("FirebaseAuthException--->${e.code}: ${e.message}");
            ShowToastDialog.closeLoader();
            ShowToastDialog.showToast(_friendlyAuthErrorMessage(e));
            if (e.code == 'too-many-requests' ||
                e.code == 'quota-exceeded') {
              _startCooldown();
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            ShowToastDialog.closeLoader();
            Get.to(
              () => const OtpScreen(),
              arguments: {
                "countryCode": countryCode.value,
                "phoneNumber": digits,
                "verificationId": verificationId,
              },
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        )
        .catchError((error) {
          debugPrint("catchError--->$error");
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Too many attempts. Please wait a minute and try again.".tr,
          );
          _startCooldown();
        });
  }

  signInWithApple() async {
    ShowToastDialog.showLoader("Please wait".tr);

    final result = await AppleSignInService.signIn();

    if (result.cancelled) {
      ShowToastDialog.closeLoader();
      return;
    }

    if (!result.isSuccess || result.credential?.user == null) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          result.errorMessage ?? "Apple sign-in failed.".tr);
      return;
    }

    final user = result.credential!.user!;

    try {
      final userExit = await FireStoreUtils.userExitOrNot(user.uid);
      ShowToastDialog.closeLoader();

      if (userExit == true) {
        log("----->existing apple user");
        UserModel? userModel = await FireStoreUtils.getUserProfile(user.uid);
        if (userModel != null) {
          if (userModel.isActive == true) {
            Get.offAll(const DashBoardScreen());
          } else {
            await FirebaseAuth.instance.signOut();
            ShowToastDialog.showToast(
                "This user is disable please contact administrator".tr);
          }
        }
      } else {
        log("----->new apple user");
        UserModel userModel = UserModel();
        userModel.id = user.uid;
        userModel.email = user.email;
        userModel.fullName = user.displayName;
        userModel.profilePic = user.photoURL;
        userModel.loginType = Constant.appleLoginType;

        Get.to(const InformationScreen(), arguments: {
          "userModel": userModel,
        });
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to load profile. Try again.".tr);
    }
  }

  signInWithGoogle() async {
    ShowToastDialog.showLoader("Please wait".tr);

    final result = await GoogleSignInService.signIn();

    if (result.cancelled) {
      ShowToastDialog.closeLoader();
      return;
    }

    if (!result.isSuccess || result.credential?.user == null) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          result.errorMessage ?? "Google sign-in failed.".tr);
      return;
    }

    final user = result.credential!.user!;

    try {
      final userExit = await FireStoreUtils.userExitOrNot(user.uid);
      ShowToastDialog.closeLoader();

      if (userExit == true) {
        log("----->existing google user");
        UserModel? userModel = await FireStoreUtils.getUserProfile(user.uid);
        if (userModel != null) {
          if (userModel.isActive == true) {
            Get.offAll(const DashBoardScreen());
          } else {
            await FirebaseAuth.instance.signOut();
            await GoogleSignInService.signOut();
            ShowToastDialog.showToast(
                "This user is disable please contact administrator".tr);
          }
        }
      } else {
        log("----->new google user");
        UserModel userModel = UserModel();
        userModel.id = user.uid;
        userModel.email = user.email;
        userModel.fullName = user.displayName;
        userModel.profilePic = user.photoURL;
        userModel.loginType = Constant.googleLoginType;

        Get.to(const InformationScreen(), arguments: {
          "userModel": userModel,
        });
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to load profile. Try again.".tr);
    }
  }
}
