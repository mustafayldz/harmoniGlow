import 'package:flutter/material.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/game/data/repositories/local_storage_repository.dart';
import 'package:drumly/services/user_service.dart';
import 'package:drumly/models/user_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingViewModel extends ChangeNotifier {
  final StorageService storageService = StorageService();
  final UserService userService = UserService();

  late AppProvider appProvider;

  String version = '';
  String buildNumber = '';
  UserModel? userModel;
  bool isLoadingUser = false;

  void initialize(AppProvider provider) {
    appProvider = provider;
    _loadPackageInfo();
  }

  void _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    version = info.version;
    buildNumber = info.buildNumber;
    notifyListeners();
  }

  Future<void> refreshUserInfo(BuildContext context) async {
    isLoadingUser = true;
    notifyListeners();

    try {
      userModel = await userService.getUser(context);
    } catch (e) {
      debugPrint('❌ Error creating fallback player for $e');
    } finally {
      isLoadingUser = false;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    await appProvider.toggleTheme();
    notifyListeners();
  }

  void adjustCountdown(bool increase) {
    appProvider.setCountdownValue(increase);
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await LocalStorageRepository.clearAll();
    await storageService.clearAll();
    await Navigator.of(context)
        .pushNamedAndRemoveUntil('/auth', (route) => false);
  }
}
