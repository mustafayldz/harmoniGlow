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
  final List<NotificationModel> _notifications = [];
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isSyncing = false;
  String? _syncError;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnreadNotifications => _unreadCount > 0;
  int get notificationCount => _notifications.length;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;

  Future<void> syncNotifications(BuildContext context) async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncError = null;
    notifyListeners();
    try {
      const pageSize = 100;
      var currentPage = 1;
      var unreadCount = 0;
      final apiNotifications = <NotificationModel>[];

      while (true) {
        final result = await _notificationService.getNotifications(
          context,
          page: currentPage,
          limit: pageSize,
        );
        if (result == null) {
          _syncError = 'notifications_load_failed';
          return;
        }
        if (currentPage == 1) unreadCount = result.unreadCount;
        apiNotifications.addAll(result.notifications);
        if (currentPage >= result.totalPages || result.notifications.isEmpty) {
          break;
        }
        currentPage++;
      }

      _notifications
        ..clear()
        ..addAll(apiNotifications);
      _unreadCount = unreadCount;
      await _saveNotifications();
    } catch (error) {
      _syncError = 'notifications_load_failed';
      debugPrint('Notification sync failed: $error');
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

    // Increment unread count for new notification
    if (!notification.isRead) {
      _unreadCount++;
    }

    debugPrint(
      '📢 Added notification. Current count: ${_notifications.length}',
    );

    notifyListeners();
    unawaited(_saveNotifications());
  }

  void addNotificationFromRemoteMessage(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(message);
    addNotification(notification);
  }

  Future<bool> markAsRead(
    BuildContext context,
    String notificationId,
  ) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return true;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    notifyListeners();
    await _saveNotifications();

    final success =
        await _notificationService.markAsRead(context, notificationId);
    if (success) return true;

    final currentIndex =
        _notifications.indexWhere((item) => item.id == notificationId);
    if (currentIndex != -1 && _notifications[currentIndex].isRead) {
      _notifications[currentIndex] =
          _notifications[currentIndex].copyWith(isRead: false);
      _unreadCount++;
      notifyListeners();
      await _saveNotifications();
    }
    return false;
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

  Future<bool> markAllAsRead(BuildContext context) async {
    final unreadIds = _notifications
        .where((notification) => !notification.isRead)
        .map((notification) => notification.id)
        .toSet();
    if (unreadIds.isEmpty) return true;

    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
    await _saveNotifications();

    final success = await _notificationService.markAllAsRead(context);
    if (success) return true;

    for (var index = 0; index < _notifications.length; index++) {
      if (unreadIds.contains(_notifications[index].id)) {
        _notifications[index] = _notifications[index].copyWith(isRead: false);
      }
    }
    _unreadCount =
        _notifications.where((notification) => !notification.isRead).length;
    notifyListeners();
    await _saveNotifications();
    return false;
  }

  Future<bool> removeNotification(
    BuildContext context,
    String notificationId,
  ) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return true;

    final removed = _notifications.removeAt(index);
    if (!removed.isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    }
    notifyListeners();
    await _saveNotifications();

    final success =
        await _notificationService.deleteNotification(context, notificationId);
    if (success) return true;

    final restoredIndex =
        index > _notifications.length ? _notifications.length : index;
    _notifications.insert(restoredIndex, removed);
    if (!removed.isRead) _unreadCount++;
    notifyListeners();
    await _saveNotifications();
    return false;
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

        _notifications.addAll(loadedNotifications);

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
