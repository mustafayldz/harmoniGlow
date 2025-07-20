import 'package:flutter/material.dart';
import 'package:drumly/models/user_model.dart';
import 'package:drumly/services/user_service.dart';
import 'package:drumly/services/local_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();

  // User data
  UserModel? _userModel;
  bool _isLoading = false;

  // Getters
  UserModel? get userModel => _userModel;
  UserModel get user => _userModel!;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userModel != null;

  // Setter for user data
  void setUser(UserModel user) {
    _userModel = user;
    notifyListeners();
  }

  void clearUser() {
    _userModel = null;
    notifyListeners();
  }

  /// App başlangıcında token kontrolü ve kullanıcı güncelleme
  Future<void> initializeUser(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // Firebase'den fresh token al
        final idToken = await firebaseUser.getIdToken(true);

        if (idToken != null) {
          await StorageService.saveFirebaseToken(idToken);

          // Backend'e kullanıcı bilgilerini gönder/güncelle
          final user = await _userService.createOrUpdateUser(
            context,
            firebaseToken: idToken,
            email: firebaseUser.email,
            name: firebaseUser.displayName,
          );

          if (user != null) {
            setUser(user);
            debugPrint('✅ User initialized: ${user.email}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Token'ı manuel olarak güncelle
  Future<void> updateFirebaseToken(
    BuildContext context,
    String newToken,
  ) async {
    if (_userModel?.userId != null) {
      try {
        final updatedUser = await _userService.updateFirebaseToken(
          context,
          userId: _userModel!.userId!,
          firebaseToken: newToken,
        );

        if (updatedUser != null) {
          setUser(updatedUser);
          debugPrint('✅ Token updated for user: ${updatedUser.email}');
        }
      } catch (e) {
        debugPrint('❌ Error updating token: $e');
      }
    }
  }
}
