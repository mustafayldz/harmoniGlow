import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/user_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> toggleMode(bool login) async {
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

        final user = await userService.createOrUpdateUser(
          context,
          firebaseToken: idToken,
          email: email,
          name: value.user!.displayName,
        );

        if (user != null) {
          debugPrint('✅ User login successful: ${user.email}');
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.setUser(user);
          await userProvider.registerNotificationDevice(context);
        } else {
          debugPrint('❌ Failed to create user in backend');
        }

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

          final user = await userService.createOrUpdateUser(
            context,
            firebaseToken: idToken,
            email: email,
            name: name.isNotEmpty ? name : null,
          );

          if (user != null) {
            debugPrint('✅ User registration successful: ${user.email}');
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            userProvider.setUser(user);
            await userProvider.registerNotificationDevice(context);
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
