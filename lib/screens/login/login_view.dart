import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drumly/mock_service/local_service.dart';
import 'package:drumly/screens/bluetooth/find_devices.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  LoginViewState createState() => LoginViewState();
}

class LoginViewState extends State<LoginView> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoginMode = true;

  Future<void> login() async {
    try {
      final UserCredential value = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (value.user != null) {
        final idToken = await value.user!.getIdToken();
        await StorageService.saveFirebaseToken(idToken!);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FindDevicesScreen(),
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Sign in successful!',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Sign in failed: $e',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onError))),
      );
    }
  }

  Future<void> register() async {
    try {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sign up successful!',
          ),
        ),
      );
      setState(() => isLoginMode = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign up failed: $e',
          ),
        ),
      );
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter your email to reset password',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Password reset email sent',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onError))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
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
                  // Toggle Sign In / Sign Up
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
                          onPressed: () => setState(() => isLoginMode = false),
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
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
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
    );
  }
}
