import 'package:drumly/screens/bluetooth/find_devices_view.dart';
import 'package:drumly/screens/home/home_view.dart';
import 'package:drumly/screens/auth/auth_view.dart';
import 'package:drumly/screens/song_request/song_request_page.dart';
import 'package:drumly/screens/requested_songs/requested_songs_page.dart';
import 'package:drumly/screens/splash/splash.dart';
import 'package:drumly/screens/songs/songv2_view.dart';
import 'package:drumly/game/drum_hero_screen.dart';
import 'package:flutter/material.dart';

class AppRoute {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Map<String, WidgetBuilder> getRoute() => <String, WidgetBuilder>{
        '/auth': (context) => const AuthView(),
        '/home': (context) => const HomeView(),
        '/splash': (context) => const SplashView(),
        '/findDevices': (context) => const FindDevicesView(),
        '/song-request': (context) => const SongRequestPage(),
        '/requested-songs': (context) => const RequestedSongsPage(),
        '/songsv2': (context) => const SongV2View(),
        // 🎮 Drum Hero - performanceMode için:
        // - true: düşük cihazlarda glow efektleri kapalı
        // - false: normal cihazlarda tam efektler
        // debugMode: true yaparak bölge kalibrasyonu yapabilirsin
        '/drum-hero': (context) => const DrumHeroScreen(
          
        ),
      };

  static String getInitialRoute() => '/splash';

  static MaterialPageRoute generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case '/home':
        return MaterialPageRoute(builder: (context) => const HomeView());
      case '/auth':
        return MaterialPageRoute(builder: (context) => const AuthView());
      case '/splash':
        return MaterialPageRoute(builder: (context) => const SplashView());
      case '/findDevices':
        return MaterialPageRoute(builder: (context) => const FindDevicesView());
      case '/song-request':
        return MaterialPageRoute(builder: (context) => const SongRequestPage());
      case '/requested-songs':
        return MaterialPageRoute(
          builder: (context) => const RequestedSongsPage(),
        );
      case '/songsv2':
        return MaterialPageRoute(
          builder: (context) => const SongV2View(),
        );
      case '/drum-hero':
        return MaterialPageRoute(
          builder: (context) => const DrumHeroScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const SplashView(),
          settings: routeSettings,
        );
    }
  }
}
