import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.data,
    this.isRead = false,
  });

  factory NotificationModel.fromRemoteMessage(RemoteMessage message) =>
      NotificationModel(
        id: message.data['notification_id'] ??
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ??
            message.data['_title'] ??
            message.data['title'] ??
            'Drumly Notification',
        body: message.notification?.body ??
            message.data['_body'] ??
            message.data['body'] ??
            '',
        timestamp: DateTime.now(),
        data: message.data,
      );

  factory NotificationModel.fromApi(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Drumly Notification',
        body: json['body'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        data: {
          if (json['type'] != null) 'type': json['type'],
          if (json['action'] != null) 'action': json['action'],
          if (json['entity_type'] != null) 'entity_type': json['entity_type'],
          if (json['entity_id'] != null) 'entity_id': json['entity_id'],
        },
        isRead: json['is_read'] as bool? ?? false,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        data: Map<String, dynamic>.from(json['data'] ?? {}),
        isRead: json['isRead'] ?? false,
      );

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isRead;

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        timestamp: timestamp ?? this.timestamp,
        data: data ?? this.data,
        isRead: isRead ?? this.isRead,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'data': data,
        'isRead': isRead,
      };
}
