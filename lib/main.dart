import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/app_routes.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/locator.dart';
import 'package:harmoniglow/mock_service/local_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupLocator();
  runApp(const HarmoniGlow());
}

class HarmoniGlow extends StatelessWidget {
  const HarmoniGlow({super.key});
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          // Provide BluetoothBloc
          BlocProvider<BluetoothBloc>(
            create: (context) => BluetoothBloc(),
          ),
          RepositoryProvider<StorageService>(
            create: (context) => StorageService(),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [observer],
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoute.getInitialRoute(),
          routes: AppRoute.getRoute(),
          onGenerateRoute: (RouteSettings routeSettings) =>
              AppRoute.generateRoute(routeSettings),
        ),
      );
}
