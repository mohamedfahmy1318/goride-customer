// ignore_for_file: file_names

import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const languageCodeKey = "languageCodeKey";
  static const themKey = "themKey";
  static const isFinishOnBoardingKey = "isFinishOnBoardingKey";
  static const chatEulaAcceptedKey = "chatEulaAcceptedKey";
  // Set ONLY after subscribeToTopic("goRide_customer") succeeds, so we don't
  // re-enqueue an FCM registration op every launch (the TOO_MANY_REGISTRATIONS
  // leak). Keyed on the topic name so a future topic rename re-subscribes.
  static const fcmTopicSubscribedKey = "topicSubscribed_goRide_customer";
  static const lastSyncedFcmTokenKey = "lastSyncedFcmToken_customer";
  static const firestoreSetupVersionKey = "firestoreSetupVersion";

  static late SharedPreferences pref;

  static initPref() async {
    pref = await SharedPreferences.getInstance();
  }

  static bool getBoolean(String key) {
    return pref.getBool(key) ?? false;
  }

  static Future<void> setBoolean(String key, bool value) async {
    await pref.setBool(key, value);
  }

  static String getString(String key) {
    return pref.getString(key) ?? "";
  }

  static Future<void> setString(String key, String value) async {
    await pref.setString(key, value);
  }

  static int getInt(String key) {
    return pref.getInt(key) ?? 0;
  }

  static Future<void> setInt(String key, int value) async {
    await pref.setInt(key, value);
  }

  static Future<void> clearSharPreference() async {
    await pref.clear();
  }

  static Future<void> clearKeyData(String key) async {
    await pref.remove(key);
  }
}
