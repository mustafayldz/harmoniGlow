import 'package:drumly/models/user_model.dart';
import 'package:drumly/services/firebase_notification_service.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/user_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  final UserService userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoginMode = true;
  bool isButtonLoading = false;

  void init() {
    nameController.addListener(_onFormChanged);
    emailController.addListener(_onFormChanged);
    passwordController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    notifyListeners();
  }

  void toggleMode(bool login) {
    isLoginMode = login;
    notifyListeners();
  }

  bool get isFormValid {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    final hasRequiredFields = email.isNotEmpty && password.isNotEmpty;
    final nameOk = isLoginMode || name.isNotEmpty;

    return hasRequiredFields && nameOk && isValidEmail(email);
  }

  Future<void> login(BuildContext context) async {
    isButtonLoading = true;
    notifyListeners();

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final UserCredential value = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (value.user != null) {
        final idToken = await value.user!.getIdToken();
        await StorageService.saveFirebaseToken(idToken!);

        // FCM token'ı al
        final fcmToken = FirebaseNotificationService().fcmToken;

        // Önce mevcut kullanıcıyı kontrol et
        final existingUser = await userService.getUser(context);

        UserModel? user;
        if (existingUser != null &&
            (existingUser.firebaseToken == null ||
                existingUser.firebaseToken!.isEmpty)) {
          // Mevcut kullanıcının Firebase token'ı eksik, güncelle
          debugPrint(
            '🔄 Updating missing Firebase token for existing user during login',
          );
          // createOrUpdateUser kullanarak name'i de koru
          user = await userService.createOrUpdateUser(
            context,
            firebaseToken: idToken,
            email: email,
            name: existingUser.name, // Mevcut name'i koru
            fcmToken: fcmToken,
          );
        } else {
          // Backend'e kullanıcı bilgilerini gönder/güncelle
          user = await userService.createOrUpdateUser(
            context,
            firebaseToken: idToken,
            email: email,
            name: value.user!.displayName, // Firebase'den display name'i al
            fcmToken: fcmToken,
          );
        }

        if (user != null) {
          debugPrint('✅ User login successful: ${user.email}');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/home');
        });
      }
    } catch (e) {
      Future.delayed(Duration.zero, () {
        showTopSnackBar(context, 'Sign in failed: $e');
      });
    } finally {
      isButtonLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(BuildContext context) async {
    isButtonLoading = true;
    notifyListeners();

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final rawName = nameController.text.trim();
      final name = rawName.isNotEmpty
          ? rawName[0].toUpperCase() + rawName.substring(1)
          : '';

      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // İsim varsa display name'i güncelle
        if (name.isNotEmpty) {
          await cred.user!.updateDisplayName(name);
          await Future.microtask(() => cred.user!.reload());
        }

        // Firebase token'ı kesinlikle al ve backend'e kullanıcı oluştur
        final idToken = await cred.user!.getIdToken();
        if (idToken != null) {
          await StorageService.saveFirebaseToken(idToken);

          // FCM token'ı al
          final fcmToken = FirebaseNotificationService().fcmToken;

          final user = await userService.createOrUpdateUser(
            context,
            firebaseToken: idToken,
            email: email,
            name: name.isNotEmpty ? name : null,
            fcmToken: fcmToken,
          );

          if (user != null) {
            debugPrint('✅ User registration successful: ${user.email}');
          } else {
            debugPrint('❌ Failed to create user in backend');
          }
        } else {
          debugPrint('❌ Failed to get Firebase ID token');
        }
      }
      toggleMode(true);
    } catch (e) {
      Future.delayed(Duration.zero, () {
        showTopSnackBar(context, 'Sign up failed: $e');
      });
    } finally {
      isButtonLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(BuildContext context) async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showTopSnackBar(
        context,
        'resetPasswordInstruction'.tr(),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      showTopSnackBar(context, 'resetPasswordSuccess'.tr());
    } catch (e) {
      showTopSnackBar(context, '${'resetPasswordFailure'.tr()}: $e');
    }
  }

  void disposeControllers() {
    nameController.removeListener(_onFormChanged);
    emailController.removeListener(_onFormChanged);
    passwordController.removeListener(_onFormChanged);
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}
