import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test1/Components/AppBar.dart';
import 'package:test1/Controllers/AuthController.dart';

class SelectProductAction extends StatefulWidget {
  const SelectProductAction({super.key});

  @override
  State<SelectProductAction> createState() => _SelectProductActionState();
}

class _SelectProductActionState extends State<SelectProductAction> {
  @override
  Widget build(BuildContext context) {
    // 1. ADD the appBar property to the Scaffold
    return Scaffold(
      appBar: CustomAppBar(
        title: "Pos | Panel",
        showBackButton: true,
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
                  crossAxisCount: 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    // Shop Card (Can be refactored into ShadCard for full Shadcn style)
                    GestureDetector(
                      onTap: () => Get.toNamed('/add_product'),
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
                                  Icons.add,
                                  size: 48,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 12),
                                Text('Add Product', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed('/product_list'),
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
                                  Icons.list,
                                  size: 48,
                                  color: const Color.fromARGB(
                                    255,
                                    199,
                                    182,
                                    26,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Product List',
                                  style: TextStyle(fontSize: 16),
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
