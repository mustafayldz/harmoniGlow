import 'package:flutter/material.dart';
import 'package:drumly/models/user_model.dart';
import 'package:drumly/services/user_service.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/firebase_notification_service.dart';
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

          // Önce mevcut kullanıcıyı kontrol et
          final existingUser = await _userService.getUser(context);

          if (existingUser != null) {
            // Kullanıcı mevcut, FCM token'ı kontrol et ve güncelle
            debugPrint('👤 User found: ${existingUser.email}');
            debugPrint(
              '🔍 Checking FCM token... Current: ${existingUser.fcmToken ?? "null"}',
            );

            // FCM token'ı kontrol et - null veya boşsa güncelle
            if (existingUser.fcmToken == null ||
                existingUser.fcmToken!.isEmpty) {
              debugPrint(
                '🔔 FCM token is missing, attempting to get and update...',
              );

              // FCM token'ı al
              var fcmToken = await FirebaseNotificationService().fcmToken;

              // Eğer hala null ise manuel olarak almaya çalış
              if (fcmToken == null) {
                debugPrint('🔄 FCM token null, trying to get manually...');
                try {
                  fcmToken =
                      await FirebaseNotificationService().getTokenManually();
                } catch (e) {
                  debugPrint('❌ Failed to get FCM token manually: $e');
                }
              }

              if (fcmToken != null && fcmToken.isNotEmpty) {
                debugPrint(
                  '🔔 Updating missing FCM token for existing user: ${existingUser.email}',
                );
                debugPrint(
                  '🔔 FCM Token to send: ${fcmToken.substring(0, 20)}...',
                );

                final updatedUser = await _userService.updateFCMToken(
                  context,
                  fcmToken: fcmToken,
                );

                if (updatedUser != null) {
                  setUser(updatedUser);
                  debugPrint(
                    '✅ FCM token updated for existing user: ${updatedUser.email}',
                  );
                } else {
                  // FCM token güncellenemedi ama mevcut kullanıcıyı yükle
                  setUser(existingUser);
                  debugPrint(
                    'ℹ️ User loaded (FCM token update failed): ${existingUser.email}',
                  );
                }
              } else {
                // FCM token alınamadı, kullanıcıyı olduğu gibi yükle
                setUser(existingUser);
                debugPrint(
                  '⚠️ FCM token could not be obtained, user loaded without update',
                );
              }
            } else {
              // FCM token zaten var, kullanıcıyı yükle
              setUser(existingUser);
              debugPrint(
                '✅ User loaded with existing tokens: ${existingUser.email}',
              );
            }
          } else {
            // Backend'e kullanıcı bilgilerini gönder/güncelle (yeni kullanıcı veya token mevcut)
            // FCM token'ı al
            final fcmToken = await FirebaseNotificationService().fcmToken;

            final user = await _userService.createOrUpdateUser(
              context,
              firebaseToken: idToken,
              email: firebaseUser.email,
              name: firebaseUser.displayName,
              fcmToken: fcmToken,
            );

            if (user != null) {
              setUser(user);
              debugPrint('✅ User initialized: ${user.email}');
            }
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
          userId: _userModel!.userId,
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

  /// FCM Token'ı manuel olarak güncelle
  Future<void> updateFCMToken(
    BuildContext context,
    String newFCMToken,
  ) async {
    if (_userModel?.userId != null) {
      try {
        final updatedUser = await _userService.updateFCMToken(
          context,
          fcmToken: newFCMToken,
        );

        if (updatedUser != null) {
          setUser(updatedUser);
          debugPrint('✅ FCM Token updated for user: ${updatedUser.email}');
        }
      } catch (e) {
        debugPrint('❌ Error updating FCM token: $e');
      }
    }
  }
}
