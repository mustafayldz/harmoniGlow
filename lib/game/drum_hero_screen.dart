import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:drumly/game/game.dart';
import 'package:drumly/adMob/ad_service.dart';
import 'package:drumly/services/age_gate_service.dart';

/// ============================================================================
/// DRUM HERO SCREEN - Flame oyununu barındıran Flutter ekranı
/// ============================================================================
///
/// Bu widget, DrumGame'i Flutter widget tree'sine entegre eder ve
/// platform-spesifik özellikleri yönetir.
///
/// ## Sorumluluklar
///
/// 1. Android geri tuşu yönetimi (PopScope ile)
/// 2. Oyun lifecycle yönetimi (pause/resume)
/// 3. Reklam gösterim entegrasyonu
/// 4. Immersive mode (sistem UI gizleme)
///
/// ## Android Geri Tuşu
///
/// ```
/// Kullanıcı geri tuşuna basınca:
/// - Menüdeyse: Çıkış onayı göster
/// - Oyundaysa: Oyunu duraklat ve onay göster
/// - Game Over'daysa: Doğrudan çık
/// ```
///
/// ## Kullanım
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => DrumHeroScreen(
///       debugMode: false,
///       performanceMode: false,
///       showAdOnGameEnd: true,
///     ),
///   ),
/// );
/// ```
/// ============================================================================
class DrumHeroScreen extends StatefulWidget {
  /// Yeni bir DrumHeroScreen instance'ı oluşturur.
  ///
  /// [debugMode] true ise pad bölgeleri ve tap bilgisi gösterilir.
  /// [performanceMode] true ise glow efektleri devre dışı kalır.
  /// [showAdOnGameEnd] true ise oyun bittiğinde reklam gösterilir.
  const DrumHeroScreen({
    super.key,
    this.debugMode = false,
    this.performanceMode = false,
    this.showAdOnGameEnd = true,
  });

  /// Debug modu: Pad bölgelerini ve tap bilgisini gösterir.
  final bool debugMode;

  /// Performans modu: Glow efektlerini devre dışı bırakır.
  final bool performanceMode;

  /// Oyun bittiğinde interstitial reklam göster.
  final bool showAdOnGameEnd;

  @override
  State<DrumHeroScreen> createState() => _DrumHeroScreenState();
}

/// DrumHeroScreen'in state sınıfı.
///
/// WidgetsBindingObserver ile uygulama yaşam döngüsü olaylarını dinler.
/// Bu sayede uygulama arka plana alındığında oyun duraklatılır.
class _DrumHeroScreenState extends State<DrumHeroScreen>
    with WidgetsBindingObserver {
  /// Flame oyun instance'ı.
  late DrumGame _game;

  /// Reklam gösteriliyor mu?
  bool _isShowingAd = false;

  /// Uygulama arka plandayken oyun duraklatılmış mıydı?
  ///
  /// Bu flag, kullanıcı zaten oyunu duraklatmışken uygulamayı
  /// arka plana alırsa, geri döndüğünde otomatik olarak
  /// devam ettirmemek için kullanılır.
  bool _pausedByLifecycle = false;

  @override
  void initState() {
    super.initState();

    // Lifecycle observer'ı ekle
    WidgetsBinding.instance.addObserver(this);

    // Immersive mode: Sistem UI'ını gizle (fullscreen)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Ekran yönü: Sadece portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Oyun instance'ını oluştur
    _initGame();
  }

  /// Oyun instance'ını oluşturur.
  void _initGame() {
    final localizations = GameLocalizations.fromMap({
      'score': 'game.score'.tr(),
      'gameOver': 'game.gameOver'.tr(),
      'highestCombo': 'game.highestCombo'.tr(),
      'record': 'game.record'.tr(),
      'legendary': 'game.legendary'.tr(),
      'great': 'game.great'.tr(),
      'good': 'game.good'.tr(),
      'tryAgain': 'game.tryAgain'.tr(),
      'playAgain': 'game.playAgain'.tr(),
      'mainMenu': 'game.mainMenu'.tr(),
      'drumHero': 'game.drumHero'.tr(),
      'catchTheBeat': 'game.catchTheBeat'.tr(),
      'highest': 'game.highest'.tr(),
      'start': 'game.start'.tr(),
      'difficultyLevel': 'game.difficultyLevel'.tr(),
      'easy': 'game.easy'.tr(),
      'medium': 'game.medium'.tr(),
      'hard': 'game.hard'.tr(),
      'howToPlay': 'game.howToPlay'.tr(),
      'exitGame': 'game.exitGame'.tr(),
      'combo': 'game.combo'.tr(),
      'miss': 'game.miss'.tr(),
      'fever': 'game.fever'.tr(),
      'shieldReady': 'game.shieldReady'.tr(),
    });

    _game = DrumGame(
      localizations: localizations,
      onExit: _handleExit,
      performanceMode: widget.performanceMode,
      onGameEnd: _handleGameEnd,
    );
  }

  @override
  void dispose() {
    // Lifecycle observer'ı kaldır
    WidgetsBinding.instance.removeObserver(this);

    // Sistem UI'ını geri getir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Ekran yönü kısıtlamasını kaldır
    SystemChrome.setPreferredOrientations([]);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Sadece biz pause ediyorsak flag set et
        if (!_game.isPaused) {
          _pausedByLifecycle = true;
          _game.pauseGame();
        }
        break;

      case AppLifecycleState.resumed:
        // Sadece lifecycle yüzünden pause ettiysek resume et
        if (_pausedByLifecycle) {
          _game.resumeGame();
          _pausedByLifecycle = false;
        }
        break;

      default:
        break;
    }
  }

  /// Oyundan çıkış işler.
  void _handleExit() {
    Navigator.of(context).pop();
  }

  /// Oyun sonu işler (reklam gösterimi için).
  void _handleGameEnd() {
    if (!widget.showAdOnGameEnd || _isShowingAd) return;

    // Kısa bir gecikme ile reklam göster (UI'ın çizmesini bekle)
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      final canShow = await AgeGateService.instance.canShowFullScreenAds();
      if (!canShow) return;

      _isShowingAd = true;
      _game.pauseGame();

      try {
        await AdService.instance.showInterstitialAd();
      } catch (e) {
        debugPrint('Ad error: $e');
      } finally {
        if (mounted) {
          _isShowingAd = false;
          _game.resumeGame();
        }
      }
    });
  }

  /// Android geri tuşu için çıkış onayı dialogu gösterir.
  ///
  /// Returns: true ise çıkışa izin ver, false ise engelle.
  Future<bool> _showExitConfirmation() async {
    // Oyun duraklatılsın
    final wasPlaying = _game.gameState == GameState.playing;
    if (wasPlaying) {
      _game.pauseGame();
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '🎵 Oyundan Çık?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Oyundan çıkmak istediğinize emin misiniz?\nİlerlemeniz kaydedilmeyecek.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text(
              'DEVAM ET',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text(
              'ÇIKIŞ',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // Dialog kapatıldı
    if (shouldExit == true) {
      return true;
    }

    // Devam et seçildiyse oyunu resume et
    if (wasPlaying) {
      _game.resumeGame();
    }

    return false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
        // Varsayılan pop davranışını engelle
        canPop: false,

        // Geri tuşuna basıldığında çalışır
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          // Eğer zaten pop edildiyse (canPop: true durumunda) bir şey yapma
          if (didPop) return;

          // Game Over durumunda doğrudan çık
          if (_game.gameState == GameState.gameOver) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            return;
          }

          // Diğer durumlarda onay iste
          final shouldExit = await _showExitConfirmation();

          if (shouldExit && context.mounted) {
            Navigator.of(context).pop();
          }
        },

        // Flame oyun widget'ı
        child: Scaffold(
          body: SafeArea(
            child: GameWidget(
              game: _game,
              overlayBuilderMap: {
                DrumGame.pauseOverlayId: (context, game) {
                  final g = game as DrumGame;
                  return PauseOverlay(
                    currentScore: g.currentScore,
                    currentCombo: g.maxCombo,
                    currentAccuracy: g.accuracy,
                    onResume: g.resumeFromPause,
                    onRestart: g.restartFromPause,
                    onHome: g.goToMenuFromPause,
                  );
                },
                DrumGame.gameOverOverlayId: (context, game) {
                  final g = game as DrumGame;
                  return GameOverOverlay(
                    score: g.currentScore,
                    accuracy: g.accuracy,
                    maxCombo: g.maxCombo,
                    totalHits: g.perfectHits + g.goodHits + g.missCount,
                    perfectHits: g.perfectHits,
                    goodHits: g.goodHits,
                    missCount: g.missCount,
                    onRetry: g.restartFromGameOver,
                    onHome: g.goToMenuFromGameOver,
                  );
                },
              },
              loadingBuilder: (_) => _buildLoadingIndicator(),
              errorBuilder: (context, error) => _buildErrorWidget(error),
              backgroundBuilder: (context) => Container(
                color: const Color(0xFF0A0A15),
              ),
            ),
          ),
        ),
      );

  /// Yükleme göstergesi widget'ı.
  Widget _buildLoadingIndicator() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF4ECDC4),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );

  /// Hata widget'ı.
  Widget _buildErrorWidget(Object error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF6B6B),
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'Bir hata oluştu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
}
