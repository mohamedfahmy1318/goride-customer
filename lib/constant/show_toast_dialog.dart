import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class ShowToastDialog {
  static showToast(String? message, {Duration? duration}) {
    if (message == null || message.isEmpty) return;
    EasyLoading.showToast(message.tr, duration: duration);
  }

  static showLoader(String message) {
    EasyLoading.show(status: message.tr);
  }

  static closeLoader() {
    EasyLoading.dismiss();
  }
}
