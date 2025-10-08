import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:logging/logging.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// Screens
import 'Screens/Login.dart';
import 'Screens/ForgotPassword.dart';
import 'Screens/Register.dart';
import 'Screens/Home.dart';
import 'Screens/Shop.dart';
import 'Screens/Settings.dart';
import 'Screens/UiScreen.dart';
import 'Screens/Payment.dart';

final Logger _logger = Logger('main');

Future<void> clearSharedPreferences() async {
  await DefaultCacheManager().emptyCache();

  _logger.info('SharedPreferences cleared.');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await clearSharedPreferences();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      appBuilder: (context) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/home',

          // 🌈 Global default transition (applied to all routes)
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 400),

          getPages: [
            // ---------------- BASIC BUILT-IN TRANSITIONS ----------------
            GetPage(
              name: '/login',
              page: () => const LoginScreen(),
              transition: Transition.fade, // simple fade
            ),
            GetPage(
              name: '/forgot_password',
              page: () => const ForgotPasswordScreen(),
              transition: Transition.rightToLeft, // slide right → left
            ),
            GetPage(
              name: '/register',
              page: () => const RegisterScreen(),
              transition: Transition.leftToRight, // slide left → right
            ),
            GetPage(
              name: '/home',
              page: () => const HomeScreen(),
              transition: Transition.downToUp, // slide bottom → up
            ),
            GetPage(
              name: '/shop',
              page: () => const ShopScreen(),
              transition: Transition.zoom, // zoom in/out
            ),
            GetPage(
              name: '/settings',
              page: () => const SettingsScreen(),
              transition: Transition.cupertino, // iOS-style push
            ),
            GetPage(
              name: '/ui',
              page: () => const UiScreen(),
              transition: Transition.size, // grows/shrinks
            ),
            GetPage(
              name: '/payment',
              page: () => const PaymentScreen(),
              customTransition: FadeScaleTransition(), // custom combo animation
            ),
          ],

          // 👇 Wrap with ShadToaster
          builder: (context, child) => ShadToaster(child: child!),
        );
      },
    );
  }
}

class FadeScaleTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    );
  }
}
