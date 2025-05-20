import 'package:drumly/app_routes.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/hive/models/note_model.dart';
import 'package:drumly/locator.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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
        child: const Drumly(),
      ),
    ),
  );

  // Arka planda başlat
  await Future.microtask(() async {
    await MobileAds.instance.initialize();
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);

    await Hive.openLazyBox(Constants.lockSongBox);
    await Hive.openLazyBox<BeatMakerModel>(Constants.beatRecordsBox);

    Hive.registerAdapter(BeatMakerModelAdapter());
    Hive.registerAdapter(NoteModelAdapter());
  });
}

class Drumly extends StatelessWidget {
  const Drumly({super.key});

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
