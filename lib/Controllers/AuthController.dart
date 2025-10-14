import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:test1/Utils/FCMService.dart';

class AuthController extends GetxController {
  final isLoggedIn = false.obs;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    isLoggedIn.value = token != null && token.isNotEmpty;
  }

  Future<void> login(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setInt('user_id', userId);
    isLoggedIn.value = true;
    checkSaveFCMToken();
  }

  Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? -1;
  }

  Future<void> checkSaveFCMToken() async {
    final authController = Get.find<AuthController>();
    final fcmService = Get.find<FCMService>();
    int userId = await authController.getUserId();
    if (userId == -1) {
      debugPrint('User ID not found. Cannot save FCM token.');
      Get.snackbar('FCM Token', 'User ID not found. Cannot save FCM token.');
      return;
    }
    Get.snackbar('FCM Token', 'Retrieving FCM Token...');
    String fcmToken = await fcmService.getFCMToken();
    Get.snackbar('FCM Token', 'FCM Token retrieved: $fcmToken');
    String deviceInfo = await getDeviceId();
    Get.snackbar('Device Info', 'Device ID: $deviceInfo');
    if (fcmToken.isNotEmpty) {
      await authController.saveFCMToken(userId, fcmToken, deviceInfo);
      debugPrint('FCM Token saved to user profile.');
    } else {
      debugPrint('Failed to retrieve FCM Token.');
      Get.snackbar('FCM Token', 'Failed to retrieve FCM Token.');
    }
  }

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return info.id ?? info.fingerprint; // unique-ish ID
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown';
    } else {
      return 'unsupported-platform';
    }
  }

  Future<void> logout() async {
    isLoggedIn.value = false;
    await deleteFCMToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    Get.offAllNamed('/login');
  }

  Future<void> deleteFCMToken() async {
    final authController = Get.find<AuthController>();
    int userId = await authController.getUserId();
    if (userId == -1) {
      debugPrint('User ID not found. Cannot delete FCM token.');
      return;
    }
    String fcmToken = await Get.find<FCMService>().getFCMToken();
    String deviceInfo = await authController.getDeviceId();
    if (fcmToken.isNotEmpty) {
      await authController.removeFCMToken(userId, fcmToken, deviceInfo);
      debugPrint('FCM Token deleted from user profile.');
    } else {
      debugPrint('Failed to retrieve FCM Token.');
    }
  }

  Future<void> removeFCMToken(
    int user_id,
    String fcmToken,
    String deviceId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      debugPrint('User not logged in. Cannot remove FCM token.');
      return;
    } else {
      final response = await http.put(
        Uri.parse(
          '${dotenv.env['API_URL']}/api/notification/remove/${user_id}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token}',
        },
        body: jsonEncode({'fcmToken': fcmToken, 'deviceId': deviceId}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM Token removed successfully.');
      } else {
        debugPrint('Failed to remove FCM Token.');
      }
    }
  }

  Future<void> saveFCMToken(
    int user_id,
    String fcmToken,
    String deviceId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      debugPrint('User not logged in. Cannot save FCM token.');
      return;
    } else {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_URL']}/api/notification/${user_id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token}',
        },
        body: jsonEncode({'fcmToken': fcmToken, 'deviceId': deviceId}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM Token updated successfully.');
      } else {
        debugPrint('Failed to update FCM Token.');
      }
    }
  }
}
