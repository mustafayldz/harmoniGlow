import 'dart:convert';

import 'package:drumly/services/firebase_notification_service.dart';
import 'package:drumly/main.dart'; // navigatorKey için
import 'package:drumly/provider/notification_provider.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/screens/notifications/notification_view.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHandler {
  static final FirebaseNotificationService _notificationService =
      FirebaseNotificationService();

  static void initialize() {
    // Notification callback'lerini ayarla
    _notificationService.onMessageReceived = _handleForegroundMessage;
    _notificationService.onMessageOpenedApp = _handleMessageOpenedApp;
    _notificationService.onTokenRefresh = _handleTokenRefresh;
  }

  /// Foreground'da gelen mesajlar için
  static void _handleForegroundMessage(RemoteMessage message) {
    // Add notification to provider
    final context = navigatorKey.currentContext;
    if (context != null) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.addNotificationFromRemoteMessage(message);
    }
  }

  /// Notification'a tıklanma durumu
  static void _handleMessageOpenedApp(RemoteMessage message) {
    // Add notification to provider
    final context = navigatorKey.currentContext;
    if (context != null) {
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      notificationProvider.addNotificationFromRemoteMessage(message);

      // Navigate to notifications screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationView()),
      );
    }

    // Notification data'sına göre navigation yapın
    final data = message.data;
    if (data.isNotEmpty) {
      _navigateBasedOnData(data);
    }
  }

  /// FCM token yenileme
  static void _handleTokenRefresh(String token) {
    debugPrint('🔄 FCM Token refreshed: $token');

    // Token'ı sunucuya gönderin
    _sendTokenToServer(token);
  }

  /// Navigation işlemi
  static void _navigateBasedOnData(Map<String, dynamic> data) {
    final screen = data['screen'];
    final id = data['id'];

    switch (screen) {
      case 'song':
        // Şarkı detay sayfasına git
        debugPrint('Navigate to song with id: $id');
        break;
      case 'beat':
        // Beat maker sayfasına git
        debugPrint('Navigate to beat maker with id: $id');
        break;
      case 'settings':
        // Ayarlar sayfasına git
        debugPrint('Navigate to settings');
        break;
      default:
        // Ana sayfa
        debugPrint('Navigate to home');
        break;
    }
  }

  /// Token'ı sunucuya gönder
  static void _sendTokenToServer(String token) {
    debugPrint('🔔 Sending FCM token to server: $token');

    // Context'i al ve UserProvider'a gönder
    final context = navigatorKey.currentContext;
    if (context != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        userProvider.updateFCMToken(context, token);
      } else {
        debugPrint('❌ User not logged in, cannot update FCM token');
      }
    } else {
      debugPrint('❌ Context not available, cannot update FCM token');
    }
  }

  /// Topic'lere abone ol
  static Future<void> subscribeToDefaultTopics() async {
    await _notificationService.subscribeToTopic('general');
    await _notificationService.subscribeToTopic('updates');
    debugPrint('Subscribed to default topics');
  }

  /// Kullanıcı çıkış yaptığında topic'lerden çık
  static Future<void> unsubscribeFromTopics() async {
    await _notificationService.unsubscribeFromTopic('general');
    await _notificationService.unsubscribeFromTopic('updates');
    debugPrint('Unsubscribed from topics');
  }

  /// FCM token'ı al
  static String? get fcmToken => _notificationService.fcmToken;

  /// Debug için token'ı manuel olarak yazdır
  static Future<void> printCurrentToken() async {
    final token = _notificationService.fcmToken;

    if (token == null) {
      final newToken = await _notificationService.getTokenManually();
      debugPrint('🔄 Yeniden alınan token: $newToken');
    }
  }

  Future<void> saveNotificationInBackground(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Mevcut notification'ları yükle
      final notificationsString = prefs.getString('notifications');
      List<Map<String, dynamic>> notifications = [];

      if (notificationsString != null) {
        final List<dynamic> notificationsJson = jsonDecode(notificationsString);
        notifications = notificationsJson.cast<Map<String, dynamic>>();
      }

      // Yeni notification'ı oluştur
      final newNotification = {
        'id': message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'title': message.notification?.title ?? 'Drumly Notification',
        'body': message.notification?.body ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': message.data,
        'isRead': false,
      };

      // Duplicate check - aynı ID'li notification varsa ekleme
      final existingIndex =
          notifications.indexWhere((n) => n['id'] == newNotification['id']);
      if (existingIndex != -1) {
        debugPrint(
            '📱 Duplicate notification ignored: ${newNotification['id']}');
        return;
      }

      // Listenin başına ekle (en yeni notification en üstte)
      notifications.insert(0, newNotification);

      // Maximum 20 notification limit
      if (notifications.length > 20) {
        notifications = notifications.take(20).toList();
      }

      // SharedPreferences'a kaydet
      await prefs.setString('notifications', jsonEncode(notifications));

      debugPrint(
          '✅ Background notification saved successfully to SharedPreferences');
    } catch (e) {
      debugPrint('❌ Error saving background notification: $e');
    }
  }
}
