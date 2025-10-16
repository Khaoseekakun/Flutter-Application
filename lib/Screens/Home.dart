import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test1/Components/AppBar.dart';
import 'package:test1/Controllers/AuthController.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  @override
  Widget build(BuildContext context) {
    // 1. ADD the appBar property to the Scaffold
    return Scaffold(
      appBar: CustomAppBar(
        title: "Pos | Panel",
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Get.toNamed("/notifications");
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ... (Your existing GridView content)
            Container(
              margin: const EdgeInsets.all(18.0),
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 420,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    // Shop Card (Can be refactored into ShadCard for full Shadcn style)
                    GestureDetector(
                      onTap: () => Get.toNamed('/shop'),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 2,
                          color: Colors.lightBlue[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  size: 48,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 12),
                                Text('Shop', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),GestureDetector(
                      onTap: () => Get.toNamed('/select_product_action'),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 2,
                          color: Colors.yellow[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_shopping_cart,
                                  size: 48,
                                  color: const Color.fromARGB(255, 199, 182, 26),
                                ),
                                const SizedBox(height: 12),
                                Text('Product Manage', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Billing Card
                    GestureDetector(
                      onTap: () => Get.toNamed('/billing'),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 2,
                          color: Colors.pink[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Colors.pink,
                                ),
                                const SizedBox(height: 12),
                                Text('Billing', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Promotions Card
                    GestureDetector(
                      onTap: () => Get.toNamed('/promotions'),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 2,
                          color: Colors.green[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  size: 48,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Promotions',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Memberships Card
                    GestureDetector(
                      onTap: () => Get.toNamed('/memberships'),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 2,
                          color: Colors.purple[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.card_membership_rounded,
                                  size: 48,
                                  color: Colors.purple,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Memberships',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Settings Card
                    GestureDetector(
                      onTap: () => Get.toNamed('/settings'),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 2,
                          color: Colors.orange[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.settings,
                                  size: 48,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Settings',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Logout Card
                    GestureDetector(
                      onTap: () => AuthController().logout(),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 2,
                          color: Colors.red[100],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text('Logout', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Use a Container with gradient as the background
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(255, 238, 243, 255),
    );
  }
}
