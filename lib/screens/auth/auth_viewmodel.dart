import 'dart:io';

import 'package:drumly/models/user_model.dart';
import 'package:drumly/services/firebase_notification_service.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/age_gate_service.dart';
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

  int? selectedBirthYear;

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

  Future<void> toggleMode(bool login) async {
    isLoginMode = login;
    notifyListeners();
  }


  List<int> get birthYears {
    final currentYear = DateTime.now().year;
    const earliestYear = 1900;
    return List<int>.generate(
      currentYear - earliestYear + 1,
      (index) => currentYear - index,
    );
  }

  bool get isFormValid {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    final hasRequiredFields = email.isNotEmpty && password.isNotEmpty;
    final nameOk = isLoginMode || name.isNotEmpty;

    return hasRequiredFields && nameOk && isValidEmail(email);
  }

  Future<void> _persistBirthYearIfNeeded() async {
    if (selectedBirthYear == null) return;
    await AgeGateService.instance.setBirthYear(selectedBirthYear!);
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

        // FCM token'ı güvenli şekilde al
        debugPrint('🔔 FCM token alınıyor...');
        String? fcmToken;

        try {
          fcmToken = await FirebaseNotificationService().fcmToken;
          debugPrint(
            '✅ FCM token result: ${fcmToken?.isNotEmpty == true ? "${fcmToken!.substring(0, 20)}..." : "null"}',
          );
        } catch (e) {
          debugPrint('❌ FCM token alma hatası: $e');
          fcmToken = null;
        }

        // Önce mevcut kullanıcıyı kontrol et
        final existingUser = await userService.getUser(context);

        UserModel? user;
        if (existingUser != null &&
            (existingUser.firebaseToken == null ||
                existingUser.firebaseToken!.isEmpty)) {
          debugPrint(
            '🔄 Updating missing Firebase token for existing user during login',
          );

          user = await userService.createOrUpdateUser(
            context,
            firebaseToken: idToken,
            email: email,
            name: existingUser.name,
            fcmToken: fcmToken, // FCM token'ı gönder
          );
        } else {
          debugPrint('🆕 Creating/updating user with all tokens');

          user = await userService.createOrUpdateUser(
            context,
            firebaseToken: idToken,
            email: email,
            name: value.user!.displayName,
            fcmToken: fcmToken, // FCM token'ı gönder
          );
        }

        // FCM token ayrıca gönderilmemişse, özel method ile gönder
        if (user != null && fcmToken != null && fcmToken.isNotEmpty) {
          if (user.fcmToken == null || user.fcmToken != fcmToken) {
            debugPrint('🔔 FCM token eksik, ayrıca gönderiliyor...');
            final fcmResult = await userService.sendFCMTokenToServer(
              context,
              fcmToken: fcmToken,
            );
            debugPrint('🔔 FCM token separate send result: $fcmResult');
          } else {
            debugPrint('✅ FCM token already updated in user profile');
          }
        }

        if (user != null) {
          debugPrint('✅ User login successful: ${user.email}');
          debugPrint(
            '✅ User FCM token: ${user.fcmToken?.substring(0, 20) ?? "null"}...',
          );
        } else {
          debugPrint('❌ Failed to create user in backend');
        }

        final canContinue = await _captureBirthYearIfNeeded(context);
        if (!canContinue) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamed(context, '/home');
        });
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      
      // Kullanıcı dostu hata mesajı
      String errorMessage = 'auth.sign_in_failed'.tr();
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'network-request-failed':
            errorMessage = 'auth.network_error'.tr();
            break;
          case 'user-not-found':
            errorMessage = 'auth.user_not_found'.tr();
            break;
          case 'wrong-password':
            errorMessage = 'auth.wrong_password'.tr();
            break;
          case 'invalid-email':
            errorMessage = 'auth.invalid_email'.tr();
            break;
          case 'too-many-requests':
            errorMessage = 'auth.too_many_requests'.tr();
            break;
          default:
            errorMessage = e.message ?? 'auth.sign_in_failed'.tr();
        }
      } else if (e.toString().contains('network')) {
        errorMessage = 'auth.network_error'.tr();
      }
      
      Future.delayed(Duration.zero, () {
        showTopSnackBar(context, errorMessage);
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
        if (name.isNotEmpty) {
          await cred.user!.updateDisplayName(name);
          await Future.microtask(() => cred.user!.reload());
        }

        final idToken = await cred.user!.getIdToken();
        if (idToken != null) {
          await StorageService.saveFirebaseToken(idToken);

          // FCM token'ı al
          debugPrint('🔔 Registration: FCM token alınıyor...');
          String? fcmToken;
          try {
            fcmToken = await FirebaseNotificationService().fcmToken;
            debugPrint(
              '✅ Registration FCM token: ${fcmToken?.substring(0, 20) ?? "null"}...',
            );
          } catch (e) {
            debugPrint('❌ Registration FCM token error: $e');
          }

          final user = await userService.createOrUpdateUser(
            context,
            firebaseToken: idToken,
            email: email,
            name: name.isNotEmpty ? name : null,
            fcmToken: fcmToken, // FCM token'ı gönder
          );

          if (user != null) {
            debugPrint('✅ User registration successful: ${user.email}');
            debugPrint(
              '✅ Registered user FCM token: ${user.fcmToken?.substring(0, 20) ?? "null"}...',
            );
          } else {
            debugPrint('❌ Failed to create user in backend');
          }
        } else {
          debugPrint('❌ Failed to get Firebase ID token');
        }
      }
      final canContinue = await _captureBirthYearIfNeeded(context);
      if (!canContinue) return;
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

  Future<bool> _captureBirthYearIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final hasStored = await AgeGateService.instance.hasBirthYear();
    if (hasStored) return true;

    if (selectedBirthYear != null) {
      await _persistBirthYearIfNeeded();
      notifyListeners();
      return true;
    }

    int? tempYear;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('ageGateTitle'.tr()),
          content: DropdownButtonFormField<int>(
            initialValue: tempYear,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'ageGateYearLabel'.tr(),
              border: const OutlineInputBorder(),
            ),
            items: birthYears
                .map(
                  (year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => tempYear = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: tempYear == null
                  ? null
                  : () => Navigator.of(context).pop(true),
              child: Text('ok'.tr()),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && tempYear != null) {
      selectedBirthYear = tempYear;
      await _persistBirthYearIfNeeded();
      notifyListeners();
      return true;
    }

    showTopSnackBar(context, 'ageGateYearRequired'.tr());
    return false;
  }
}
