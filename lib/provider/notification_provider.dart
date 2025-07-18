import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
        id: message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Drumly Notification',
        body: message.notification?.body ?? '',
        timestamp: DateTime.now(),
        data: message.data,
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

class NotificationProvider with ChangeNotifier {
  static const int maxNotifications = 20; // Maximum 20 notifications
  final List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  NotificationProvider() {
    // Load saved notifications when provider is created
    loadNotifications();
  }

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnreadNotifications => _unreadCount > 0;
  int get notificationCount => _notifications.length;
  int get maxNotificationLimit => maxNotifications;

  void addNotification(NotificationModel notification) {
    // Add new notification at the beginning (latest first)
    _notifications.insert(0, notification);

    // Check if we exceeded the limit
    if (_notifications.length > maxNotifications) {
      // Remove the oldest notification (last in the list)
      final removedNotification = _notifications.removeLast();

      // Debug log when limit is reached
      debugPrint(
          '📢 Notification limit reached (${maxNotifications}). Removed oldest: "${removedNotification.title}"');

      // Adjust unread count if the removed notification was unread
      if (!removedNotification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
    }

    // Increment unread count for new notification
    if (!notification.isRead) {
      _unreadCount++;
    }

    debugPrint(
        '📢 Added notification. Current count: ${_notifications.length}/${maxNotifications}');

    notifyListeners();
    _saveNotifications();
  }

  void addNotificationFromRemoteMessage(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(message);
    addNotification(notification);
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      notifyListeners();
      _saveNotifications();
    }
  }

  void markAsUnread(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && _notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
      _unreadCount++;
      notifyListeners();
      _saveNotifications();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
    _saveNotifications();
  }

  void removeNotification(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      if (!_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
      _notifications.removeAt(index);
      notifyListeners();
      _saveNotifications();
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
    _saveNotifications();
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          _notifications.map((notification) => notification.toJson()).toList();
      await prefs.setString('notifications', jsonEncode(notificationsJson));
      print(
          'DEBUG: Saved ${_notifications.length} notifications to SharedPreferences');
    } catch (e) {
      print('ERROR: Failed to save notifications: $e');
    }
  }

  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsString = prefs.getString('notifications');

      if (notificationsString != null) {
        final List<dynamic> notificationsJson = jsonDecode(notificationsString);
        final loadedNotifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        // Clear existing notifications and add loaded ones
        _notifications.clear();

        // Ensure we don't exceed the limit after loading
        if (loadedNotifications.length > maxNotifications) {
          _notifications.addAll(loadedNotifications.take(maxNotifications));
          print(
              'DEBUG: Trimmed loaded notifications to $maxNotifications limit');
        } else {
          _notifications.addAll(loadedNotifications);
        }

        // Update unread count based on actual unread notifications
        _unreadCount =
            _notifications.where((notification) => !notification.isRead).length;

        print(
            'DEBUG: Loaded ${_notifications.length} notifications from SharedPreferences');
        notifyListeners();
      } else {
        print('DEBUG: No saved notifications found');
      }
    } catch (e) {
      print('ERROR: Failed to load notifications: $e');
      _notifications.clear();
      _unreadCount = 0;
    }
  }
}
