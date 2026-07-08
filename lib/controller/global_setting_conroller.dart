import 'dart:convert';
import 'dart:developer';

import 'package:customer/constant/constant.dart';
import 'package:customer/model/currency_model.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/services/localization_service.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    notificationService.initInfo().then((value) async {
      // Guard the whole continuation: getToken() can throw TOO_MANY_REGISTRATIONS
      // and this runs in a fire-and-forget .then(), so an unguarded rejection
      // becomes an unhandled async error (fatal at app start). Degrade instead.
      try {
        String? token = await NotificationService.getToken();
        if (token != null && FirebaseAuth.instance.currentUser != null) {
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
              .then((value) {
            if (value != null) {
              UserModel driverUserModel = value;
              driverUserModel.fcmToken = token;
              // Save language to Firestore
              String langPref =
                  Preferences.getString(Preferences.languageCodeKey);
              if (langPref.isNotEmpty) {
                try {
                  final langData = jsonDecode(langPref);
                  driverUserModel.language = langData['code'] ?? 'ar';
                } catch (_) {
                  driverUserModel.language = 'ar';
                }
              }
              FireStoreUtils.updateUser(driverUserModel);
            }
          });
        }
      } catch (e) {
        log('notificationInit error: $e');
      }
    });
  }
}
