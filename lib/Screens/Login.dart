import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _passwordVisible = false;
  final TextEditingController _userPassworController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: (size.width - 120) / 2,
              right: (size.width - 120) / 2,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 140, 203, 255),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/pos-icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 150.0, end: 0.0),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, offsetY, child) {
                return Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Opacity(
                    opacity: 1.0 - (offsetY / 150.0),
                    child: child,
                  ),
                );
              },
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: size.height * 0.63,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40.0),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Email
                        const Text(
                          'Email',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.mail),
                            hintText: 'Enter your email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        const Text(
                          'Password',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _userPassworController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            hintText: 'Enter your password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Get.toNamed('/forgot_password'),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              // perform login
                              Get.toNamed('/home');
                            },
                            child: const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Register button (outline)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Get.toNamed('/register'),
                            child: const Text(
                              'REGISTER',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // More actions / social or extra info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.facebook,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.g_mobiledata,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
