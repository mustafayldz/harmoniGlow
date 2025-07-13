import 'package:drumly/app_routes.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/locator.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/firebase_notification_service.dart';
import 'package:drumly/services/notification_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background message handler - top level function olmalı
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase'i başlat (background'da gerekli)
  await Firebase.initializeApp();

  debugPrint('🔔 Background message received: ${message.messageId}');
  debugPrint('🔔 Background message title: ${message.notification?.title}');
  debugPrint('🔔 Background message body: ${message.notification?.body}');

  // Background'da özel işlemler yapabilirsiniz
  // Örneğin: local storage'a kaydetme, API call, vs.
}

void main() async {
  // İlk debug çıktısı
  print('🚀🚀🚀 DRUMLY UYGULAMASI BAŞLATIYOR 🚀🚀🚀');
  debugPrint('🚀🚀🚀 DRUMLY UYGULAMASI BAŞLATIYOR 🚀🚀🚀');

  WidgetsFlutterBinding.ensureInitialized();
  print('✅ WidgetsFlutterBinding başlatıldı');

  // Firebase'i başlat
  print('🚀 Firebase başlatılıyor...');
  await Firebase.initializeApp();
  print('✅ Firebase başlatıldı');

  // Background message handler'ı kaydet
  print('🚀 Background message handler kaydediliyor...');
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print('✅ Background message handler kaydedildi');

  // Firebase Notification Service'i başlat
  print('🚀 Firebase Notification Service başlatılıyor...');
  await FirebaseNotificationService().initialize();
  print('✅ Firebase Notification Service başlatıldı');

  // Notification handler'ı başlat
  print('🚀 Notification Handler başlatılıyor...');
  NotificationHandler.initialize();
  print('✅ Notification Handler başlatıldı');

  // Default topic'lere abone ol
  print('🚀 Default topic\'lere abone oluyor...');
  await NotificationHandler.subscribeToDefaultTopics();
  print('✅ Default topic\'lere abone olundu');

  // FCM Token'ı debug için yazdır
  print('🔍 FCM Token kontrolü başlıyor...');
  final notificationService = FirebaseNotificationService();

  // İlk kontrol
  var token = notificationService.fcmToken;
  print('🔔 Main\'de FCM Token (ilk): $token');

  // Eğer token null ise, daha agresif deneme
  if (token == null) {
    print('⚠️  Token null, 2 saniye bekleniyor...');
    await Future.delayed(const Duration(seconds: 2));

    token = notificationService.fcmToken;
    print('🔄 2 saniye sonra FCM Token: $token');

    if (token == null) {
      print('⚠️  Hala null, manuel olarak alınmaya çalışılıyor...');
      token = await notificationService.getTokenManually();
      print('🔄 Manuel alma sonrası FCM Token: $token');

      // Hala null ise refresh dene
      if (token == null) {
        print('⚠️  Hala null, refresh deneniyor...');
        token = await notificationService.refreshToken();
        print('🔄 Refresh sonrası FCM Token: $token');

        // Son deneme - 3 saniye daha bekle
        if (token == null) {
          print('⚠️  Son deneme: 3 saniye daha bekleniyor...');
          await Future.delayed(const Duration(seconds: 3));
          token = notificationService.fcmToken;
          print('🔄 Son deneme FCM Token: $token');
        }
      }
    }
  }

  if (token != null) {
    print('🎉🎉🎉 BAŞARILI! FCM Token: $token');
    print('📋 Bu token\'ı Firebase Console\'da test için kullanın!');
    print('🔗 Token uzunluğu: ${token.length} karakter');

    // Test helper'ı çağır
    NotificationHandler.sendTestNotification();
  } else {
    print('❌❌❌ FCM Token alınamadı!');
    print('🔧 Sorun giderme: Firebase konfigürasyonunu kontrol edin');
  }

  // Diğer servisleri başlat
  setupLocator();
  await MobileAds.instance.initialize();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
        Locale('ru'),
        Locale('es'),
        Locale('fr'),
      ],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      child: const DrumlyApp(),
    ),
  );
}

class DrumlyApp extends StatelessWidget {
  const DrumlyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AppProvider()),
          RepositoryProvider(create: (_) => StorageService()),
          BlocProvider(create: (_) => BluetoothBloc()),
        ],
        child: const Drumly(),
      );
}

class Drumly extends StatelessWidget {
  const Drumly({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoute.getInitialRoute(),
      routes: AppRoute.getRoute(),
    );
  }
}
