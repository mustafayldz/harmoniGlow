import 'package:flutter/material.dart';
import 'package:harmoniglow/screens/bluetooth/find_devices.dart';
import 'package:harmoniglow/screens/home_page.dart';
import 'package:harmoniglow/screens/login/login_view.dart';
import 'package:harmoniglow/screens/shuffle/shuffle_mode.dart';
import 'package:harmoniglow/screens/splash/splash.dart';

class AppRoute {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static getRoute() => <String, WidgetBuilder>{
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomePage(),
        '/shuffle': (context) => const ShuffleMode(),
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
