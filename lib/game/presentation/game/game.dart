import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'package:drumly/game/core/constants/game_constants.dart';
import 'package:drumly/game/core/enums/game_enums.dart';
import 'package:drumly/game/core/localizations/game_localizations.dart';
import 'package:drumly/game/data/repositories/local_storage_repository.dart';
import 'package:drumly/game/domain/controllers/game_controller.dart';
import 'package:drumly/game/domain/controllers/input_controller.dart';
import 'package:drumly/game/domain/controllers/score_controller.dart';
import 'package:drumly/game/domain/controllers/timing_controller.dart';
import 'package:drumly/game/domain/entities/hit_result.dart';
import 'package:drumly/game/domain/entities/hit_windows.dart';
import 'package:drumly/game/domain/entities/pad_spec.dart';
import 'package:drumly/game/domain/entities/scheduled_note.dart';
import 'package:drumly/game/domain/services/beat_generator_service.dart';
import 'package:drumly/game/domain/services/drum_audio_service.dart';
import 'package:drumly/game/presentation/components/menu_button_component.dart';
import 'package:drumly/game/presentation/components/note_component.dart';
import 'package:drumly/game/presentation/components/pause_button_component.dart';
import 'package:drumly/game/presentation/components/circle_lane_component.dart';
import 'package:drumly/game/presentation/components/hit_feedback_ring.dart';
/// ============================================================================
/// DRUM GAME - Ana oyun sınıfı
/// ============================================================================
///
/// Bu sınıf, Flame oyun motorunu kullanarak drum rhythm oyununu yönetir.
/// State machine pattern ile oyun akışını kontrol eder.
///
/// ## Oyun Akışı
///
/// ```
/// [Menu] ---> [Playing] ---> [GameOver]
///   ^             |              |
///   |             v              |
///   +-------- onExit <-----------+
/// ```
///
/// ## Temel Sorumluluklar
///
/// 1. Oyun durumu yönetimi (menu, playing, gameOver)
/// 2. Nota spawn ve güncelleme döngüsü
/// 3. Kullanıcı input'u işleme (tap detection)
/// 4. Skor ve combo hesaplama
/// 5. UI rendering (menü, HUD, game over)
/// ============================================================================
class DrumGame extends FlameGame with TapCallbacks {

  /// Yeni bir DrumGame instance'ı oluşturur.
  ///
  /// [onExit] Oyundan çıkıldığında çağrılacak callback.
  /// [localizations] Oyun metinleri için yerelleştirme sınıfı.
  /// [performanceMode] true ise glow efektleri devre dışı kalır.
  /// [onGameEnd] Oyun bittiğinde çağrılacak callback (reklam için).
  DrumGame({
    required this.localizations,
    this.onExit,
    this.performanceMode = false,
    this.onGameEnd,
  });
  /// Pause overlay ID.
  static const String pauseOverlayId = 'pause_overlay';
  
  /// Game over overlay ID.
  static const String gameOverOverlayId = 'game_over_overlay';

  // ===========================================================================
  // CALLBACK'LER ve AYARLAR
  // ===========================================================================

  /// Oyundan çıkış callback'i (Navigator.pop için).
  final VoidCallback? onExit;

  /// Oyun sonu callback'i (reklam gösterimi için).
  final VoidCallback? onGameEnd;

  /// Oyun metinleri için yerelleştirme sınıfı.
  final GameLocalizations localizations;

  /// Performans modu: Glow efektlerini devre dışı bırakır.
  final bool performanceMode;

  // ===========================================================================
  // CONTROLLERS (FAZ 0 - Yeni Mimari)
  // ===========================================================================

  /// Ana oyun kontrolcüsü.
  GameController? _gameController;

  /// Input kontrolcüsü.
  InputController? _inputController;

  /// Skor kontrolcüsü.
  ScoreController? _scoreController;

  /// Timing kontrolcüsü.
  TimingController? _timingController;

  // ===========================================================================
  // OYUN DURUMU
  // ===========================================================================

  /// Oyun duraklatıldı mı?
  bool _isPaused = false;

  /// Mevcut oyun durumu (menu, playing, gameOver).
  GameState _gameState = GameState.menu;

  /// Seçili zorluk seviyesi.
  Difficulty _selectedDifficulty = Difficulty.easy;

  // ===========================================================================
  // SKOR SİSTEMİ
  // ===========================================================================

  /// Mevcut oyun skoru.
  int _score = 0;

  /// Mevcut combo sayısı.
  int _combo = 0;

  /// Bu oyundaki en yüksek combo.
  int _maxCombo = 0;

  /// Kaydedilmiş high score.
  int _highScore = 0;
  
  /// Perfect hit sayısı (overlay için).
  int _perfectHits = 0;
  
  /// Good hit sayısı (overlay için).
  int _goodHits = 0;
  
  /// Miss sayısı (overlay için).
  int _missCount = 0;

  // ===========================================================================
  // OYUN ZAMANLAMA
  // ===========================================================================

  /// Mevcut oyun zamanı (saniye).
  double _gameTime = 0;

  /// Notaların düşme hızı (piksel/saniye).
  late double _noteSpeed;

  /// Timing judgement pencereleri.
  late HitWindows _hitWindows;

  // ===========================================================================
  // NOTA YÖNETİMİ
  // ===========================================================================

  /// Spawn bekleyen notalar listesi (zamana göre sıralı).
  List<ScheduledNote> _scheduledNotes = [];

  /// Lane bazlı nota kuyrukları - O(1) erişim için.
  ///
  /// Her lane için ayrı liste tutulur. Hit kontrolünde sadece
  /// ilgili lane'in ilk notasına bakılır.
  final List<List<NoteComponent>> _notesByLane =
      List.generate(GameConstants.laneCount, (_) => []);

  // ===========================================================================
  // BONUS SİSTEMİ
  // ===========================================================================

  /// Fever modu kalan süresi (saniye). 0 ise aktif değil.
  double _feverTimer = 0;

  /// Shield aktif mi? (1 = aktif, 0 = değil)
  int _shield = 0;

  // ===========================================================================
  // UI COMPONENT'LERİ
  // ===========================================================================

  /// Menü component'leri listesi (temizleme için).
  final List<Component> _menuComponents = [];

  // drum_kit sprite kaldırıldı - artık CircleLaneComponent kullanılacak

  /// Skor text component'i.
  TextComponent? _scoreText;

  /// Combo text component'i.
  TextComponent? _comboText;

  /// Fever/Shield text component'i.
  TextComponent? _feverText;

  /// Pause button component'i.
  PauseButtonComponent? _pauseButton;

  /// Circle lane component'leri (modern drum kit).
  final List<CircleLaneComponent> _circleLanes = [];

  // ===========================================================================
  // DRUM KIT ÖLÇÜMLER
  // ===========================================================================

  /// Lane genişliği (piksel).
  late double _laneWidth;

  /// Drum kit'in Y başlangıç pozisyonu.
  late double _drumKitY;

  /// Drum kit yüksekliği.
  late double _drumKitHeight;

  /// Hit zone Y pozisyonu (notaların vurulması gereken çizgi).
  late double _hitZoneY;

  // ===========================================================================
  // PAD TANIMLARI - Circle bazlı hit detection
  // ===========================================================================

  /// 8 drum pad'in tanımları.
  final List<PadSpec> _pads = [
    // Lane 0: Hi-Hat
    PadSpec(lane: 0, normCx: 0.220, normCy: 0.58, normR: 0.0675),

    // Lane 1: Crash
    PadSpec(lane: 1, normCx: 0.108, normCy: 0.20, normR: 0.0810),

    // Lane 2: Ride
    PadSpec(lane: 2, normCx: 0.892, normCy: 0.20, normR: 0.0810),

    // Lane 3: Snare
    PadSpec(lane: 3, normCx: 0.332, normCy: 0.65, normR: 0.0675),

    // Lane 4: Tom 1
    PadSpec(lane: 4, normCx: 0.444, normCy: 0.24, normR: 0.0675),

    // Lane 5: Tom 2
    PadSpec(lane: 5, normCx: 0.668, normCy: 0.24, normR: 0.0675),

    // Lane 6: Tom Floor
    PadSpec(lane: 6, normCx: 0.780, normCy: 0.61, normR: 0.0810),

    // Lane 7: Kick
    PadSpec(lane: 7, normCx: 0.556, normCy: 0.78, normR: 0.1080),
  ];
  /// Drum flash efekti süreleri (her lane için).
  final List<double> _drumFlashTimers =
      List.filled(GameConstants.laneCount, 0.0);

  // ===========================================================================
  // DEBUG DEĞİŞKENLERİ
  // ===========================================================================

  /// Son dokunulan lane (debug için).
  int? _lastTappedLane;

  /// Debug lane gösterim süresi.
  double _debugLaneShowTimer = 0;

  /// Son dokunma pozisyonu (debug için).
  Vector2? _lastTapPosition;

  // ===========================================================================
  // LIFECYCLE - onLoad
  // ===========================================================================

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Kamera ayarı: sol üst köşe origin
    camera.viewfinder.anchor = Anchor.topLeft;

    // Servisleri başlat
    await LocalStorageRepository.init();
    await DrumAudioService.init();

    // Controller'ları başlat (FAZ 0)
    _scoreController = ScoreController();
    _timingController = TimingController(
      hitWindows: HitWindows.forDifficulty(_selectedDifficulty),
    );

    // drum_kit.jpg yükleme kaldırıldı - artık CircleLaneComponent kullanıyoruz

    // Son seçilen zorluğu yükle
    final lastDiff = LocalStorageRepository.lastDifficulty();
    if (lastDiff != null) {
      _selectedDifficulty = Difficulty.values.firstWhere(
        (e) => e.name == lastDiff,
        orElse: () => Difficulty.easy,
      );
    }

    // High score'u yükle
    _highScore = LocalStorageRepository.highScore(_selectedDifficulty);
  }

  // ===========================================================================
  // LIFECYCLE - onGameResize
  // ===========================================================================

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Geçersiz boyut kontrolü
    if (size.x <= 1 || size.y <= 1) return;

    // Ölçümleri hesapla
    _laneWidth = size.x / GameConstants.laneCount;
    _drumKitHeight = size.x / GameConstants.drumKitAspectRatio;
    _drumKitY = size.y - _drumKitHeight;

    // Pad'lerin world koordinatlarını güncelle
    for (final pad in _pads) {
      pad.updateWorldCoords(size.x, _drumKitY, _drumKitHeight);
    }

    // Hit zone'ı pad merkezlerinin ortalamasına hizala
    _hitZoneY = _pads
            .map((pad) => pad.cy)
            .reduce((a, b) => a + b) /
        _pads.length;

    // Controller'ları güncelle (FAZ 0) - sadece initialize edilmişlerse
    if (_timingController != null && _scoreController != null) {
      _inputController = InputController(pads: _pads);
      _gameController = GameController(
        inputController: _inputController!,
        timingController: _timingController!,
        scoreController: _scoreController!,
      );
    }

    // Mevcut state'e göre UI'ı rebuild et
    switch (_gameState) {
      case GameState.menu:
        _buildMenuUI(size);
        break;
      case GameState.playing:
        _buildGameUI(size);
        break;
      case GameState.gameOver:
        _buildGameOverUI(size);
        break;
    }
  }

  // ===========================================================================
  // MENU UI
  // ===========================================================================

  /// Ana menü UI'ını oluşturur.
  void _buildMenuUI(Vector2 screenSize) {
    // Önceki component'leri temizle
    for (final comp in _menuComponents) {
      comp.removeFromParent();
    }
    _menuComponents.clear();

    _pauseButton?.removeFromParent();
    _pauseButton = null;

    for (final lane in _circleLanes) {
      lane.removeFromParent();
    }
    _circleLanes.clear();

    final minSide = math.min(screenSize.x, screenSize.y);
    final centerX = screenSize.x / 2;
    final buttonWidth = (screenSize.x * 0.78).clamp(240.0, 520.0);
    final buttonHeight = (screenSize.y * 0.065).clamp(44.0, 68.0);
    final gap = (screenSize.y * 0.012).clamp(6.0, 14.0);
    final topY = (screenSize.y * 0.06).clamp(24.0, 64.0);

    // Başlık
    final title = TextComponent(
      text: localizations.drumHero,
      anchor: Anchor.topCenter,
      position: Vector2(centerX, topY),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: (minSide * 0.085).clamp(26.0, 46.0),
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    );

    // Alt başlık
    final subtitle = TextComponent(
      text: localizations.catchTheBeat,
      anchor: Anchor.topCenter,
      position: Vector2(centerX, topY + (minSide * 0.08).clamp(30.0, 44.0)),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: (minSide * 0.035).clamp(12.0, 18.0),
          color: const Color(0xFF8A7CFF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // High score bilgisi
    final highScoreText = TextComponent(
      text: '${localizations.highest} $_highScore',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, topY + (minSide * 0.12).clamp(46.0, 72.0)),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: (minSide * 0.028).clamp(11.0, 15.0),
          color: const Color(0xFFBDBDBD),
        ),
      ),
    );

    // Başla butonu
    final startButton = MenuButtonComponent(
      label: localizations.start,
      size: Vector2(buttonWidth, buttonHeight),
      position: Vector2(centerX, screenSize.y * 0.26),
      color: const Color(0xFF4ECDC4),
      onPressed: _startGame,
    );

    // Zorluk label
    final difficultyLabel = TextComponent(
      text: localizations.difficultyLevel,
      anchor: Anchor.topCenter,
      position: Vector2(centerX, screenSize.y * 0.37),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: (minSide * 0.03).clamp(12.0, 16.0),
          color: const Color(0xFFBDBDBD),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Zorluk butonları
    final easyButton = MenuButtonComponent(
      label: localizations.easy,
      size: Vector2(buttonWidth, buttonHeight),
      position: Vector2(centerX, screenSize.y * 0.42),
      color: const Color(0xFF22C55E),
      isSelected: _selectedDifficulty == Difficulty.easy,
      onPressed: () => _setDifficulty(Difficulty.easy),
    );

    final mediumButton = MenuButtonComponent(
      label: localizations.medium,
      size: Vector2(buttonWidth, buttonHeight),
      position: Vector2(centerX, screenSize.y * 0.42 + buttonHeight + gap),
      color: const Color(0xFFFFE66D),
      isSelected: _selectedDifficulty == Difficulty.medium,
      onPressed: () => _setDifficulty(Difficulty.medium),
    );

    final hardButton = MenuButtonComponent(
      label: localizations.hard,
      size: Vector2(buttonWidth, buttonHeight),
      position: Vector2(centerX, screenSize.y * 0.42 + 2 * (buttonHeight + gap)),
      color: const Color(0xFFFF6B6B),
      isSelected: _selectedDifficulty == Difficulty.hard,
      onPressed: () => _setDifficulty(Difficulty.hard),
    );

    // Nasıl oynanır
    final howToPlay = TextComponent(
      text: localizations.howToPlay,
      anchor: Anchor.topCenter,
      position: Vector2(centerX, screenSize.y - (buttonHeight * 2.2)),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: (minSide * 0.028).clamp(11.0, 15.0),
          color: const Color(0xFF666666),
        ),
      ),
    );

    // Çıkış butonu
    final exitButton = MenuButtonComponent(
      label: localizations.exitGame,
      size: Vector2(buttonWidth, buttonHeight),
      position: Vector2(centerX, screenSize.y - buttonHeight * 1.2),
      color: const Color(0xFFFF6B6B),
      onPressed: () => onExit?.call(),
    );

    // Component'leri ekle
    _menuComponents.addAll([
      title,
      subtitle,
      highScoreText,
      startButton,
      difficultyLabel,
      easyButton,
      mediumButton,
      hardButton,
      howToPlay,
      exitButton,
    ]);

    for (final comp in _menuComponents) {
      add(comp);
    }
  }

  /// Zorluk seviyesini değiştirir.
  void _setDifficulty(Difficulty difficulty) {
    _selectedDifficulty = difficulty;
    LocalStorageRepository.setLastDifficulty(difficulty);
    _highScore = LocalStorageRepository.highScore(difficulty);
    _buildMenuUI(size);
  }

  // ===========================================================================
  // OYUN BAŞLATMA
  // ===========================================================================

  /// Oyunu başlatır.
  void _startGame() {
    _gameState = GameState.playing;

    // Skorları sıfırla (eski sistem - FAZ 0'da kaldırılacak)
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _gameTime = 0;
    _feverTimer = 0;
    _shield = 0;
    
    // Hit tracking'i sıfırla
    _perfectHits = 0;
    _goodHits = 0;
    _missCount = 0;

    // Zorluk ayarları
    _hitWindows = HitWindows.forDifficulty(_selectedDifficulty);
    _timingController = TimingController(hitWindows: _hitWindows);
    _noteSpeed = switch (_selectedDifficulty) {
      Difficulty.easy => GameConstants.noteSpeedEasy,
      Difficulty.medium => GameConstants.noteSpeedMedium,
      Difficulty.hard => GameConstants.noteSpeedHard,
    };

    // Nota zamanlaması hesapla
    final travelTime = (_hitZoneY + 30) / _noteSpeed;
    final startOffset = travelTime + 0.8;
    final seed = DateTime.now().millisecondsSinceEpoch;

    // Beat pattern oluştur
    final events = BeatGeneratorService.generate(
      difficulty: _selectedDifficulty,
      seed: seed,
      duration: GameConstants.gameDurationSeconds,
      startOffset: startOffset,
    );

    // NoteEvent'leri ScheduledNote'lara dönüştür
    _scheduledNotes = events
        .map((e) => ScheduledNote(
              spawnAt: (e.hitTime - travelTime)
                  .clamp(0.0, GameConstants.gameDurationSeconds),
              hitTime: e.hitTime,
              lane: e.lane,
            ),)
        .toList()
      ..sort((a, b) => a.spawnAt.compareTo(b.spawnAt));

    // Controller'ı başlat (FAZ 0) - null check
    _gameController?.startGame(_scheduledNotes);

    // Menü component'lerini temizle
    for (final comp in _menuComponents) {
      comp.removeFromParent();
    }
    _menuComponents.clear();

    // Kalan notaları temizle
    _clearAllNotes();

    // Oyun UI'ını oluştur
    _buildGameUI(size);
  }

  // ===========================================================================
  // GAME UI
  // ===========================================================================

  /// Oyun içi UI'ını oluşturur.
  void _buildGameUI(Vector2 screenSize) {
    // Önceki component'leri temizle
    _scoreText?.removeFromParent();
    _comboText?.removeFromParent();
    _feverText?.removeFromParent();
    _pauseButton?.removeFromParent();

    // Flash timer'ları sıfırla
    for (int i = 0; i < _drumFlashTimers.length; i++) {
      _drumFlashTimers[i] = 0;
    }

    // Skor text
    _scoreText = TextComponent(
      text: '${localizations.score} $_score',
      anchor: Anchor.topLeft,
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );

    // Combo text
    _comboText = TextComponent(
      text: '',
      anchor: Anchor.topRight,
      position: Vector2(screenSize.x - 20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFD700),
        ),
      ),
    );

    // Fever text
    _feverText = TextComponent(
      text: '',
      anchor: Anchor.topCenter,
      position: Vector2(screenSize.x / 2, 75),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6B6B),
        ),
      ),
    );

    add(_scoreText!);
    add(_comboText!);
    add(_feverText!);
    
    // Pause button - sağ üst köşe
    _pauseButton = PauseButtonComponent(
      onPressed: () {
        pauseGame();
        overlays.add(pauseOverlayId);
      },
      position: Vector2(screenSize.x - 10, 10),
      isPaused: _isPaused,
    );
    add(_pauseButton!);
    
    // Circle lane'leri ekle (modern drum kit)
    for (final lane in _circleLanes) {
      lane.removeFromParent();
    }
    _circleLanes.clear();
    
    for (int i = 0; i < GameConstants.laneCount; i++) {
      final pad = _pads[i];
      final laneRadius = pad.r.clamp(14.0, 140.0);
      final circleLane = CircleLaneComponent(
        laneIndex: i,
        radius: laneRadius,
        color: GameConstants.laneColors[i],
        hitZoneY: _hitZoneY,
        label: GameConstants.laneNames[i],
        position: Vector2(
          pad.cx - laneRadius,
          pad.cy - laneRadius,
        ),
      );
      _circleLanes.add(circleLane);
      add(circleLane);
    }
  }

  // ===========================================================================
  // GAME OVER UI
  // ===========================================================================

  /// Game over UI'ını oluşturur.
  void _buildGameOverUI(Vector2 screenSize) {
    // Overlay kullanıldığı için eski game over UI'ı kaldırılıyor
    _scoreText?.removeFromParent();
    _comboText?.removeFromParent();
    _feverText?.removeFromParent();
    _pauseButton?.removeFromParent();
    _pauseButton = null;

    for (final lane in _circleLanes) {
      lane.removeFromParent();
    }
    _circleLanes.clear();

    for (final comp in _menuComponents) {
      comp.removeFromParent();
    }
    _menuComponents.clear();
    _clearAllNotes();
  }

  /// Ana menüye döner.
  void _goToMenu() {
    if (_score > _highScore) {
      _highScore = _score;
    }
    
    // Kalan notaları ve menü component'lerini temizle
    _clearAllNotes();
    for (final comp in _menuComponents) {
      comp.removeFromParent();
    }
    _menuComponents.clear();
    
    // Oyun UI'ını temizle
    _scoreText?.removeFromParent();
    _comboText?.removeFromParent();
    _feverText?.removeFromParent();

    _pauseButton?.removeFromParent();
    _pauseButton = null;

    for (final lane in _circleLanes) {
      lane.removeFromParent();
    }
    _circleLanes.clear();
    
    _gameState = GameState.menu;
    _buildMenuUI(size);
  }

  // ===========================================================================
  // UPDATE LOOP
  // ===========================================================================

  @override
  void update(double dt) {
    super.update(dt);

    // Oyun oynamıyorsa veya duraklatıldıysa güncelleme yapma
    if (_gameState != GameState.playing || _isPaused) return;

    _gameTime += dt;

    // Controller'ı güncelle (FAZ 0) - null check
    if (_gameController == null) return;
    
    _gameController!.update(dt);

    // Süre doldu mu?
    if (_gameTime >= GameConstants.gameDurationSeconds) {
      _endGame();
      return;
    }

    // Zamanı gelen notaları spawn et (controller'dan al)
    final notesToSpawn = _gameController!.checkForSpawns();
    for (final scheduled in notesToSpawn) {
      _spawnNote(scheduled.lane, scheduled.hitTime);
    }

    // Miss kontrolü (controller'dan)
    final missedLanes = _gameController!.checkForMisses();
    if (missedLanes.isNotEmpty) {
      _onMiss();
    }

    // Skor ve combo UI'ını güncelle (controller'dan oku)
    _score = _gameController!.score;
    _combo = _gameController!.combo;
    _maxCombo = _gameController!.maxCombo;
    _scoreText?.text = '${localizations.score} $_score';
    if (_combo > 0) {
      _comboText?.text = '${localizations.combo} $_combo';
    } else {
      _comboText?.text = '';
    }

    // Fever timer güncelle
    _updateFeverTimer(dt);

    // Flash timer'ları güncelle
    _updateFlashTimers(dt);

    // Debug timer güncelle
    _updateDebugTimer(dt);

    // Notaları güncelle (hareket)
    _updateNotes(dt);
  }



  /// Belirtilen lane'de nota spawn eder.
  void _spawnNote(int lane, double hitTime) {
    final pad = _pads[lane];
    final note = NoteComponent(
      laneIndex: lane,
      hitTime: hitTime,
      position: Vector2(pad.cx, -30), // Ekranın üstünden başla
      radius: _laneWidth * 0.32,
      color: GameConstants.laneColors[lane],
      hitZoneY: pad.cy,
      speed: _noteSpeed,
      performanceMode: performanceMode,
    );
    _notesByLane[lane].add(note);
    add(note);
  }

  /// Fever timer'ı günceller ve UI'ı günceller.
  void _updateFeverTimer(double dt) {
    if (_feverTimer > 0) {
      _feverTimer -= dt;
      if (_feverTimer < 0) _feverTimer = 0;
      _feverText?.text =
          '${localizations.fever} ${_feverTimer.toStringAsFixed(1)}s';
    } else {
      _feverText?.text = '';
    }

    // Shield gösterimi
    if (_shield > 0 && _feverTimer <= 0) {
      _feverText?.text = localizations.shieldReady;
    }
  }

  /// Flash timer'ları günceller.
  void _updateFlashTimers(double dt) {
    for (int i = 0; i < _drumFlashTimers.length; i++) {
      if (_drumFlashTimers[i] > 0) {
        _drumFlashTimers[i] -= dt;
      }
    }
  }

  /// Debug timer'ı günceller.
  void _updateDebugTimer(double dt) {
    if (_debugLaneShowTimer > 0) {
      _debugLaneShowTimer -= dt;
      if (_debugLaneShowTimer <= 0) {
        _lastTappedLane = null;
        _lastTapPosition = null;
      }
    }
  }

  /// Tüm notaları günceller (hareket ve miss kontrolü).
  void _updateNotes(double dt) {
    for (int lane = 0; lane < GameConstants.laneCount; lane++) {
      final queue = _notesByLane[lane];
      final toRemove = <NoteComponent>[];
      final pad = _pads[lane];

      for (final note in queue) {
        // Notayı hareket ettir
        note.position.y += note.speed * dt;

        // Hit zone'a ulaştıysa ve vurulmadıysa miss say
        if (!note.isHit && !note.isMissed && note.position.y >= pad.cy) {
          note.isMissed = true;
          toRemove.add(note);
          add(
            HitFeedbackRingFactory.miss(
              position: Vector2(pad.cx, pad.cy),
              radius: pad.r * 0.9,
              performanceMode: performanceMode,
            ),
          );
        }

        // Ekrandan çıktı mı?
        if (note.position.y > size.y + 50) {
          toRemove.add(note);
        }
      }

      // Kaldırılacak notaları temizle
      for (final note in toRemove) {
        queue.remove(note);
        note.removeFromParent();
      }
    }
  }

  /// Tüm notaları temizler.
  void _clearAllNotes() {
    for (final queue in _notesByLane) {
      for (final note in queue) {
        note.removeFromParent();
      }
      queue.clear();
    }
  }

  // ===========================================================================
  // INPUT HANDLING
  // ===========================================================================

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (_gameState == GameState.playing) {
      final tapPosition = event.localPosition;

      // Debug için tap pozisyonunu kaydet
      if (debugMode) {
        _lastTapPosition = Vector2(tapPosition.x, tapPosition.y);
      }

      // SADECE drum kit alanında hit al
      if (tapPosition.y >= _drumKitY &&
          _gameController != null &&
          _inputController != null) {
        final lane = _inputController!.detectLane(tapPosition);
        if (lane == null) return;

        // Debug için lane'i kaydet
        if (debugMode) {
          _lastTappedLane = lane;
          _debugLaneShowTimer = 1.5;
        }

        final pad = _pads[lane];
        final queue = _notesByLane[lane];
        final note = queue.isNotEmpty ? queue.first : null;
        final isInCatchZone =
            note != null && _isNoteInCatchZone(note, pad);

        if (isInCatchZone) {
          final hitResult = _gameController!.processTap(tapPosition);

          if (hitResult != null && hitResult.isSuccessful) {
            // Notayı kaldır
            queue.removeAt(0);
            note.markHit();

            add(
              HitFeedbackRingFactory.success(
                position: Vector2(pad.cx, pad.cy),
                radius: pad.r * 0.9,
                performanceMode: performanceMode,
              ),
            );

            // Ses çal
            DrumAudioService.playLane(lane);

            // Flash efekti - hem eski sistem hem circle lane
            _drumFlashTimers[lane] = GameConstants.drumFlashDuration;
            if (lane < _circleLanes.length) {
              _circleLanes[lane].triggerFlash();
            }

            // Haptic feedback
            _triggerHaptic(hitResult.quality);

            // Hit tracking için quality'yi kaydet
            switch (hitResult.quality) {
              case HitQuality.perfect:
                _perfectHits++;
                break;
              case HitQuality.good:
                _goodHits++;
                break;
              case HitQuality.miss:
                _missCount++;
                break;
            }
          } else {
            // Catch zone içindeyken timing kaçırıldıysa miss
            add(
              HitFeedbackRingFactory.miss(
                position: Vector2(pad.cx, pad.cy),
                radius: pad.r * 0.9,
                performanceMode: performanceMode,
              ),
            );
          }
        } else {
          // Catch zone dışında tap => miss feedback
          add(
            HitFeedbackRingFactory.miss(
              position: Vector2(pad.cx, pad.cy),
              radius: pad.r * 0.9,
              performanceMode: performanceMode,
            ),
          );
        }
      }
    }
  }

  bool _isNoteInCatchZone(NoteComponent note, PadSpec pad) {
    final dx = note.position.x - pad.cx;
    final dy = note.position.y - pad.cy;
    final maxR = pad.r * 0.65;
    return (dx * dx + dy * dy) <= (maxR * maxR);
  }

  /// Hit quality'ye göre haptic feedback tetikler.
  void _triggerHaptic(HitQuality quality) {
    switch (quality) {
      case HitQuality.perfect:
        HapticFeedback.lightImpact();
        break;
      case HitQuality.good:
        HapticFeedback.selectionClick();
        break;
      case HitQuality.miss:
        // Miss için haptic yok
        break;
    }
  }

  /// Miss işler.
  void _onMiss() {
    _comboText?.text = localizations.miss;
    HapticFeedback.mediumImpact();
    _missCount++; // Miss tracking
  }

  /// Oyunu bitirir.
  void _endGame() {
    // High score güncelle
    final score = _gameController?.score ?? 0;
    if (score > _highScore) {
      _highScore = score;
      LocalStorageRepository.setHighScore(_selectedDifficulty, _highScore);
    }

    _gameState = GameState.gameOver;
    
    // Modern game over overlay'i göster
    overlays.add(gameOverOverlayId);

    // Game end callback (reklam için)
    onGameEnd?.call();
  }

  // ===========================================================================
  // RENDER
  // ===========================================================================

  @override
  void render(ui.Canvas canvas) {
    // Arka plan
    canvas.drawColor(GameConstants.backgroundColor, ui.BlendMode.src);

    // State'e göre render
    if (_gameState == GameState.playing) {
      _renderGameBackground(canvas);
    } else if (_gameState == GameState.menu) {
      _renderMenuBackground(canvas);
    }

    super.render(canvas);
  }

  /// Menü arka planını render eder.
  void _renderMenuBackground(ui.Canvas canvas) {
    final decorPaint = ui.Paint()..color = GameConstants.menuDecorColor;
    for (int i = 0; i < GameConstants.laneCount; i++) {
      final x = (i + 0.5) * (size.x / GameConstants.laneCount);
      canvas.drawCircle(ui.Offset(x, size.y - 50), 20, decorPaint);
    }
  }

  /// Oyun arka planını render eder.
  void _renderGameBackground(ui.Canvas canvas) {
    // Debug pad gösterimi
    if (debugMode) _renderDebugPads(canvas);

    // Drum flash efektleri
    for (int i = 0; i < _pads.length; i++) {
      if (_drumFlashTimers[i] > 0) {
        final pad = _pads[i];
        final flashPaint = ui.Paint()
          ..color = GameConstants.laneColors[i]
              .withValues(alpha: _drumFlashTimers[i] * 3)
          ..style = ui.PaintingStyle.fill;
        canvas.drawCircle(ui.Offset(pad.cx, pad.cy), pad.r, flashPaint);
      }
    }

    // Debug tap bilgisi
    if (debugMode && _lastTappedLane != null) {
      _renderDebugTapInfo(canvas);
    }

    // Hit çizgisi
    final hitLinePaint = ui.Paint()
      ..color = GameConstants.hitLineColor
      ..strokeWidth = 2;
    canvas.drawLine(
      ui.Offset(0, _hitZoneY),
      ui.Offset(size.x, _hitZoneY),
      hitLinePaint,
    );

    // Progress bar
    _renderProgressBar(canvas);
  }

  /// Progress bar'ı render eder.
  void _renderProgressBar(ui.Canvas canvas) {
    final progress = 1 - (_gameTime / GameConstants.gameDurationSeconds);
    final barWidth = size.x * 0.6;
    final barX = (size.x - barWidth) / 2;

    // Arka plan
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(barX, 55, barWidth, 8),
        const ui.Radius.circular(4),
      ),
      ui.Paint()..color = GameConstants.progressBarBackgroundColor,
    );

    // Progress
    final progressColor = progress > 0.3
        ? GameConstants.progressBarFullColor
        : GameConstants.progressBarLowColor;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(barX, 55, barWidth * progress, 8),
        const ui.Radius.circular(4),
      ),
      ui.Paint()..color = progressColor,
    );
  }

  /// Debug için pad bölgelerini render eder.
  void _renderDebugPads(ui.Canvas canvas) {
    for (int i = 0; i < _pads.length; i++) {
      final pad = _pads[i];

      // Dolgu
      canvas.drawCircle(
        ui.Offset(pad.cx, pad.cy),
        pad.r,
        ui.Paint()
          ..color = GameConstants.laneColors[i].withValues(alpha: 0.15)
          ..style = ui.PaintingStyle.fill,
      );

      // Border
      canvas.drawCircle(
        ui.Offset(pad.cx, pad.cy),
        pad.r,
        ui.Paint()
          ..color = GameConstants.laneColors[i].withValues(alpha: 0.8)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i: ${GameConstants.laneNames[i]}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: GameConstants.laneColors[i],
            backgroundColor: const ui.Color(0xAA000000),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pad.cx - textPainter.width / 2, pad.cy - 5),
      );
    }
  }

  /// Debug tap bilgisini render eder.
  void _renderDebugTapInfo(ui.Canvas canvas) {
    final laneText = _lastTappedLane != null
        ? 'Lane $_lastTappedLane: ${GameConstants.laneNames[_lastTappedLane!]}'
        : 'No pad hit (outside circles)';
    final textColor = _lastTappedLane != null
        ? GameConstants.laneColors[_lastTappedLane!]
        : const Color(0xFFFF4444);

    // Bilgi kutusu
    final boxRect = ui.Rect.fromLTWH(10, size.y - 140, size.x - 20, 60);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(boxRect, const ui.Radius.circular(8)),
      ui.Paint()..color = const ui.Color(0xDD000000),
    );

    // Lane text
    final textPainter = TextPainter(
      text: TextSpan(
        text: laneText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(boxRect.left + 10, boxRect.top + 8));

    // Tap pozisyonu
    if (_lastTapPosition != null) {
      final posPainter = TextPainter(
        text: TextSpan(
          text: 'Tap: (${_lastTapPosition!.x.toStringAsFixed(0)}, '
              '${_lastTapPosition!.y.toStringAsFixed(0)})',
          style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
        ),
        textDirection: TextDirection.ltr,
      );
      posPainter.layout();
      posPainter.paint(canvas, Offset(boxRect.left + 10, boxRect.top + 32));

      // Tap işareti
      canvas.drawCircle(
        ui.Offset(_lastTapPosition!.x, _lastTapPosition!.y),
        15,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  // ===========================================================================
  // PUBLIC API - Pause/Resume
  // ===========================================================================

  /// Oyunu duraklatır.
  void pauseGame() {
    _isPaused = true;
    pauseEngine();
    _pauseButton?.setPaused(true);
  }

  /// Oyunu devam ettirir.
  void resumeGame() {
    _isPaused = false;
    resumeEngine();
    _pauseButton?.setPaused(false);
  }

  @override
  void onRemove() {
    DrumAudioService.stopAll();
    super.onRemove();
  }

  /// Oyunun duraklatılmış olup olmadığını döndürür.
  bool get isPaused => _isPaused;

  /// Mevcut oyun durumunu döndürür.
  GameState get gameState => _gameState;
  
  /// Mevcut skoru döndürür.
  int get currentScore => _score;
  
  /// Accuracy (isabet oranı) döndürür.
  double get accuracy {
    final total = _perfectHits + _goodHits + _missCount;
    if (total == 0) return 100.0;
    return ((_perfectHits + _goodHits) / total) * 100.0;
  }
  
  /// Maksimum combo değerini döndürür.
  int get maxCombo => _maxCombo;
  
  /// Perfect hit sayısını döndürür.
  int get perfectHits => _perfectHits;
  
  /// Good hit sayısını döndürür.
  int get goodHits => _goodHits;
  
  /// Miss sayısını döndürür.
  int get missCount => _missCount;

  // ===========================================================================
  // PAUSE OVERLAY METHODS
  // ===========================================================================

  /// Pause overlay'den oyunu devam ettirir.
  void resumeFromPause() {
    overlays.remove(pauseOverlayId);
    resumeGame();
  }

  /// Pause overlay'den oyunu yeniden başlatır.
  void restartFromPause() {
    overlays.remove(pauseOverlayId);
    resumeGame();
    _startGame();
  }

  /// Pause overlay'den ana menüye döner.
  void goToMenuFromPause() {
    overlays.remove(pauseOverlayId);
    resumeGame();
    _goToMenu();
  }
  
  // ===========================================================================
  // GAME OVER OVERLAY METHODS
  // ===========================================================================

  /// Game over overlay'den oyunu yeniden başlatır.
  void restartFromGameOver() {
    overlays.remove(gameOverOverlayId);
    _startGame();
  }

  /// Game over overlay'den ana menüye döner.
  void goToMenuFromGameOver() {
    overlays.remove(gameOverOverlayId);
    _goToMenu();
  }
}
