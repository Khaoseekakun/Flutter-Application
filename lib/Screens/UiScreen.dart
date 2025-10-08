import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:test1/Components/AppBar.dart';

class UiScreen extends StatefulWidget {
  const UiScreen({super.key});

  @override
  State<UiScreen> createState() => _UiScreenState();
}

class _UiScreenState extends State<UiScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Pos | Ui", showBackButton: true, 
      actions: [
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Get.toNamed('/home'),
        ),
      ],),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[ShadBadge(child: const Text('Primary'))],
        ),
      ),
      
    );
  }
}
