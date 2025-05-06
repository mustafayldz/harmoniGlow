import 'package:get_it/get_it.dart';
import 'package:harmoniglow/mock_service/api_service.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/provider/app_provider.dart';
import 'package:harmoniglow/provider/user_provider.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<MockApiService>(() => MockApiService());

  // Register providers
  getIt.registerFactory<UserProvider>(() => UserProvider());
  getIt.registerFactory<AppProvider>(() => AppProvider());
}
