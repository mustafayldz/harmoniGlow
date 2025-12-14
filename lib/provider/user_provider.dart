import 'dart:async';
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
          // Token kaydetmeyi arka planda yap
          unawaited(StorageService.saveFirebaseToken(idToken));

          // Önce mevcut kullanıcıyı kontrol et
          final existingUser = await _userService.getUser(context);

          if (existingUser != null) {
            // Kullanıcı mevcut
            debugPrint('👤 User found: ${existingUser.email}');
            
            setUser(existingUser);

            // FCM token güncellemesini arka planda yap
            if (existingUser.fcmToken == null || existingUser.fcmToken!.isEmpty) {
              unawaited(_updateFCMTokenInBackground(context));
            }
          } else {
            // Yeni kullanıcı - arka planda oluştur
            unawaited(_createUserInBackground(context, firebaseUser, idToken));
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

  /// FCM token güncellemesi - arka planda
  Future<void> _updateFCMTokenInBackground(BuildContext context) async {
    try {
      debugPrint('🔔 Updating FCM token in background...');
      
      var fcmToken = await FirebaseNotificationService().fcmToken;
      fcmToken ??= await FirebaseNotificationService().getTokenManually();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final updatedUser = await _userService.updateFCMToken(
          context,
          fcmToken: fcmToken,
        );

        if (updatedUser != null) {
          setUser(updatedUser);
          debugPrint('✅ FCM token updated in background');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Background FCM update error: $e');
    }
  }

  /// Kullanıcı oluşturma - arka planda
  Future<void> _createUserInBackground(
    BuildContext context,
    User firebaseUser,
    String idToken,
  ) async {
    try {
      // FCM token'ı al - ama bekleme
      String? fcmToken;
      try {
        fcmToken = await FirebaseNotificationService().fcmToken;
      } catch (_) {}

      final user = await _userService.createOrUpdateUser(
        context,
        firebaseToken: idToken,
        email: firebaseUser.email,
        name: firebaseUser.displayName,
        fcmToken: fcmToken,
      );

      if (user != null) {
        setUser(user);
        debugPrint('✅ User created in background: ${user.email}');
      }
    } catch (e) {
      debugPrint('⚠️ Background user creation error: $e');
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
  
  /// Safe notify - aynı frame'de birden fazla notify'ı önler
  void _safeNotifyListeners() {
    if (_isNotifying) return;
    _isNotifying = true;
    
    // Build sırasındaysa, sonraki frame'e ertele
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
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
