import 'package:drumly/screens/bluetooth/find_devices_view.dart';
import 'package:drumly/screens/home_view.dart';
import 'package:drumly/screens/auth/auth_view.dart';
import 'package:drumly/screens/splash/splash.dart';
import 'package:flutter/material.dart';

class AppRoute {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static getRoute() => <String, WidgetBuilder>{
        '/auth': (context) => const AuthView(),
        '/home': (context) => const HomeView(),
        '/splash': (context) => const SplashView(),
        '/findDevices': (context) => const FindDevicesView(),
      };

  static String getInitialRoute() => '/splash';

  static generateRoute(RouteSettings routeSettings) {
    if (routeSettings.name == '/home') {
      return MaterialPageRoute(builder: (context) => const HomeView());
    }
  }
}
