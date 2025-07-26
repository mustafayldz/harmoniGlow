import 'dart:async';
// unawaited fonksiyonu zaten dart:async içinde mevcut
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Notification callback'leri
  Function(RemoteMessage)? onMessageReceived;
  Function(RemoteMessage)? onMessageOpenedApp;
  Function(String)? onTokenRefresh;

  /// Firebase Messaging'i başlat
  Future<void> initialize() async {
    try {
      // İzin ve local notification işlemlerini paralel başlat
      await Future.wait([
        _requestPermission(),
        _initializeLocalNotifications(),
      ]);

      // iOS için APNS token'ı arka planda başlat
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        unawaited(_getAPNSToken());
      }

      // FCM token'ı arka planda başlat
      unawaited(_getToken());

      // Token yenileme dinleyicisi
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        onTokenRefresh?.call(token);
        developer.log('FCM Token refreshed: $token', name: 'FCM');
      });

      // Foreground mesaj dinleyicisi
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background'dan uygulama açılması dinleyicisi
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Uygulama kapalıyken gelen mesajları kontrol et
      unawaited(_checkInitialMessage());

      developer.log('Firebase Messaging initialized successfully', name: 'FCM');
    } catch (e) {
      developer.log(
        'Firebase Messaging initialization failed',
        name: 'FCM',
        error: e,
      );
    }
  }

  /// İzin iste
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted permission', name: 'FCM');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      developer.log('User granted provisional permission', name: 'FCM');
    } else {
      developer.log(
        'User declined or has not accepted permission',
        name: 'FCM',
      );
    }
  }

  /// Local notifications'ı başlat
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android için notification channel oluştur
    if (!kIsWeb) {
      const androidChannel = AndroidNotificationChannel(
        'drumly_channel',
        'Drumly Notifications',
        description: 'Drumly app notifications',
        importance: Importance.high,
        // Ses dosyası ayarını kaldırdık - sistem varsayılan sesini kullanacak
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// FCM token'ı al
  Future<void> _getToken() async {
    try {
      developer.log('FCM Token alınmaya çalışılıyor...', name: 'FCM');

      // iOS için APNS token'ın hazır olduğundan emin ol
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          developer.log(
            'APNS token henüz hazır değil, bekleniyor...',
            name: 'FCM',
          );
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      _fcmToken = await _firebaseMessaging.getToken();
      developer.log('FCM Token: $_fcmToken', name: 'FCM');
    } catch (e) {
      developer.log('Failed to get FCM token', name: 'FCM', error: e);
    }
  }

  /// Foreground mesajları işle
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log(
      'Foreground message received: ${message.messageId}',
      name: 'FCM',
    );

    // Local notification göster
    _showLocalNotification(message);

    // Callback çağır
    onMessageReceived?.call(message);
  }

  /// Background'dan uygulama açılması
  void _handleMessageOpenedApp(RemoteMessage message) {
    developer.log('Message clicked: ${message.messageId}', name: 'FCM');
    onMessageOpenedApp?.call(message);
  }

  /// Uygulama kapalıyken gelen mesajları kontrol et
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        'App opened from terminated state: ${initialMessage.messageId}',
        name: 'FCM',
      );
      onMessageOpenedApp?.call(initialMessage);
    }
  }

  /// Local notification göster
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'drumly_channel',
      'Drumly Notifications',
      channelDescription: 'Drumly app notifications',
      importance: Importance.high,
      priority: Priority.high,
      // Ses ayarını kaldırdık - sistem varsayılan sesini kullanacak
    );

    const iosDetails = DarwinNotificationDetails(
        // Ses ayarını kaldırdık - sistem varsayılan sesini kullanacak
        );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.messageId.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Notification'a tıklanma
  void _onNotificationTapped(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}', name: 'FCM');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final message = RemoteMessage(data: Map<String, String>.from(data));
        onMessageOpenedApp?.call(message);
      } catch (e) {
        developer.log(
          'Failed to parse notification payload',
          name: 'FCM',
          error: e,
        );
      }
    }
  }

  /// Topic'e abone ol
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'FCM');
    } catch (e) {
      developer.log(
        'Failed to subscribe to topic: $topic',
        name: 'FCM',
        error: e,
      );
    }
  }

  /// Topic'ten çık
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic', name: 'FCM');
    } catch (e) {
      developer.log(
        'Failed to unsubscribe from topic: $topic',
        name: 'FCM',
        error: e,
      );
    }
  }

  /// Bildirim badge'ini temizle
  Future<void> clearBadge() async {
    await _localNotifications.cancelAll();
  }

  /// FCM token'ı zorla yeniden al
  Future<String?> refreshToken() async {
    try {
      // iOS için önce APNS token'ı kontrol et
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _getAPNSToken();

        // APNS token'ın kullanılabilir olması için biraz bekle
        await Future.delayed(const Duration(seconds: 1));
      }

      await _firebaseMessaging.deleteToken();
      await Future.delayed(const Duration(milliseconds: 500));
      _fcmToken = await _firebaseMessaging.getToken();
      developer.log('FCM Token refreshed: $_fcmToken', name: 'FCM');
      return _fcmToken;
    } catch (e) {
      developer.log('Failed to refresh FCM token', name: 'FCM', error: e);
      return null;
    }
  }

  /// FCM token'ı manuel olarak al (public metod)
  Future<String?> getTokenManually() async {
    await _getToken();
    return _fcmToken;
  }

  /// iOS için APNS token'ı al
  Future<void> _getAPNSToken() async {
    try {
      // APNS token'ı al
      final apnsToken = await _firebaseMessaging.getAPNSToken();

      if (apnsToken != null) {
        developer.log('APNS Token: $apnsToken', name: 'FCM');
      } else {
        await Future.delayed(const Duration(seconds: 2));

        // Tekrar dene
        final retryApnsToken = await _firebaseMessaging.getAPNSToken();
        if (retryApnsToken != null) {
          developer.log(
            'APNS token (retry) alındı: ${retryApnsToken.substring(0, 20)}...',
            name: 'FCM',
          );
        } else {
          developer.log('APNS token hala null', name: 'FCM');
        }
      }
    } catch (e) {
      developer.log('APNS token alma hatası: $e', name: 'FCM');
      developer.log('Failed to get APNS token', name: 'FCM', error: e);
    }
  }
}

/// Background message handler (top-level function olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'Background message received: ${message.messageId}',
    name: 'FCM_BG',
  );
}
