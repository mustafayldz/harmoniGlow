import 'package:drumly/mock_service/api_service.dart';
import 'package:drumly/mock_service/local_service.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<MockApiService>(() => MockApiService());

  // Register providers
  getIt.registerFactory<UserProvider>(() => UserProvider());
  getIt.registerFactory<AppProvider>(() => AppProvider());
}
