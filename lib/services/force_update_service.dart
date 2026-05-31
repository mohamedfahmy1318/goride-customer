import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Force Update service using Firebase Remote Config.
///
/// Remote Config keys to set in Firebase Console:
/// - `force_update_customer_version` : minimum required version (e.g. "1.2.0")
/// - `force_update_enabled` : "true" or "false"
/// - `update_message_ar` : Arabic update message
/// - `update_message_en` : English update message
/// - `play_store_url` : Play Store URL for the customer app
/// - `app_store_url` : App Store URL for the customer app
class ForceUpdateService {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  /// Initialize Remote Config with defaults and fetch latest values
  static Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Short interval so a published force-update reaches users on their
        // next app open instead of waiting out a long cache window.
        minimumFetchInterval: const Duration(minutes: 5),
      ));

      // Set defaults
      await _remoteConfig.setDefaults({
        'force_update_enabled': false,
        'force_update_customer_version': '1.0.0',
        'update_message_ar': 'يجب تحديث التطبيق للاستمرار في الاستخدام',
        'update_message_en':
            'Please update the app to continue using the service',
        'play_store_url': '',
        'app_store_url': '',
      });

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      log('ForceUpdateService.init error: $e');
    }
  }

  /// Check if force update is needed. Call this on app start.
  static Future<void> checkForUpdate() async {
    try {
      // Re-fetch to get latest values
      await _remoteConfig.fetchAndActivate();

      final enabled = _remoteConfig.getBool('force_update_enabled');
      if (!enabled) return;

      final minVersion =
          _remoteConfig.getString('force_update_customer_version');
      if (minVersion.isEmpty) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isUpdateRequired(currentVersion, minVersion)) {
        _showForceUpdateDialog();
      }
    } catch (e) {
      log('ForceUpdateService.checkForUpdate error: $e');
      // Don't block the app if remote config fails
    }
  }

  /// Compare version strings. Returns true if current < minimum.
  static bool _isUpdateRequired(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minimumParts = minimum.split('.').map(int.parse).toList();

      // Pad shorter list with zeros
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (minimumParts.length < 3) {
        minimumParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < minimumParts[i]) return true;
        if (currentParts[i] > minimumParts[i]) return false;
      }
      return false; // Same version
    } catch (e) {
      log('ForceUpdateService._isUpdateRequired error: $e');
      return false;
    }
  }

  /// Show a non-dismissible dialog forcing the user to update
  static void _showForceUpdateDialog() {
    final messageAr = _remoteConfig.getString('update_message_ar');
    final playStoreUrl = _remoteConfig.getString('play_store_url');
    final appStoreUrl = _remoteConfig.getString('app_store_url');

    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text(
            'تحديث مطلوب',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                messageAr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final url = GetPlatform.isIOS ? appStoreUrl : playStoreUrl;
                  if (url.isNotEmpty) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('تحديث الآن', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
