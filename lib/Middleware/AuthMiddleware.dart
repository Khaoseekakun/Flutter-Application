import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/AuthController.dart';

class AuthMiddleware extends GetMiddleware {
  final authController = Get.find<AuthController>();

  @override
  RouteSettings? redirect(String? route) {
    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: '/login');
    }else{
      if(route == '/login' || route == '/register'){
        return const RouteSettings(name: '/home');
      }
    }
    return null;
  }
}
