import 'package:drumly/screens/bluetooth/find_devices.dart';
import 'package:drumly/screens/home_page.dart';
import 'package:drumly/screens/login/login_view.dart';
import 'package:drumly/screens/splash/splash.dart';
import 'package:flutter/material.dart';

class AppRoute {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static getRoute() => <String, WidgetBuilder>{
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomePage(),
        '/splash': (context) => const SplashView(),
        '/findDevices': (context) => const FindDevicesScreen(),
      };

  static String getInitialRoute() => '/splash';

  static generateRoute(RouteSettings routeSettings) {
    if (routeSettings.name == '/home') {
      return MaterialPageRoute(builder: (context) => const HomePage());
    }
  }
}
