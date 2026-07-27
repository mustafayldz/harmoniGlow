import 'dart:async';
import 'dart:convert';

import 'package:drumly/models/notification_model.dart';
import 'package:drumly/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  NotificationProvider() {
    // Load saved notifications when provider is created
    loadNotifications();
  }
  static const int maxNotifications = 20; // Maximum 20 notifications
  final List<NotificationModel> _notifications = [];
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isSyncing = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnreadNotifications => _unreadCount > 0;
  int get notificationCount => _notifications.length;
  int get maxNotificationLimit => maxNotifications;
  bool get isSyncing => _isSyncing;

  Future<void> syncNotifications(BuildContext context) async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      final page = await _notificationService.getNotifications(context);
      if (page == null) return;
      _notifications
        ..clear()
        ..addAll(page.notifications);
      _unreadCount = page.unreadCount;
      await _saveNotifications();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void addNotification(NotificationModel notification) {
    final existingIndex =
        _notifications.indexWhere((item) => item.id == notification.id);
    if (existingIndex != -1) {
      // Aynı push daha sonra notification tap veya API sync ile tekrar
      // geldiğinde unread sayısını iki kez artırma.
      final existing = _notifications.removeAt(existingIndex);
      _notifications.insert(
        0,
        notification.copyWith(isRead: existing.isRead),
      );
      notifyListeners();
      unawaited(_saveNotifications());
      return;
    }

    // Add new notification at the beginning (latest first)
    _notifications.insert(0, notification);

    // Check if we exceeded the limit
    if (_notifications.length > maxNotifications) {
      // Remove the oldest notification (last in the list)
      final removedNotification = _notifications.removeLast();

      // Debug log when limit is reached
      debugPrint(
        '📢 Notification limit reached ($maxNotifications). Removed oldest: "${removedNotification.title}"',
      );

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
      '📢 Added notification. Current count: ${_notifications.length}/$maxNotifications',
    );

    notifyListeners();
    unawaited(_saveNotifications());
  }

  void addNotificationFromRemoteMessage(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(message);
    addNotification(notification);
  }

  void markAsRead(BuildContext context, String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      notifyListeners();
      _saveNotifications();
      unawaited(_notificationService.markAsRead(context, notificationId));
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

  void markAllAsRead(BuildContext context) {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
    _saveNotifications();
    unawaited(_notificationService.markAllAsRead(context));
  }

  void removeNotification(BuildContext context, String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      if (!_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
      _notifications.removeAt(index);
      notifyListeners();
      _saveNotifications();
      unawaited(
        _notificationService.deleteNotification(context, notificationId),
      );
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
    } catch (e) {
      debugPrint('ERROR: Failed to save notifications.');
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
        } else {
          _notifications.addAll(loadedNotifications);
        }

        // Update unread count based on actual unread notifications
        _unreadCount =
            _notifications.where((notification) => !notification.isRead).length;

        notifyListeners();
      } else {
        debugPrint('DEBUG: No saved notifications found');
      }
    } catch (e) {
      _notifications.clear();
      _unreadCount = 0;
    }
  }
}
