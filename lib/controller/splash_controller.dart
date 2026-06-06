import 'dart:async';

import 'package:customer/controller/global_setting_conroller.dart';
import 'package:customer/services/force_update_service.dart';
import 'package:customer/ui/auth_screen/login_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/ui/on_boarding_screen.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    _waitAndRedirect();
    super.onInit();
  }

  Future<void> _waitAndRedirect() async {
    // Wait at least 3 seconds AND for settings to finish loading
    final minDelay = Future.delayed(const Duration(seconds: 3));
    final settingsReady = _waitForSettings();
    await Future.wait([minDelay, settingsReady]);

    // Initialize Remote Config and check for force updates
    await ForceUpdateService.init();
    final mustUpdate = await ForceUpdateService.checkForUpdate();
    if (mustUpdate) {
      // A non-dismissible update dialog is up. Do NOT continue to
      // redirectScreen() — its Get.offAll(...) would wipe the dialog off the
      // navigation stack and let the outdated app through.
      return;
    }

    redirectScreen();

    // Soft/optional "update available" prompt — shown (dismissible) over the
    // landing screen after redirect, so it isn't wiped by the Get.offAll above.
    ForceUpdateService.checkOptionalUpdate();
  }

  Future<void> _waitForSettings() async {
    try {
      final controller = Get.find<GlobalSettingController>();
      // Wait up to 10 seconds for settings to load
      for (int i = 0; i < 100; i++) {
        if (controller.settingsLoaded.value) return;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (_) {
      // Controller not found, proceed anyway
    }
  }

  redirectScreen() async {
    if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
      Get.offAll(const OnBoardingScreen());
    } else {
      bool isLogin = await FireStoreUtils.isLogin();
      if (isLogin == true) {
        Get.offAll(const DashBoardScreen());
      } else {
        Get.offAll(const LoginScreen());
      }
    }
  }
}
