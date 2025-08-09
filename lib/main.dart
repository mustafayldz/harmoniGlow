import 'package:drumly/app_routes.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/locator.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/provider/notification_provider.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/firebase_notification_service.dart';
import 'package:drumly/services/notification_handler.dart';
import 'package:drumly/services/version_control_service.dart';
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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationHandler().saveNotificationInBackground(message);
}

void main() async {
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

  // Paralel başlatma - performans iyileştirmesi
  await Future.wait([
    Firebase.initializeApp(),
    MobileAds.instance.initialize(),
    EasyLocalization.ensureInitialized(),
  ]);

  // Servisleri başlat
  setupLocator();

  // Background message handler'ı kaydet
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Firebase Notification Service'i başlat (paralel değil, dependency var)
  await FirebaseNotificationService().initialize();

  // Notification handler'ı başlat
  NotificationHandler.initialize();

  // Default topic'lere abone ol
  await NotificationHandler.subscribeToDefaultTopics();

  // FCM Token'ı al ve debug için yazdır
  final notificationService = FirebaseNotificationService();

  // Token alma işlemi - performansı optimize et
  await notificationService.getTokenManually();

  // 📱 Version Control Service'i başlat (background'da)
  VersionControlService().initialize().catchError((e) {
    debugPrint('❌ [VERSION] Version Control başlatma hatası: $e');
  });

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
