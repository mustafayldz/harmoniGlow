import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:harmoniglow/app_routes.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/locator.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/provider/app_provider.dart';
import 'package:harmoniglow/provider/user_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupLocator();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BluetoothBloc>(
            create: (_) => BluetoothBloc(),
          ),
          RepositoryProvider<StorageService>(
            create: (_) => StorageService(),
          ),
        ],
        child: const HarmoniGlow(),
      ),
    ),
  );
}

class HarmoniGlow extends StatelessWidget {
  const HarmoniGlow({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        debugShowCheckedModeBanner: false,

        // Theme
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
        themeMode: context.watch<AppProvider>().isDarkMode
            ? ThemeMode.dark
            : ThemeMode.light,

        initialRoute: AppRoute.getInitialRoute(),
        routes: AppRoute.getRoute(),
        onGenerateRoute: (RouteSettings settings) =>
            AppRoute.generateRoute(settings),
      );
}
