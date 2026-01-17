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

  // 🔄 Initialization state
  String? _nextRoute;

  @override
  void initState() {
    super.initState();

    // 🎬 Animasyonu hemen başlat (lightweight)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Daha kısa
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();

    // 🚀 İlk frame renderdan sonra ağır işlemleri başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // 1️⃣ Hive'ı arka planda başlat
      await _initializeHive();

      // 2️⃣ Token kontrolü (paralel olarak)
      final token = await StorageService().getFirebaseToken();

      if (!mounted) return;

      // 3️⃣ Yönlendirme kararı
      if (token != null && token.isNotEmpty) {
        // Token varsa, validity check
        if (isJwtExpired(token)) {
          // Token expired - yenile
          unawaited(_refreshTokenInBackground());
        }
        
        // User initialization - arka planda başlat, beklemeden devam et
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        unawaited(
          userProvider.initializeUser(context).catchError((e) {
            debugPrint('⚠️ User init error: $e');
          }),
        );
        
        _nextRoute = '/home';
      } else {
        _nextRoute = '/auth';
      }

      // 4️⃣ Minimum animasyon süresi bekle
      await _waitForMinimumSplashTime();

      // 5️⃣ Navigate
      if (mounted && _nextRoute != null) {
        await Navigator.pushReplacementNamed(context, _nextRoute!);
      }
    } catch (e) {
      debugPrint('❌ Splash init error: $e');
      // Hata durumunda auth'a yönlendir
      if (mounted) {
        await Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }


  /// Hive başlatma - optimize edilmiş
  Future<void> _initializeHive() async {
    // Path'i al
    final appDocDir = await getApplicationDocumentsDirectory();
    
    // Hive'ı sadece bir kere başlat
    if (!Hive.isBoxOpen(Constants.lockSongBox)) {
      Hive.init(appDocDir.path);
      
      // Adapter'ları kaydet (sadece kayıtlı değilse)
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(BeatMakerModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(NoteModelAdapter());
      }
    }

    // Box'ları lazy olarak aç
    await Future.wait([
      Hive.openLazyBox(Constants.lockSongBox),
      Hive.openLazyBox<BeatMakerModel>(Constants.beatRecordsBox),
    ]);
  }

  /// Token yenileme - arka planda
  Future<void> _refreshTokenInBackground() async {
    try {
      final newToken = await getValidFirebaseToken();
      await StorageService.saveFirebaseToken(newToken);
    } catch (e) {
      debugPrint('⚠️ Token refresh error: $e');
    }
  }

  /// Minimum splash süresi - animasyonun tamamlanması için
  Future<void> _waitForMinimumSplashTime() async {
    // Animasyon tamamlanana kadar veya max 1.5 saniye bekle
    final animationComplete = _controller.isCompleted;
    if (!animationComplete) {
      await Future.any([
        _controller.forward().orCancel,
        Future.delayed(const Duration(milliseconds: 1500)),
      ]).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context); // Daha performanslı

    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🖼️ Logo - cache'lenmiş
              Image.asset(
                'assets/images/logo.png',
                width: size.width * 0.4,
                cacheWidth: (size.width * 0.4 * 2).toInt(), // 2x for retina
              ),
              const SizedBox(height: 24),
              // 📝 Text - const widget
              FadeTransition(
                opacity: _animation,
                child: const _BrandText(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand text - ayrı const widget
class _BrandText extends StatelessWidget {
  const _BrandText();

  @override
  Widget build(BuildContext context) => const Text.rich(
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
      );
}
