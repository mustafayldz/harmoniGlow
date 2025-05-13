import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/user_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  LoginViewState createState() => LoginViewState();
}

class LoginViewState extends State<LoginView> {
  final UserService userService = UserService();
  final AppProvider appProvider = AppProvider();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoginMode = true;

  Future<void> login() async {
    try {
      appProvider.setLoading(true);
      final UserCredential value = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (value.user != null) {
        appProvider.setLoading(false);
        final idToken = await value.user!.getIdToken();
        await StorageService.saveFirebaseToken(idToken!);
        await userService.getUser(context);
        await Navigator.pushNamed(context, '/home');
      }
      showClassicSnackBar(
        context,
        'Sign in successful!',
      );
    } catch (e) {
      showClassicSnackBar(
        context,
        'Sign in failed: $e',
      );

      appProvider.setLoading(false);
    }
  }

  Future<void> register() async {
    try {
      appProvider.setLoading(true);
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final rawName = nameController.text.trim();
      final name = rawName.isNotEmpty
          ? rawName[0].toUpperCase() + rawName.substring(1)
          : '';
      if (name.isNotEmpty) {
        await cred.user!.updateDisplayName(name);
        await cred.user!.reload();
      }
      appProvider.setLoading(false);
      showClassicSnackBar(
        context,
        'Sign up successful!',
      );

      setState(() => isLoginMode = true);
    } catch (e) {
      showClassicSnackBar(
        context,
        'Sign up failed: $e',
      );
    }
    appProvider.setLoading(false);
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showClassicSnackBar(
        context,
        'Please enter your email to reset password',
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      showClassicSnackBar(
        context,
        'Password reset email sent',
      );
    } catch (e) {
      showClassicSnackBar(
        context,
        'Failed to send password reset email: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: appProvider.loading,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              color: theme.cardColor,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => isLoginMode = true),
                            style: TextButton.styleFrom(
                              backgroundColor: isLoginMode
                                  ? (isDark ? Colors.grey[700] : Colors.white)
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: isLoginMode
                                    ? theme.colorScheme.onTertiaryFixedVariant
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => isLoginMode = false),
                            style: TextButton.styleFrom(
                              backgroundColor: !isLoginMode
                                  ? (isDark ? Colors.grey[700] : Colors.white)
                                  : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: !isLoginMode
                                    ? theme.colorScheme.onTertiaryFixedVariant
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (!isLoginMode)
                      TextField(
                        controller: nameController,
                        style:
                            TextStyle(color: theme.textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          filled: true,
                          fillColor:
                              isDark ? Colors.grey[800] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    if (!isLoginMode) const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoginMode ? login : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? theme.colorScheme.primary : Colors.white,
                          foregroundColor: isDark
                              ? theme.colorScheme.onPrimary
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isLoginMode ? 'Sign In' : 'Sign Up'),
                      ),
                    ),
                    if (isLoginMode) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: resetPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
