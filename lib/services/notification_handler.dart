import 'package:drumly/services/firebase_notification_service.dart';
import 'package:drumly/main.dart'; // navigatorKey için
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

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
    // Foreground'da güzel bir bildirim göster (debug print kaldırıldı)
    _showForegroundNotification(message);
  }

  /// Foreground notification UI göster
  static void _showForegroundNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ Context null, notification gösterilemedi');
      return;
    }

    // Directly use simple SnackBar - more reliable
    _showSimpleSnackBar(context, message);

    debugPrint('🔔 Foreground notification: ${message.notification?.title}');
  }

  /// Alternative: Custom dialog ile notification göster
  /// Kullanım: _showNotificationDialog(context, message);
  // ignore: unused_element
  static void _showNotificationDialog(
    BuildContext context,
    RemoteMessage message,
  ) {
    final title = message.notification?.title ?? 'Bildirim';
    final body = message.notification?.body ?? 'Yeni mesaj';

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: Colors.blue[600],
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('KAPAT'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Notification data'sına göre navigation yap
              if (message.data.isNotEmpty) {
                _navigateBasedOnData(message.data);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('AÇ'),
          ),
        ],
      ),
    );
  }

  /// Notification'a tıklanma durumu
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.notification?.title}');

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

  /// Test notification gönder (development için)
  static void sendTestNotification() {
    final token = _notificationService.fcmToken;
    if (token != null) {
      debugPrint('🔔 Test notification gönderiliyor: $token');
    } else {
      debugPrint('❌ FCM Token bulunamadı!');
    }
  }

  /// Fallback: Basit SnackBar ile notification göster
  static void _showSimpleSnackBar(BuildContext context, RemoteMessage message) {
    final title = message.notification?.title ?? 'Bildirim';
    final body = message.notification?.body ?? 'Yeni mesaj';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    body,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
