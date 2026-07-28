import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  // 🎯 Session flags
  bool _hasShownVersionCheckThisSession = false;
  bool _hasShownInitialAdThisSession = false;

  // 🔒 Debounce
  bool _isNotifying = false;

  // Getters
  UserModel? get userModel => _userModel;
  UserModel get user => _userModel!;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _userModel != null;

  // 🎯 Session flag getters
  bool get hasShownVersionCheckThisSession => _hasShownVersionCheckThisSession;
  bool get hasShownInitialAdThisSession => _hasShownInitialAdThisSession;

  // 🎯 Session flag setters
  void markVersionCheckAsShown() {
    if (!_hasShownVersionCheckThisSession) {
      _hasShownVersionCheckThisSession = true;
      _safeNotifyListeners();
    }
  }

  void markInitialAdAsShown() {
    if (!_hasShownInitialAdThisSession) {
      _hasShownInitialAdThisSession = true;
      _safeNotifyListeners();
    }
  }

  // 🔄 Reset session flags
  void resetSessionFlags() {
    _hasShownVersionCheckThisSession = false;
    _hasShownInitialAdThisSession = false;
    _safeNotifyListeners();
  }

  // Setter for user data
  void setUser(UserModel user) {
    if (_userModel != user) {
      _userModel = user;
      _safeNotifyListeners();
    }
  }

  void clearUser() {
    if (_userModel != null) {
      _userModel = null;
      _safeNotifyListeners();
    }
  }

  /// App başlangıcında token kontrolü ve kullanıcı güncelleme
  /// Optimize edilmiş - ana thread'i bloklamaz
  Future<void> initializeUser(BuildContext context) async {
    if (_isLoading) return; // Zaten yükleniyor

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // Firebase'den fresh token al - timeout ile
        final idToken = await firebaseUser.getIdToken(true).timeout(
              const Duration(seconds: 10),
              onTimeout: () => null,
            );

        if (idToken != null) {
          // API çağrısı başlamadan önce yeni token'ın kullanılabilir olduğundan
          // emin ol.
          await StorageService.saveFirebaseToken(idToken);

          // Önce mevcut kullanıcıyı kontrol et
          final existingUser = await _userService.getUser(context);

          if (existingUser != null) {
            // Kullanıcı mevcut
            debugPrint('👤 User found: ${existingUser.email}');

            setUser(existingUser);

            // İlk korumalı oturum açılışında cihaz kaydının backend tarafından
            // kabul edilmesini bekle.
            await registerNotificationDevice(context);
          } else {
            await _createUser(context, firebaseUser, idToken);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing user: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Mevcut installation'ı notification device endpointine kaydeder.
  /// Login ve app launch çağrıları bu sonucu await eder.
  Future<bool> registerNotificationDevice(
    BuildContext context, {
    String? token,
  }) async {
    if (_userModel == null) return false;

    try {
      final notificationService = FirebaseNotificationService();
      final fcmToken =
          token ?? await notificationService.getTokenForRegistration();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('FCM token acquired');
        debugPrint('POST /notification-devices');
        final updated = await _userService.updateFCMToken(
          context,
          fcmToken: fcmToken,
        );
        debugPrint('notification-device success: $updated');
        return updated;
      }
      debugPrint('notification-device registration skipped: no FCM token');
    } catch (e) {
      debugPrint('❌ Notification device registration error: $e');
    }
    return false;
  }

  Future<void> _createUser(
    BuildContext context,
    User firebaseUser,
    String idToken,
  ) async {
    try {
      final user = await _userService.createOrUpdateUser(
        context,
        firebaseToken: idToken,
        email: firebaseUser.email,
        name: firebaseUser.displayName,
      );

      if (user != null) {
        setUser(user);
        debugPrint('✅ User created: ${user.email}');
        await registerNotificationDevice(context);
      }
    } catch (e) {
      debugPrint('⚠️ User creation error: $e');
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
  Future<bool> updateFCMToken(
    BuildContext context,
    String newFCMToken,
  ) async {
    if (_userModel?.userId == null) return false;
    return registerNotificationDevice(context, token: newFCMToken);
  }

  /// Safe notify - aynı frame'de birden fazla notify'ı önler
  void _safeNotifyListeners() {
    if (_isNotifying) return;
    _isNotifying = true;

    // Build sırasındaysa, sonraki frame'e ertele
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isNotifying = false;
        notifyListeners();
      });
    } else {
      _isNotifying = false;
      notifyListeners();
    }
  }
}
