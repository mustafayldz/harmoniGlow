import 'package:flutter/material.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/game/data/repositories/local_storage_repository.dart';
import 'package:drumly/services/user_service.dart';
import 'package:drumly/models/user_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/shared/common_functions.dart';

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

  Future<void> deleteAccount(BuildContext context) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('deleteAccountConfirmTitle'.tr()),
        content: Text('deleteAccountConfirmMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('🗑️ Delete account process started');
      
      // 1. Delete from backend
      debugPrint('🌐 Step 1: Deleting from backend...');
      final success = await userService.deleteAccount(context);
      debugPrint('🌐 Backend deletion result: $success');

      if (success) {
        // 2. Delete Firebase Auth user (hata olsa bile devam et)
        debugPrint('🔥 Step 2: Deleting Firebase Auth user...');
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await user.delete();
            debugPrint('🔥 Firebase user deleted');
          } catch (firebaseError) {
            // requires-recent-login veya başka hata olsa bile
            // backend'den zaten silindi, devam et
            debugPrint('⚠️ Firebase Auth deletion warning: $firebaseError');
            debugPrint('ℹ️ Continuing with logout (backend already deleted)');
          }
        }

        // 3. Clear local storage
        debugPrint('💾 Step 3: Clearing local storage...');
        await FirebaseAuth.instance.signOut();
        await LocalStorageRepository.clearAll();
        await storageService.clearAll();
        debugPrint('💾 Local storage cleared');

        // 4. Show success message
        if (context.mounted) {
          debugPrint('✅ Account deletion completed successfully');
          showTopSnackBar(context, 'deleteAccountSuccess'.tr());

          // 5. Navigate to auth screen
          await Navigator.of(context)
              .pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      } else {
        debugPrint('❌ Backend deletion failed');
        if (context.mounted) {
          showTopSnackBar(context, 'deleteAccountError'.tr());
        }
      }
    } catch (e) {
      debugPrint('❌ Error deleting account: $e');
      if (context.mounted) {
        showTopSnackBar(context, 'deleteAccountError'.tr());
      }
    }
  }
}
