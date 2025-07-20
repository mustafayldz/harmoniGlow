import 'package:drumly/app_routes.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/locator.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/provider/notification_provider.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/firebase_notification_service.dart';
import 'package:drumly/services/notification_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  debugPrint('🚀🚀🚀 DRUMLY UYGULAMASI BAŞLATIYOR 🚀🚀🚀');

  WidgetsFlutterBinding.ensureInitialized();

  // Status bar'ı gizle (tüm uygulama boyunca)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Status bar'ı tamamen gizle
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Firebase'i başlat
  await Firebase.initializeApp();

  // Background message handler'ı kaydet
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Firebase Notification Service'i başlat
  await FirebaseNotificationService().initialize();

  // Notification handler'ı başlat
  NotificationHandler.initialize();

  // Default topic'lere abone ol
  await NotificationHandler.subscribeToDefaultTopics();

  // FCM Token'ı debug için yazdır
  final notificationService = FirebaseNotificationService();

  // İlk kontrol
  var token = notificationService.fcmToken;

  debugPrint('🔔 ----------------FCM Token: $token');

  // Eğer token null ise, daha agresif deneme
  if (token == null) {
    await Future.delayed(const Duration(seconds: 2));

    token = notificationService.fcmToken;

    if (token == null) {
      token = await notificationService.getTokenManually();

      // Hala null ise refresh dene
      if (token == null) {
        token = await notificationService.refreshToken();

        // Son deneme - 3 saniye daha bekle
        if (token == null) {
          await Future.delayed(const Duration(seconds: 3));
          token = notificationService.fcmToken;
        }
      }
    }
  }

  // if (token != null) {
  //   debugPrint('🔧 Firebase token alındı');
  // } else {
  //   debugPrint('🔧 Sorun giderme: Firebase konfigürasyonunu kontrol edin');
  // }

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
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
