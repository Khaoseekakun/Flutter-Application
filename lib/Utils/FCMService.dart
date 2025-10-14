import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Note: You must add flutter_local_notifications to your pubspec.yaml
// to display foreground notifications on iOS/Android.
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  void initializeFCM() async {
    await _requestPermissionsAndGetToken();

    _setupForegroundMessageHandler();

    _setupMessageOpenedAppHandler();

    _checkForInitialMessage();
  }

  Future<void> _requestPermissionsAndGetToken() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', fcmToken);
      }
    } else {
      debugPrint('User denied permission for notifications.');
    }
  }

  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('==> FOREGROUND MESSAGE RECEIVED <==');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
      // }
    });
  }

  void _setupMessageOpenedAppHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('==> NOTIFICATION TAPPED <==');
      debugPrint('Message ID: ${message.messageId}');

      final route = message.data['route'];
      if (route != null) {
        Get.toNamed(route);
      }
    });
  }

  void _checkForInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('==> APP OPENED FROM INITIAL MESSAGE <==');
      final route = initialMessage.data['route'];
      if (route != null) {
        Get.toNamed(route);
      }
    }
  }

  Future<String> getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token') ?? '';
  }

  // Placeholder for local notification function (requires extra package setup)
  // Future<void> _showLocalNotification(RemoteMessage message) async {
  //   const androidDetails = AndroidNotificationDetails(
  //     'high_importance_channel', // Replace with your actual channel ID
  //     'High Importance Notifications',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );
  //   const notificationDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

  //   await _localNotifications.show(
  //     0, // Notification ID
  //     message.notification?.title,
  //     message.notification?.body,
  //     notificationDetails,
  //     payload: 'item x',
  //   );
  // }
}
