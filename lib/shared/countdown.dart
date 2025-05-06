import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/provider/app_provider.dart';

class Countdown extends StatefulWidget {
  const Countdown({super.key});

  @override
  CountdownState createState() => CountdownState();
}

class CountdownState extends State<Countdown> {
  late int _counter;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _counter = context.read<AppProvider>().countdownValue;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_counter > 0) {
            _counter--;
          } else {
            _timer.cancel();
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(20),
            child: Text(
              '$_counter',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
}
