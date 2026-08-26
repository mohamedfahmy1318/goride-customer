import 'dart:convert';
import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/model/currency_model.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/services/localization_service.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:get/get.dart';

class GlobalSettingController extends GetxController {
  var settingsLoaded = false.obs;

  @override
  void onInit() {
    notificationInit();
    getCurrentCurrency();
    super.onInit();
  }

  getCurrentCurrency() async {
    try {
      if (Preferences.getString(Preferences.languageCodeKey)
          .toString()
          .isNotEmpty) {
        LanguageModel languageModel = Constant.getLanguage();
        LocalizationService().changeLocale(languageModel.code.toString());
      } else {
        await FireStoreUtils.getLanguage().then((value) {
          if (value != null) {
            List<LanguageModel> languageList = value;

            if (languageList
                .where((element) => element.isDefault == true)
                .isNotEmpty) {
              LanguageModel languageModel = languageList
                  .firstWhere((element) => element.isDefault == true);
              Preferences.setString(
                  Preferences.languageCodeKey, jsonEncode(languageModel));
              LocalizationService().changeLocale(languageModel.code.toString());
            }
          }
        });
      }

      await FireStoreUtils().getCurrency().then((value) {
        if (value != null) {
          Constant.currencyModel = value;
        } else {
          Constant.currencyModel = CurrencyModel(
              id: "",
              code: "MRU",
              decimalDigits: 0,
              enable: true,
              name: "Mauritanian Ouguiya",
              symbol: "أوقية",
              symbolAtRight: true);
        }
      });
      try {
        await FireStoreUtils().getSettings();
      } catch (e) {
        log('Failed to load settings: $e');
      }
    } catch (e) {
      log("❌ Error loading global settings: $e");
      Constant.currencyModel = CurrencyModel(
          id: "",
          code: "MRU",
          decimalDigits: 0,
          enable: true,
          name: "Mauritanian Ouguiya",
          symbol: "أوقية",
          symbolAtRight: true);
    } finally {
      settingsLoaded.value = true;
    }
  }

  NotificationService notificationService = NotificationService();

  notificationInit() {
    // initInfo owns the deduped token sync. Avoid the former full user read +
    // full document write on every cold start.
    notificationService.initInfo().catchError((e) {
      log('notificationInit error: $e');
    });
  }
}
