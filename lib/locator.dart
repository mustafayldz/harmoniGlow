import 'package:drumly/services/local_service.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/services/song_service.dart';
import 'package:drumly/services/user_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<UserService>(() => UserService());
  getIt.registerLazySingleton<SongService>(() => SongService());

  // Register providers
  getIt.registerFactory<UserProvider>(() => UserProvider());
  getIt.registerFactory<AppProvider>(() => AppProvider());
}
