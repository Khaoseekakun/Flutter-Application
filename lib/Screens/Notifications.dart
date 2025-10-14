import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:test1/Components/AppBar.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:test1/Interfaces/interface.Notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool isLoading = true;
  List<NotificationModels> notifications = [];

  @override
  void initState() {
    super.initState();
    LoadNotification();
  }

  Future<void> LoadNotification() async {
    final response = await http.get(
      Uri.parse('http://45.154.27.155:5179/api/notification'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        notifications = data
            .map((item) => NotificationModels.fromJson(item))
            .toList();
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Pos | Notificaton", showBackButton: true),
      body: SafeArea(
        // ✅ Prevents bottom overflow safely
        bottom: false,
        child: Container(
          color: const Color.fromARGB(255, 242, 242, 242),
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? _buildLoading()
                    : _buildNotificationList(notifications),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildNotificationList(List<NotificationModels> notifications) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return ListTile(
          leading: Icon(
            notification.isRead
                ? Icons.mark_email_read
                : Icons.mark_email_unread,
            color: notification.isRead ? Colors.grey : Colors.blue,
          ),
          title: Text(notification.title),
          subtitle: Text(notification.message),
          trailing: Text(
            '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          onTap: () {
            // Handle notification tap
          },
        );
      },
    );
  }
}
