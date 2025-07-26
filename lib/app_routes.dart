import 'package:drumly/screens/bluetooth/find_devices_view.dart';
import 'package:drumly/screens/home/home_view.dart';
import 'package:drumly/screens/auth/auth_view.dart';
import 'package:drumly/screens/song_request/song_request_page.dart';
import 'package:drumly/screens/requested_songs/requested_songs_page.dart';
import 'package:drumly/screens/splash/splash.dart';
import 'package:flutter/material.dart';

class AppRoute {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static getRoute() => <String, WidgetBuilder>{
        '/auth': (context) => const AuthView(),
        '/home': (context) => const HomeView(),
        '/splash': (context) => const SplashView(),
        '/findDevices': (context) => const FindDevicesView(),
        '/song-request': (context) => const SongRequestPage(),
        '/requested-songs': (context) => const RequestedSongsPage(),
      };

  static String getInitialRoute() => '/splash';

  static generateRoute(RouteSettings routeSettings) {
    if (routeSettings.name == '/home') {
      return MaterialPageRoute(builder: (context) => const HomeView());
    }
  }
}
