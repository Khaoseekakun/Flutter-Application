import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:test1/Controllers/AuthController.dart';
import 'package:test1/Middleware/AuthMiddleware.dart';
import 'package:test1/Screens/Notifications.dart';
import 'package:test1/Utils/FCMService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Screens (Minimal Placeholders)
import 'Screens/Login.dart';
import 'Screens/ForgotPassword.dart';
import 'Screens/Register.dart';
import 'Screens/Home.dart';
import 'Screens/Shop.dart';
import 'Screens/Settings.dart';
import 'Screens/UiScreen.dart';
import 'Screens/Payment.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message: ${message.messageId}");
}

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp();

  Get.put(AuthController());
  await Get.find<AuthController>().checkLoginStatus();
  Get.put(FCMService());
  Get.find<FCMService>().initializeFCM();

  runApp(const Application());
}

class Application extends StatefulWidget {
  const Application({super.key});
  @override
  State<Application> createState() => _Application();
}

class _Application extends State<Application> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      appBuilder: (context) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/home',

          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 400),

          getPages: [
            // ---------------- BASIC BUILT-IN TRANSITIONS ----------------
            GetPage(
              name: '/login',
              page: () => const LoginScreen(),
              transition: Transition.fade,
            ),
            GetPage(
              name: '/forgot_password',
              page: () => const ForgotPasswordScreen(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/notifications',
              page: () => const NotificationScreen(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/register',
              page: () => const RegisterScreen(),
              transition: Transition.leftToRight,
            ),
            GetPage(
              name: '/home',
              page: () => const HomeScreen(),
              transition: Transition.downToUp,
              middlewares: [AuthMiddleware()],
            ),
            GetPage(
              name: '/shop',
              page: () => const ShopScreen(),
              transition: Transition.zoom,
              middlewares: [AuthMiddleware()],
            ),
            GetPage(
              name: '/settings',
              page: () => const SettingsScreen(),
              transition: Transition.cupertino,
              middlewares: [AuthMiddleware()],
            ),
            GetPage(
              name: '/ui',
              page: () => const UiScreen(),
              transition: Transition.size,
              middlewares: [AuthMiddleware()],
            ),
            GetPage(
              name: '/payment',
              page: () => const PaymentScreen(),
              customTransition: FadeScaleTransition(),
              middlewares: [AuthMiddleware()],
            ),
          ],

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
