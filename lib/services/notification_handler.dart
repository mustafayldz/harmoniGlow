import 'package:drumly/services/firebase_notification_service.dart';
import 'package:drumly/main.dart'; // navigatorKey için
import 'package:drumly/provider/notification_provider.dart';
import 'package:drumly/screens/notifications/notification_view.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    // API call yapın
    debugPrint('Sending token to server: $token');

    // Örnek implementation:
    // final userService = GetIt.instance<UserService>();
    // userService.updateFCMToken(token);
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
}
