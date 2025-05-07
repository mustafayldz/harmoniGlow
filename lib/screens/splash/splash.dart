import 'dart:async';

import 'package:flutter/material.dart';
import 'package:drumly/mock_service/local_service.dart';
import 'package:drumly/models/device_model.dart';
import 'package:drumly/models/user_model.dart';
import 'package:drumly/provider/user_provider.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  SplashViewState createState() => SplashViewState();
}

class SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
    final userModel = UserModel(
      userId: '1',
      name: 'mustafa',
      email: 'mstf.yildiz92@gmail.com',
      createdAt: DateTime.now()
          .subtract(const Duration(hours: 24))
          .millisecondsSinceEpoch,
      lastLogin: DateTime.now()
          .subtract(const Duration(hours: 5))
          .millisecondsSinceEpoch,
      devices: [
        DeviceModel(
          deviceId: '1',
          model: 'Model A',
          serialNumber: '123456789',
          firmwareVersion: '1.0.0',
          hardwareVersion: '1.0.0',
          lastConnectedAt: DateTime.now()
              .subtract(const Duration(hours: 6))
              .millisecondsSinceEpoch,
          pairedAt: DateTime.now()
              .subtract(const Duration(hours: 5))
              .millisecondsSinceEpoch,
          isActive: 1,
        ),
      ],
    );

    UserProvider().setUser(userModel);
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 5));
    final token = await StorageService.getFirebaseToken();

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
