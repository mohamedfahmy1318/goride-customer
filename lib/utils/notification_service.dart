import 'dart:convert';
import 'dart:developer';

import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:customer/ui/intercityOrders/intercity_payment_order_screen.dart';
import 'package:customer/ui/orders/payment_order_screen.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");
  // Do NOT call display() here — messages with a 'notification' field
  // are automatically shown by the system in background.
  // Calling display() would create a duplicate notification.
}

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'goRide-customer', // id
    'GoRide Customer Notifications', // name
    description: 'Notifications for GoRide Customer App',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  initInfo() async {
    // Create the notification channel for Android 8.0+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (request.authorizationStatus == AuthorizationStatus.authorized ||
        request.authorizationStatus == AuthorizationStatus.provisional) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid,
              iOS: iosInitializationSettings);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: (payload) {});
      setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    // Register background message handler at top level
    FirebaseMessaging.onBackgroundMessage(firebaseMessageBackgroundHandle);

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log("Initial message received: ${initialMessage.messageId}");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("::::::::::::onMessage:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        display(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        if (message.data['type'] == "chat") {
          UserModel? customer =
              await FireStoreUtils.getUserProfile(message.data['customerId']);
          DriverUserModel? driver =
              await FireStoreUtils.getDriver(message.data['driverId']);

          Get.to(ChatScreens(
            driverId: driver!.id,
            customerId: customer!.id,
            customerName: customer.fullName,
            customerProfileImage: customer.profilePic,
            driverName: driver.fullName,
            driverProfileImage: driver.profilePic,
            orderId: message.data['orderId'],
            token: driver.fcmToken,
          ));
        } else if (message.data['type'] == "city_order_complete") {
          OrderModel? orderModel =
              await FireStoreUtils.getOrder(message.data['orderId']);
          Get.to(const PaymentOrderScreen(), arguments: {
            "orderModel": orderModel,
          });
        } else if (message.data['type'] == "intercity_order_complete") {
          InterCityOrderModel? orderModel =
              await FireStoreUtils.getInterCityOrder(message.data['orderId']);
          Get.to(const InterCityPaymentOrderScreen(), arguments: {
            "orderModel": orderModel,
          });
        }
      }
    });
    await FirebaseMessaging.instance.subscribeToTopic("goRide_customer");
  }

  static Future<String?> getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token;
  }

  void display(RemoteMessage message) async {
    log('Got a message whilst in the foreground!');
    log('Message data: ${message.notification!.body.toString()}');
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      AndroidNotificationDetails notificationDetails =
          AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableVibration: true,
      );
      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
              presentAlert: true, presentBadge: true, presentSound: true);
      NotificationDetails notificationDetailsBoth = NotificationDetails(
          android: notificationDetails, iOS: darwinNotificationDetails);
      await FlutterLocalNotificationsPlugin().show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log(e.toString());
    }
  }
}
