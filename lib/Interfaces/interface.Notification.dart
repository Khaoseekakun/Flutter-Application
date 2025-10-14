import 'package:json_annotation/json_annotation.dart';

part 'interface.Notification.g.dart';

@JsonSerializable()
class NotificationModels {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  NotificationModels({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  factory NotificationModels.fromJson(Map<String, dynamic> json) => _$NotificationModelsFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationModelsToJson(this);
}