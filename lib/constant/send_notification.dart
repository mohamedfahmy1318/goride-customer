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
      bool dataOnly = false,
      String? androidChannelId,
      String? titleAr,
      String? bodyAr,
      String? recipientId,
      String? recipientType}) async {
    if (token.isEmpty) {
      debugPrint('FCM token is empty, skipping notification');
      return false;
    }

    try {
      final callable = _functions.httpsCallable('sendNotification');
      final String payloadType = (payload['type'] ?? '').toString();
      final bool isRideRequest =
          payloadType == 'city_order' || payloadType == 'intercity_order';
      final String resolvedChannelId = androidChannelId ??
          (isRideRequest ? 'ride_request_alert_v3' : 'goRide-driver');

      final Map<String, dynamic> callData = {
        'token': token,
        'title': title,
        'body': body,
        'payload': payload.map((key, value) => MapEntry(key, value.toString())),
        // Ride requests are HYBRID now (the Cloud Function forces notification+data
        // for ride types). The data wakes the app to present the takeover; the
        // notification block is the last-resort cue only when the app is dead.
        'dataOnly': dataOnly,
        'androidChannelId': resolvedChannelId,
        'priority': 'high',
      };
      if (titleAr != null) callData['titleAr'] = titleAr;
      if (bodyAr != null) callData['bodyAr'] = bodyAr;
      if (recipientId != null) callData['recipientId'] = recipientId;
      if (recipientType != null) callData['recipientType'] = recipientType;
      final result = await callable.call<Map<String, dynamic>>(callData);

      log('Notification sent via Cloud Function: ${result.data}');
      return true;
    } catch (e) {
      log('Failed to send notification via Cloud Function: $e');
      return false;
    }
  }
}
