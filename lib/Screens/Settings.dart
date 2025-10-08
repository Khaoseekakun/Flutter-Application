import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/get.dart';
import 'package:test1/Components/AppBar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Pos | Settings",
        showBackButton: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
                    GestureDetector(
                      onTap: () => Get.toNamed('/home'),
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Card(
                          elevation: 2,
                          color: Colors.lightBlue[50],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home,
                                  size: 48,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 12),
                                Text('Home'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ]
        )
      )
    );
  }
}