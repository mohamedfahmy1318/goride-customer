// ignore_for_file: non_constant_identifier_names

import 'dart:developer';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';

class SendNotification {
  static final _functions = FirebaseFunctions.instance;

  static sendOneNotification(
      {required String token,
      required String title,
      required String body,
      required Map<String, dynamic> payload,
      bool dataOnly = false}) async {
    if (token.isEmpty) {
      debugPrint('FCM token is empty, skipping notification');
      return false;
    }

    try {
      final callable = _functions.httpsCallable('sendNotification');
      final result = await callable.call<Map<String, dynamic>>({
        'token': token,
        'title': title,
        'body': body,
        'payload': payload.map((key, value) => MapEntry(key, value.toString())),
        'dataOnly': dataOnly,
      });

      log('Notification sent via Cloud Function: ${result.data}');
      return true;
    } catch (e) {
      log('Failed to send notification via Cloud Function: $e');
      return false;
    }
  }
}
