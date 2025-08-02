import 'dart:async';
import 'package:drumly/constants.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/hive/models/note_model.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final StorageService storageService = StorageService();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _controller.forward();

    _initializeApp(); // Hive başlatma + yönlendirme
  }

  Future<void> _initializeApp() async {
    // 1. Hive setup - paralel çalışacak
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
    Hive.registerAdapter(BeatMakerModelAdapter());
    Hive.registerAdapter(NoteModelAdapter());

    // 2. Paralel işlemler
    await Future.wait([
      Hive.openLazyBox(Constants.lockSongBox),
      Hive.openLazyBox<BeatMakerModel>(Constants.beatRecordsBox),
    ]);

    // 3. Hafif bir gecikme animasyon için (azaltıldı)
    await Future.delayed(const Duration(milliseconds: 200));

    // 4. Firebase token kontrolü
    final token = await storageService.getFirebaseToken();

    if (!mounted) return;

    // 5. Token kontrolü ve yönlendirme
    if (token != null) {
      if (isJwtExpired(token)) {
        final newToken = await getValidFirebaseToken();
        await StorageService.saveFirebaseToken(newToken);
      }

      // 6. User initialization - paralel değil, backend dependency
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initializeUser(context);

      await Navigator.pushReplacementNamed(context, '/home');
    } else {
      await Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png', // LOGO YOLUNU DOĞRU AYARLA
                width: size.width * 0.4,
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _animation,
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Drum',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'ly',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
