import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _passwordVisible = false;
  final TextEditingController _userPassworController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final confirmController = TextEditingController();
    final size = MediaQuery.of(context).size;

    void _onRegister() {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final pass = _userPassworController.text;
      final confirm = confirmController.text;

      if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
        Get.snackbar(
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          'Error',
          'Please fill all fields',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      if (pass != confirm) {
        Get.snackbar(
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          'Error',
          'Passwords do not match',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // perform registration logic here
      Get.toNamed('/home');
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: 25,
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
                  height: size.height * 0.75,
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
                            'Register',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Name
                        const Text(
                          'Full Name',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            hintText: 'Enter your full name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 14),

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
                            hintText: 'Create a password',
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
                        const SizedBox(height: 14),

                        // Confirm Password
                        const Text(
                          'Confirm Password',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: confirmController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            hintText: 'Re-enter your password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 12),

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
                            onPressed: _onRegister,
                            child: const Text(
                              'REGISTER',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Already have account
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              onPressed: () => Get.toNamed('/login'),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
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
