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
import 'dart:async';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔥 Singleton providers - her seferinde yeniden oluşturulmaz
late final UserProvider _userProvider;
late final AppProvider _appProvider;
late final NotificationProvider _notificationProvider;
late final BluetoothBloc _bluetoothBloc;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  await NotificationHandler().saveNotificationInBackground(message);
}

void main() async {
  // 🚀 ADIM 1: Minimum başlatma - sadece Flutter engine
  WidgetsFlutterBinding.ensureInitialized();

  // 🎨 ADIM 2: UI ayarları (senkron, çok hafif)
  _configureSystemUI();

  // 🔥 ADIM 3: Firebase'i başlat (zorunlu, diğer servislerin bağımlılığı)
  await Firebase.initializeApp();

  // 📱 ADIM 4: Background handler kaydı (Firebase'den hemen sonra)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 🌍 ADIM 5: Sadece EasyLocalization (UI için kritik)
  // MobileAds'ı arka plana taşıyoruz - UI'ı bloklamasın
  await EasyLocalization.ensureInitialized();

  // 📦 ADIM 6: Singleton servisleri hazırla
  setupLocator();
  _initializeProviders();

  // 🚀 ADIM 7: UI'ı HEMEN başlat
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

  // 🔔 ADIM 8: Ağır işlemleri UI başladıktan SONRA arka planda yap
  _initializeBackgroundServicesAsync();
}

/// System UI yapılandırması (senkron, hafif)
void _configureSystemUI() {
  // Modern edge-to-edge approach - avoid deprecated statusBarColor
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Don't set statusBarColor - deprecated in Android 15
      // Let system handle it with edge-to-edge
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      // Don't set systemNavigationBarColor - deprecated in Android 15
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Immersive mode - async ama bloklamaz
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
}

/// Provider'ları bir kere oluştur (singleton pattern)
void _initializeProviders() {
  _userProvider = UserProvider();
  _appProvider = AppProvider();
  _notificationProvider = NotificationProvider();
  _bluetoothBloc = BluetoothBloc();
}

/// Arka plan servisleri - UI'ı bloklamaz
void _initializeBackgroundServicesAsync() {
  // İlk frame renderdan sonra başlat
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _runBackgroundTasks();
  });
}

/// Arka plan görevleri
Future<void> _runBackgroundTasks() async {
  try {
    // 1. MobileAds - HEMEN başlat, reklam hazır olsun
    try {
      final initStatus = await MobileAds.instance.initialize();
      debugPrint(
        '✅ MobileAds initialized: ${initStatus.adapterStatuses}',
      );
    } catch (e) {
      debugPrint('❌ MobileAds init error: $e');
    }

    // 2. Firebase Notification - 1 saniye sonra
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        // Callback'ler initial message ve ilk token alınmadan önce bağlı olmalı.
        NotificationHandler.initialize();
        await FirebaseNotificationService().initialize();

        // Topic subscription - arka planda
        unawaited(
          NotificationHandler.subscribeToDefaultTopics().catchError((e) {
            debugPrint('⚠️ Topic subscription error: $e');
            return null;
          }),
        );

        debugPrint('✅ Notification services initialized');
      } catch (e) {
        debugPrint('⚠️ Notification init error: $e');
      }
    });

    // 3. FCM Token - 3 saniye sonra (Firebase Installations Service hazır olsun)
    Future.delayed(const Duration(seconds: 3), () {
      unawaited(
        FirebaseNotificationService().getTokenManually().catchError((e) {
          debugPrint('⚠️ FCM Token error: $e');
          return null;
        }),
      );
    });

    // 4. Version Control - 5 saniye sonra (en düşük öncelik)
    Future.delayed(const Duration(seconds: 5), () {
      unawaited(
        VersionControlService().initialize().catchError((e) {
          debugPrint('⚠️ Version control error: $e');
        }),
      );
    });
  } catch (e) {
    debugPrint('❌ Background tasks error: $e');
  }
}

class DrumlyApp extends StatelessWidget {
  const DrumlyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          // Singleton provider'ları kullan - her build'de yeniden oluşturma
          ChangeNotifierProvider.value(value: _userProvider),
          ChangeNotifierProvider.value(value: _appProvider),
          ChangeNotifierProvider.value(value: _notificationProvider),
          RepositoryProvider(create: (_) => StorageService()),
          BlocProvider.value(value: _bluetoothBloc),
        ],
        child: const Drumly(),
      );
}

class Drumly extends StatelessWidget {
  const Drumly({super.key});

  // 🎨 Tema cache - her seferinde yeniden oluşturma
  static final _lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
  );

  static final _darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
  );

  // 🔍 Analytics observer cache
  static final _analyticsObserver = FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
  );

  @override
  Widget build(BuildContext context) =>
      // Selector ile sadece isDarkMode değiştiğinde rebuild
      Selector<AppProvider, bool>(
        selector: (_, provider) => provider.isDarkMode,
        builder: (context, isDarkMode, child) => MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          navigatorObservers: [_analyticsObserver],
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRoute.getInitialRoute(),
          routes: AppRoute.getRoute(),
        ),
      );
}
