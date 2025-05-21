import 'package:flutter/material.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/user_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:drumly/provider/app_provider.dart';

class SettingViewModel extends ChangeNotifier {
  final StorageService storageService = StorageService();
  final UserService userService = UserService();

  late AppProvider appProvider;

  String version = '';
  String buildNumber = '';

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

  Future<void> toggleTheme() async {
    await appProvider.toggleTheme();
    notifyListeners();
  }

  void adjustCountdown(bool increase) {
    appProvider.setCountdownValue(increase);
    notifyListeners();
  }

  void setDrumStyle(bool isClassic) {
    appProvider.setIsClassic(isClassic);
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await storageService.clearSavedDeviceId();
    await storageService.clearFirebaseToken();
    await Navigator.of(context)
        .pushNamedAndRemoveUntil('/auth', (route) => false);
  }
}
