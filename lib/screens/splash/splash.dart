import 'dart:async';

import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/services/user_service.dart';
import 'package:flutter/material.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  SplashViewState createState() => SplashViewState();
}

class SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final StorageService storageService = StorageService();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Define animation
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Start animation
    _controller.forward();

    // fetch user data
    _fetchUserData();

    // Navigate to the next screen after animation
    _navigateToNextScreen();
  }

  Future<void> _fetchUserData() async {
    try {
      final userModel = await UserService().getUser(context);
      if (userModel != null) {
        UserProvider().setUser(userModel);
        return;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 5));

    final token = await storageService.getFirebaseToken();

    if (token != null && token.isNotEmpty) {
      await Navigator.pushReplacementNamed(context, '/home');
    } else {
      await Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FadeTransition(
            opacity: _animation,
            child: const Text(
              'Welcome to Drumly',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
}
