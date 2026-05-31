import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Global connectivity service that monitors network status
/// and shows a banner when the device goes offline.
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final RxBool isConnected = true.obs;
  final Rx<ConnectivityResult> connectionType = ConnectivityResult.none.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      log('ConnectivityService._initConnectivity error: $e');
      isConnected.value = true; // Assume connected if check fails
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    connectionType.value = result;

    final wasConnected = isConnected.value;
    isConnected.value = result != ConnectivityResult.none;

    if (!isConnected.value && wasConnected) {
      // Just went offline
      _showOfflineBanner();
    } else if (isConnected.value && !wasConnected) {
      // Just came back online
      _dismissOfflineBanner();
      // Only show a GetX snackbar if Get has been initialized (GetMaterialApp built)
      if (Get.context != null) {
        Get.snackbar(
          'متصل بالإنترنت',
          'تم استعادة الاتصال بالإنترنت',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          icon: const Icon(Icons.wifi, color: Colors.white),
        );
      }
    }
  }

  void _showOfflineBanner() {
    if (Get.context == null) {
      return; // avoid calling Get.* before GetMaterialApp exists
    }

    Get.snackbar(
      'لا يوجد اتصال بالإنترنت',
      'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 30),
      isDismissible: true,
      icon: const Icon(Icons.wifi_off, color: Colors.white),
      mainButton: TextButton(
        onPressed: () async {
          if (Get.context != null) Get.closeCurrentSnackbar();
          final results = await _connectivity.checkConnectivity();
          _updateStatus(results);
        },
        child:
            const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _dismissOfflineBanner() {
    if (Get.context != null && Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }

  /// Check if currently connected (for one-off checks)
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

/// A wrapper widget that shows an offline banner at the top of the screen.
/// Wrap your main content with this widget.
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final service = Get.find<ConnectivityService>();
          if (service.isConnected.value) return const SizedBox.shrink();
          return Material(
            child: Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'لا يوجد اتصال بالإنترنت'.tr,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        Expanded(child: child),
      ],
    );
  }
}
