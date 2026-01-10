import 'dart:math';
import 'dart:ui' as ui;
import 'dart:io' show Platform;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Difficulty { easy, medium, hard }
enum GameState { menu, playing, gameOver }

// ============================================================================
// AUDIO HELPER - Lane bazlı drum sesleri
// ============================================================================
class DrumSfx {
  static final List<String> _basesByLane = [
    'close_hihat',
    'open_hihat',
    'crash_2',
    'ride_1',
    'snare_hard',
    'kick',
    'tom_1',
    'tom_floor',
  ];

  static late final String _ext;
  static late final List<AudioPool> _pools;
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;

    // iOS/macOS: m4a daha garanti, Android: ogg daha iyi
    _ext = (Platform.isIOS || Platform.isMacOS) ? 'm4a' : 'ogg';

    _pools = [];
    for (final base in _basesByLane) {
      final path = 'audio/$base.$_ext';
      final pool = await AudioPool.create(
        source: AssetSource(path),
        maxPlayers: 6,
      );
      _pools.add(pool);
    }
    _ready = true;
  }

  static void playLane(int lane, {double volume = 1.0}) {
    if (!_ready) return;
    if (lane < 0 || lane >= _pools.length) return;
    _pools[lane].start(volume: volume);
  }
}

// ============================================================================
// LOCAL STORAGE - SharedPreferences helper
// ============================================================================
class LocalStore {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static int highScore(Difficulty d) =>
      _prefs?.getInt('dh_high_${d.name}') ?? 0;

  static Future<void> setHighScore(Difficulty d, int score) async {
    await _prefs?.setInt('dh_high_${d.name}', score);
  }

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static int dailyBest(Difficulty d) =>
      _prefs?.getInt('dh_daily_${_todayKey()}_${d.name}') ?? 0;

  static Future<void> setDailyBest(Difficulty d, int score) async {
    await _prefs?.setInt('dh_daily_${_todayKey()}_${d.name}', score);
  }

  static String? lastDifficulty() => _prefs?.getString('dh_last_diff');
  
  static Future<void> setLastDifficulty(Difficulty d) async {
    await _prefs?.setString('dh_last_diff', d.name);
  }
}

// ============================================================================
// BEAT GENERATOR - Random beat pattern oluşturucu
// ============================================================================
class NoteEvent {
  const NoteEvent(this.hitTime, this.lane);
  final double hitTime;
  final int lane;
}

class ScheduledNote {
  const ScheduledNote({required this.spawnAt, required this.lane});
  final double spawnAt;
  final int lane;
}

class BeatGenerator {
  static int _pickBpm(Difficulty d, Random r) => switch (d) {
      Difficulty.easy => 95 + r.nextInt(21),    // 95–115
      Difficulty.medium => 110 + r.nextInt(26), // 110–135
      Difficulty.hard => 130 + r.nextInt(31),   // 130–160
    };

  static List<NoteEvent> generate({
    required Difficulty difficulty,
    required int seed,
    required double duration,
    required double startOffset,
  }) {
    final r = Random(seed);
    final bpm = _pickBpm(difficulty, r);

    final sixteenth = (60.0 / bpm) / 4.0;
    final steps = ((duration - startOffset) / sixteenth).floor();

    // Lane sabitleri
    const lh = 0;  // close hat
    const lo = 1;  // open hat
    const lc = 2;  // crash
    const lr = 3;  // ride
    const ls = 4;  // snare
    const lk = 5;  // kick
    const lt1 = 6; // tom1
    const ltf = 7; // tom floor

    final events = <NoteEvent>[];

    int bar = 0;
    for (int i = 0; i < steps; i++) {
      final t = startOffset + i * sixteenth;
      final inBar = i % 16;
      if (inBar == 0) bar++;

      // Snare: 2 ve 4 (16'lıkta 4 ve 12)
      if (inBar == 4 || inBar == 12) {
        events.add(NoteEvent(t, ls));
      }

      // Kick: 1 ve 3 (0 ve 8), + varyasyon
      if (inBar == 0 || inBar == 8) {
        events.add(NoteEvent(t, lk));
      } else {
        final extraKickChance = switch (difficulty) {
          Difficulty.easy => 0.10,
          Difficulty.medium => 0.18,
          Difficulty.hard => 0.26,
        };
        if (r.nextDouble() < extraKickChance &&
            (inBar == 6 || inBar == 10 || inBar == 14)) {
          events.add(NoteEvent(t, lk));
        }
      }

      // Hihat
      final hatEvery = switch (difficulty) {
        Difficulty.easy => 2,
        Difficulty.medium => 1,
        Difficulty.hard => 1,
      };

      if (i % hatEvery == 0) {
        if (difficulty == Difficulty.medium && r.nextDouble() < 0.25) {
          // medium: biraz boşluk bırak
        } else {
          events.add(NoteEvent(t, lh));
        }
      }

      // Open hat: bar sonu
      if ((inBar == 14 || inBar == 15) &&
          r.nextDouble() < (difficulty == Difficulty.hard ? 0.22 : 0.12)) {
        events.add(NoteEvent(t, lo));
      }

      // Crash: bar başı ara ara
      if (inBar == 0 && r.nextDouble() < 0.18) {
        events.add(NoteEvent(t, lc));
      }

      // Ride (özellikle hard'da)
      if (difficulty == Difficulty.hard &&
          (inBar == 2 || inBar == 6 || inBar == 10 || inBar == 14) &&
          r.nextDouble() < 0.35) {
        events.add(NoteEvent(t, lr));
      }

      // Tom fill: her 4 bar'da bir
      final isFillBar = (bar % 4 == 0);
      if (isFillBar && inBar >= 12) {
        if (difficulty != Difficulty.easy && r.nextDouble() < 0.25) {
          final lane = (inBar.isEven) ? lt1 : ltf;
          events.add(NoteEvent(t, lane));
        }
      }
    }

    // Aynı anda aşırı nota olmasın
    final maxSimul = switch (difficulty) {
      Difficulty.easy => 2,
      Difficulty.medium => 3,
      Difficulty.hard => 4,
    };

    return _capSimultaneous(events, maxSimul);
  }

  static List<NoteEvent> _capSimultaneous(List<NoteEvent> events, int maxSimul) {
    events.sort((a, b) => a.hitTime.compareTo(b.hitTime));

    final out = <NoteEvent>[];
    int i = 0;
    while (i < events.length) {
      final t = events[i].hitTime;
      final sameTime = <NoteEvent>[];
      while (i < events.length && (events[i].hitTime - t).abs() < 0.0001) {
        sameTime.add(events[i]);
        i++;
      }
      if (sameTime.length <= maxSimul) {
        out.addAll(sameTime);
      } else {
        sameTime.sort((a, b) {
          int p(NoteEvent e) => switch (e.lane) {
              5 => 0,  // kick
              4 => 1,  // snare
              6 || 7 => 2, // tom
              2 => 3,  // crash
              3 => 4,  // ride
              1 => 5,  // open hat
              0 => 6,  // close hat
              _ => 7,
            };
          return p(a).compareTo(p(b));
        });
        out.addAll(sameTime.take(maxSimul));
      }
    }
    return out;
  }
}

/// Ana oyun sınıfı - Menü ve DrumHero oyununu içerir
class DrumHeroGame extends FlameGame with TapCallbacks {
  DrumHeroGame({
    this.onExit,
    this.debugMode = false,
  });

  final VoidCallback? onExit;
  
  /// Debug modu: drum bölgelerini sürekli gösterir ve tap edilen lane'i ekranda gösterir
  final bool debugMode;

  GameState _gameState = GameState.menu;
  Difficulty _selectedDifficulty = Difficulty.easy;
  
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _highScore = 0;

  // Oyun sabitleri
  static const int laneCount = 8;
  late double _laneWidth;
  late double _hitZoneY;
  late double _noteSpeed;

  // Scheduled spawn sistemi
  List<ScheduledNote> _scheduled = [];
  int _nextSpawnIndex = 0;
  bool _isDailyChallenge = false;

  // Fever + Shield sistemi
  double _feverTimer = 0;
  int _shield = 0;
  int _perfectStreak = 0;

  // Menü bileşenleri
  final List<Component> _menuComponents = [];
  
  // Oyun bileşenleri
  final List<Note> _activeNotes = [];
  
  // Drum kit resmi
  SpriteComponent? _drumKitSprite;
  ui.Image? _drumKitImage;
  late double _drumKitY;
  late double _drumKitHeight;
  
  // Drum bölgeleri - resme göre hit alanları (yüzde olarak)
  // Lane sırası: close_hihat, open_hihat, crash_2, ride_1, snare_hard, kick, tom_1, tom_floor
  // Her bölge: [xStart%, xEnd%, yStart%, yEnd%]
  static const List<List<double>> _drumRegions = [
    [0.00, 0.12, 0.15, 0.55],  // 0: close hihat (sol üst)
    [0.10, 0.22, 0.00, 0.40],  // 1: open hihat (üst sol)
    [0.20, 0.35, 0.00, 0.35],  // 2: crash (üst orta-sol)
    [0.65, 0.80, 0.00, 0.35],  // 3: ride (üst sağ)
    [0.35, 0.50, 0.35, 0.70],  // 4: snare (orta sol)
    [0.45, 0.60, 0.60, 1.00],  // 5: kick (alt orta)
    [0.50, 0.65, 0.30, 0.60],  // 6: tom1 (üst orta)
    [0.78, 1.00, 0.40, 0.80],  // 7: floor tom (sağ alt)
  ];
  
  // Flash efekti için
  final List<double> _drumFlashTimers = List.filled(8, 0.0);
  TextComponent? _gameScoreText;
  TextComponent? _comboText;
  TextComponent? _feverText;
  
  // Debug mode için
  int? _lastTappedLane;
  double _debugLaneShowTimer = 0;
  Vector2? _lastTapPosition;

  // Zamanlama
  double _gameTime = 0;
  static const double gameDuration = 60.0;

  // Lane renkleri
  static const List<Color> laneColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFE66D),
    Color(0xFF4ECDC4),
    Color(0xFF95E1D3),
    Color(0xFFA8E6CF),
    Color(0xFF88D8B0),
    Color(0xFFB8B5FF),
    Color(0xFFFF9F9F),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // Local storage ve audio init
    await LocalStore.init();
    await DrumSfx.init();
    
    // Drum kit resmini yükle
    _drumKitImage = await images.load('drum_kit.jpg');

    // Son zorluk seviyesini geri yükle
    final last = LocalStore.lastDifficulty();
    if (last != null) {
      _selectedDifficulty = Difficulty.values.firstWhere(
        (e) => e.name == last,
        orElse: () => Difficulty.easy,
      );
    }
    _highScore = LocalStore.highScore(_selectedDifficulty);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (size.x <= 1 || size.y <= 1) return;

    _laneWidth = size.x / laneCount;
    
    // Drum kit resmi ekranın altında, genişliği ekrana sığacak şekilde
    final drumAspectRatio = 1024 / 559; // resmin orijinal oranı
    _drumKitHeight = size.x / drumAspectRatio;
    _drumKitY = size.y - _drumKitHeight;
    _hitZoneY = _drumKitY + (_drumKitHeight * 0.5); // Orta kısım hit zone

    if (_gameState == GameState.menu) {
      _buildMenu(size);
    } else if (_gameState == GameState.playing) {
      _buildGameUI(size);
    } else if (_gameState == GameState.gameOver) {
      _buildGameOverUI(size);
    }
  }

  void _buildMenu(Vector2 screenSize) {
    // Önceki menü bileşenlerini temizle
    for (final comp in _menuComponents) {
      comp.removeFromParent();
    }
    _menuComponents.clear();

    final centerX = screenSize.x / 2;
    final btnW = (screenSize.x * 0.72).clamp(220.0, 420.0);
    const btnH = 50.0;
    const gap = 10.0;

    // Başlık
    final title = TextComponent(
      text: 'DRUM HERO',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );

    // Alt başlık
    final subtitle = TextComponent(
      text: 'Ritmi Yakala!',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 88),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF8A7CFF),
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    // High Score + Daily Best
    final dailyBest = LocalStore.dailyBest(_selectedDifficulty);
    final highScoreText = TextComponent(
      text: '🏆 En Yüksek: $_highScore  |  📅 Günlük: $dailyBest',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 118),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFFBDBDBD),
        ),
      ),
    );

    // Başla butonu
    final startButton = MenuButton(
      label: '▶  BAŞLA',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 160),
      color: const Color(0xFF4ECDC4),
      onPressed: () => _startGame(),
    );

    // Daily Challenge butonu
    final dailyButton = MenuButton(
      label: '🎯  GÜNLÜK CHALLENGE',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 160 + btnH + gap),
      color: const Color(0xFFB8B5FF),
      onPressed: () => _startGame(daily: true),
    );

    // Seviye başlığı
    final difficultyLabel = TextComponent(
      text: 'Zorluk Seviyesi',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 285),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFBDBDBD),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Zorluk butonları
    final easyButton = MenuButton(
      label: 'KOLAY',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 315),
      color: const Color(0xFF22C55E),
      isSelected: _selectedDifficulty == Difficulty.easy,
      onPressed: () => _setDifficulty(Difficulty.easy),
    );

    final mediumButton = MenuButton(
      label: 'ORTA',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 315 + btnH + gap),
      color: const Color(0xFFFFE66D),
      isSelected: _selectedDifficulty == Difficulty.medium,
      onPressed: () => _setDifficulty(Difficulty.medium),
    );

    final hardButton = MenuButton(
      label: 'ZOR',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 315 + 2 * (btnH + gap)),
      color: const Color(0xFFFF6B6B),
      isSelected: _selectedDifficulty == Difficulty.hard,
      onPressed: () => _setDifficulty(Difficulty.hard),
    );

    // Nasıl oynanır
    final howToPlay = TextComponent(
      text: '🎵 Notalar düştüğünde dairelere dokun!',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, screenSize.y - 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF666666),
        ),
      ),
    );

    // Oyundan Çıkış butonu
    final exitButton = MenuButton(
      label: '✕  OYUNDAN ÇIK',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, screenSize.y - 55),
      color: const Color(0xFFFF6B6B),
      onPressed: () => onExit?.call(),
    );

    _menuComponents.addAll([
      title, subtitle, highScoreText, startButton, dailyButton,
      difficultyLabel, easyButton, mediumButton, hardButton,
      howToPlay, exitButton,
    ]);

    for (final comp in _menuComponents) {
      add(comp);
    }
  }

  void _setDifficulty(Difficulty d) {
    _selectedDifficulty = d;
    LocalStore.setLastDifficulty(d);
    _highScore = LocalStore.highScore(d);
    _buildMenu(size);
  }

  void _spawnLane(int lane) {
    // Notayı ilgili drum bölgesinin merkezine doğru düşür
    final targetX = _getDrumRegionCenterX(lane);
    final note = Note(
      laneIndex: lane,
      position: Vector2(targetX, -30),
      radius: _laneWidth * 0.32,
      color: laneColors[lane],
      speed: _noteSpeed,
    );
    _activeNotes.add(note);
    add(note);
  }

  void _startGame({bool daily = false}) {
    _isDailyChallenge = daily;

    _gameState = GameState.playing;
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _gameTime = 0;

    _feverTimer = 0;
    _shield = 0;
    _perfectStreak = 0;

    // Zorluk ayarları
    switch (_selectedDifficulty) {
      case Difficulty.easy:
        _noteSpeed = 180;
        break;
      case Difficulty.medium:
        _noteSpeed = 220;
        break;
      case Difficulty.hard:
        _noteSpeed = 260;
        break;
    }

    // Travel time hesapla
    final travelTime = (_hitZoneY + 30) / _noteSpeed;
    final startOffset = travelTime + 0.8;

    // Seed: daily için gün bazlı, normal için milisaniye
    final seed = daily
        ? DateTime.now().year * 10000 + DateTime.now().month * 100 + DateTime.now().day
        : DateTime.now().millisecondsSinceEpoch;

    // Beat pattern oluştur
    final events = BeatGenerator.generate(
      difficulty: _selectedDifficulty,
      seed: seed,
      duration: gameDuration,
      startOffset: startOffset,
    );

    _scheduled = events
        .map((e) => ScheduledNote(
              spawnAt: (e.hitTime - travelTime).clamp(0.0, gameDuration),
              lane: e.lane,
            ),)
        .toList()
      ..sort((a, b) => a.spawnAt.compareTo(b.spawnAt));

    _nextSpawnIndex = 0;

    // Menüyü temizle
    for (final comp in _menuComponents) {
      comp.removeFromParent();
    }
    _menuComponents.clear();

    // Oyun UI'ını oluştur
    _buildGameUI(size);
  }

  void _buildGameUI(Vector2 screenSize) {
    // Önceki oyun bileşenlerini temizle
    _drumKitSprite?.removeFromParent();
    for (final n in _activeNotes) {
      n.removeFromParent();
    }
    _activeNotes.clear();
    _gameScoreText?.removeFromParent();
    _comboText?.removeFromParent();
    _feverText?.removeFromParent();
    
    // Flash timer'ları sıfırla
    for (int i = 0; i < _drumFlashTimers.length; i++) {
      _drumFlashTimers[i] = 0;
    }

    // Skor
    _gameScoreText = TextComponent(
      text: 'Skor: $_score',
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

    // Combo
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

    add(_gameScoreText!);
    add(_comboText!);

    // Fever indicator
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
    add(_feverText!);

    // Drum kit sprite'ını oluştur
    if (_drumKitImage != null) {
      _drumKitSprite = SpriteComponent(
        sprite: Sprite(_drumKitImage!),
        position: Vector2(0, _drumKitY),
        size: Vector2(screenSize.x, _drumKitHeight),
      );
      add(_drumKitSprite!);
    }
  }

  void _buildGameOverUI(Vector2 screenSize) {
    // Önceki bileşenleri temizle
    _drumKitSprite?.removeFromParent();
    for (final n in _activeNotes) {
      n.removeFromParent();
    }
    _activeNotes.clear();
    _gameScoreText?.removeFromParent();
    _comboText?.removeFromParent();
    _feverText?.removeFromParent();
    for (final comp in _menuComponents) {
      comp.removeFromParent();
    }
    _menuComponents.clear();

    final centerX = screenSize.x / 2;
    final btnW = (screenSize.x * 0.72).clamp(220.0, 420.0);
    const btnH = 50.0;

    final gameOverTitle = TextComponent(
      text: _isDailyChallenge ? 'GÜNLÜK CHALLENGE!' : 'OYUN BİTTİ!',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 80),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );

    final finalScore = TextComponent(
      text: 'Skor: $_score',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 140),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4ECDC4),
        ),
      ),
    );

    final comboInfo = TextComponent(
      text: 'En Yüksek Combo: $_maxCombo',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 185),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFFFFD700),
        ),
      ),
    );

    // Daily/All-time best gösterimi
    final dailyBest = LocalStore.dailyBest(_selectedDifficulty);
    final bestInfo = TextComponent(
      text: '🏆 Rekor: $_highScore  |  📅 Günlük: $dailyBest',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 215),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFBDBDBD),
        ),
      ),
    );

    String ratingText;
    Color ratingColor;
    if (_score >= 5000) {
      ratingText = '🏆 EFSANE!';
      ratingColor = const Color(0xFFFFD700);
    } else if (_score >= 3000) {
      ratingText = '⭐ HARİKA!';
      ratingColor = const Color(0xFF4ECDC4);
    } else if (_score >= 1500) {
      ratingText = '👍 İYİ!';
      ratingColor = const Color(0xFF22C55E);
    } else {
      ratingText = '💪 Tekrar Dene!';
      ratingColor = const Color(0xFFBDBDBD);
    }

    final rating = TextComponent(
      text: ratingText,
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 255),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: ratingColor,
        ),
      ),
    );

    final playAgainButton = MenuButton(
      label: '🔄  TEKRAR OYNA',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 320),
      color: const Color(0xFF4ECDC4),
      onPressed: () => _startGame(daily: _isDailyChallenge),
    );

    final menuButton = MenuButton(
      label: '🏠  ANA MENÜ',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 385),
      color: const Color(0xFF666666),
      onPressed: _goToMenu,
    );

    _menuComponents.addAll([
      gameOverTitle, finalScore, comboInfo, bestInfo, rating,
      playAgainButton, menuButton,
    ]);

    for (final comp in _menuComponents) {
      add(comp);
    }
  }

  void _goToMenu() {
    if (_score > _highScore) {
      _highScore = _score;
    }
    _gameState = GameState.menu;
    _buildMenu(size);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_gameState != GameState.playing) return;

    _gameTime += dt;

    // Oyun süresi kontrolü
    if (_gameTime >= gameDuration) {
      _endGame();
      return;
    }

    // Scheduled spawn - beat pattern'dan notaları spawn et
    while (_nextSpawnIndex < _scheduled.length &&
        _scheduled[_nextSpawnIndex].spawnAt <= _gameTime) {
      _spawnLane(_scheduled[_nextSpawnIndex].lane);
      _nextSpawnIndex++;
    }

    // Fever timer
    if (_feverTimer > 0) {
      _feverTimer -= dt;
      if (_feverTimer < 0) _feverTimer = 0;
      _feverText?.text = '🔥 FEVER x2! ${_feverTimer.toStringAsFixed(1)}s';
    } else {
      _feverText?.text = '';
    }

    // Shield indicator
    if (_shield > 0 && _feverTimer <= 0) {
      _feverText?.text = '🛡️ SHIELD READY';
    }
    
    // Drum flash timer'ları güncelle
    for (int i = 0; i < _drumFlashTimers.length; i++) {
      if (_drumFlashTimers[i] > 0) {
        _drumFlashTimers[i] -= dt;
      }
    }
    
    // Debug lane gösterim timer'ı
    if (_debugLaneShowTimer > 0) {
      _debugLaneShowTimer -= dt;
      if (_debugLaneShowTimer <= 0) {
        _lastTappedLane = null;
        _lastTapPosition = null;
      }
    }

    // Notaları güncelle
    _updateNotes(dt);
  }

  void _updateNotes(double dt) {
    final notesToRemove = <Note>[];

    for (final note in _activeNotes) {
      note.position.y += note.speed * dt;

      if (note.position.y > _hitZoneY + 70 && !note.isHit) {
        note.isMissed = true;
        notesToRemove.add(note);
        _onMiss();
      }

      if (note.position.y > size.y + 50) {
        notesToRemove.add(note);
      }
    }

    for (final note in notesToRemove) {
      _activeNotes.remove(note);
      note.removeFromParent();
    }
  }

  // Lane isimleri (debug için)
  static const List<String> _laneNames = [
    'Close Hi-Hat',
    'Open Hi-Hat', 
    'Crash',
    'Ride',
    'Snare',
    'Kick',
    'Tom 1',
    'Floor Tom',
  ];
  
  /// Debug mode: Drum bölgelerini sürekli outline olarak çizer
  void _renderDebugDrumRegions(ui.Canvas canvas) {
    for (int i = 0; i < _drumRegions.length; i++) {
      final region = _drumRegions[i];
      final rect = ui.Rect.fromLTWH(
        region[0] * size.x,
        _drumKitY + region[2] * _drumKitHeight,
        (region[1] - region[0]) * size.x,
        (region[3] - region[2]) * _drumKitHeight,
      );
      
      // Dolgu (yarı saydam)
      final fillPaint = ui.Paint()
        ..color = laneColors[i].withValues(alpha: 0.15)
        ..style = ui.PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);
      
      // Kenarlık
      final borderPaint = ui.Paint()
        ..color = laneColors[i].withValues(alpha: 0.8)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(rect, borderPaint);
      
      // Lane numarası ve ismi
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i: ${_laneNames[i]}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: laneColors[i],
            backgroundColor: const ui.Color(0xAA000000),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(rect.left + 4, rect.top + 4),
      );
    }
  }
  
  /// Debug mode: Tap edilen lane bilgisini ekranda gösterir
  void _renderDebugTapInfo(ui.Canvas canvas) {
    final String laneText;
    final Color textColor;
    
    if (_lastTappedLane != null) {
      laneText = 'Lane $_lastTappedLane: ${_laneNames[_lastTappedLane!]}';
      textColor = laneColors[_lastTappedLane!];
    } else {
      laneText = 'No lane hit (outside regions)';
      textColor = const Color(0xFFFF4444);
    }
    
    // Üst kısımda bilgi kutusu
    final boxRect = ui.Rect.fromLTWH(10, size.y - 140, size.x - 20, 60);
    final boxPaint = ui.Paint()
      ..color = const ui.Color(0xDD000000)
      ..style = ui.PaintingStyle.fill;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(boxRect, const ui.Radius.circular(8)),
      boxPaint,
    );
    
    // Lane bilgisi
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
    textPainter.paint(
      canvas,
      Offset(boxRect.left + 10, boxRect.top + 8),
    );
    
    // Tap pozisyonu bilgisi
    if (_lastTapPosition != null) {
      final relX = _lastTapPosition!.x / size.x;
      final relY = (_lastTapPosition!.y - _drumKitY) / _drumKitHeight;
      
      final posPainter = TextPainter(
        text: TextSpan(
          text: 'Tap: (${relX.toStringAsFixed(3)}, ${relY.toStringAsFixed(3)}) [normalized]',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFAAAAAA),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      posPainter.layout();
      posPainter.paint(
        canvas,
        Offset(boxRect.left + 10, boxRect.top + 32),
      );
      
      // Tap noktasını işaretle
      final tapMarkerPaint = ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        ui.Offset(_lastTapPosition!.x, _lastTapPosition!.y),
        15,
        tapMarkerPaint,
      );
      
      // Çapraz işaret
      canvas.drawLine(
        ui.Offset(_lastTapPosition!.x - 10, _lastTapPosition!.y - 10),
        ui.Offset(_lastTapPosition!.x + 10, _lastTapPosition!.y + 10),
        tapMarkerPaint,
      );
      canvas.drawLine(
        ui.Offset(_lastTapPosition!.x + 10, _lastTapPosition!.y - 10),
        ui.Offset(_lastTapPosition!.x - 10, _lastTapPosition!.y + 10),
        tapMarkerPaint,
      );
    }
  }

  void _onHit(double distance) {
    int points;
    String rating;
    final isPerfect = distance < 12;

    if (isPerfect) {
      points = 100;
      rating = 'PERFECT!';
      _perfectStreak++;
      // 5 perfect = 1 shield
      if (_perfectStreak >= 5) {
        _shield = 1;
        _perfectStreak = 0;
        _comboText?.text = '🛡️ SHIELD!';
      }
    } else if (distance < 25) {
      points = 75;
      rating = 'GREAT!';
      _perfectStreak = 0;
    } else if (distance < 40) {
      points = 50;
      rating = 'GOOD';
      _perfectStreak = 0;
    } else {
      points = 25;
      rating = 'OK';
      _perfectStreak = 0;
    }

    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;

    final comboBonus = (_combo ~/ 10) * 10;
    
    // Fever multiplier
    final feverMult = (_feverTimer > 0) ? 2 : 1;
    _score += (points + comboBonus) * feverMult;

    // Her 20 combo'da fever mode
    if (_combo > 0 && _combo % 20 == 0) {
      _feverTimer = 4.0;
    }

    _gameScoreText?.text = 'Skor: $_score';
    if (_shield > 0 && !rating.contains('SHIELD')) {
      _comboText?.text = _combo > 1 ? '$_combo Combo! $rating 🛡️' : '$rating 🛡️';
    } else {
      _comboText?.text = _combo > 1 ? '$_combo Combo! $rating' : rating;
    }
  }

  void _onMiss() {
    // Shield varsa combo kırılmaz
    if (_shield > 0) {
      _shield = 0;
      _comboText?.text = '🛡️ SAVE!';
      return;
    }
    _combo = 0;
    _perfectStreak = 0;
    _comboText?.text = 'MISS!';
  }

  void _endGame() {
    if (_score > _highScore) {
      _highScore = _score;
      LocalStore.setHighScore(_selectedDifficulty, _highScore);
    }

    // Daily challenge best
    if (_isDailyChallenge) {
      final best = LocalStore.dailyBest(_selectedDifficulty);
      if (_score > best) {
        LocalStore.setDailyBest(_selectedDifficulty, _score);
      }
    }

    _gameState = GameState.gameOver;
    _buildGameOverUI(size);
  }

  @override
  void render(ui.Canvas canvas) {
    // Arka plan
    canvas.drawColor(const ui.Color(0xFF0A0A15), ui.BlendMode.src);

    if (_gameState == GameState.playing) {
      _renderGameBackground(canvas);
    } else if (_gameState == GameState.menu) {
      _renderMenuBackground(canvas);
    }

    super.render(canvas);
  }

  void _renderMenuBackground(ui.Canvas canvas) {
    // Dekoratif daireler
    final decorPaint = ui.Paint()..color = const ui.Color(0xFF1A1A2E);
    for (int i = 0; i < laneCount; i++) {
      final x = (i + 0.5) * (size.x / laneCount);
      canvas.drawCircle(ui.Offset(x, size.y - 50), 20, decorPaint);
    }
  }

  void _renderGameBackground(ui.Canvas canvas) {
    // Debug mode: Drum bölgelerini sürekli outline olarak çiz
    if (debugMode) {
      _renderDebugDrumRegions(canvas);
    }
    
    // Drum bölgelerinin flash efektleri
    for (int i = 0; i < _drumRegions.length; i++) {
      if (_drumFlashTimers[i] > 0) {
        final region = _drumRegions[i];
        final flashPaint = ui.Paint()
          ..color = laneColors[i].withValues(alpha: _drumFlashTimers[i] * 3)
          ..style = ui.PaintingStyle.fill;
        
        final rect = ui.Rect.fromLTWH(
          region[0] * size.x,
          _drumKitY + region[2] * _drumKitHeight,
          (region[1] - region[0]) * size.x,
          (region[3] - region[2]) * _drumKitHeight,
        );
        canvas.drawRect(rect, flashPaint);
      }
    }
    
    // Debug mode: Tap edilen lane'i göster
    if (debugMode && _lastTappedLane != null) {
      _renderDebugTapInfo(canvas);
    }
    
    // Hit zone çizgisi (drum kit üstünde)
    final hitLinePaint = ui.Paint()
      ..color = const ui.Color(0xFF333355)
      ..strokeWidth = 2;
    canvas.drawLine(
      ui.Offset(0, _hitZoneY),
      ui.Offset(size.x, _hitZoneY),
      hitLinePaint,
    );

    // Süre barı
    final progress = 1 - (_gameTime / gameDuration);
    final barWidth = size.x * 0.6;
    final barX = (size.x - barWidth) / 2;

    final barBgPaint = ui.Paint()..color = const ui.Color(0xFF222233);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(barX, 55, barWidth, 8),
        const ui.Radius.circular(4),
      ),
      barBgPaint,
    );

    final barFgPaint = ui.Paint()
      ..color = progress > 0.3
          ? const ui.Color(0xFF4ECDC4)
          : const ui.Color(0xFFFF6B6B);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(barX, 55, barWidth * progress, 8),
        const ui.Radius.circular(4),
      ),
      barFgPaint,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (_gameState == GameState.playing) {
      final tapX = event.localPosition.x;
      final tapY = event.localPosition.y;
      
      // Debug mode için tap pozisyonunu kaydet
      if (debugMode) {
        _lastTapPosition = Vector2(tapX, tapY);
      }
      
      // Drum kit alanında mı kontrol et
      if (tapY >= _drumKitY) {
        // Hangi drum bölgesine basıldı?
        final relX = tapX / size.x;
        final relY = (tapY - _drumKitY) / _drumKitHeight;
        
        int? hitLane;
        for (int i = 0; i < _drumRegions.length; i++) {
          final region = _drumRegions[i];
          if (relX >= region[0] && relX <= region[1] &&
              relY >= region[2] && relY <= region[3]) {
            hitLane = i;
            break;
          }
        }
        
        // Debug mode: hangi lane'e basıldığını kaydet
        if (debugMode) {
          _lastTappedLane = hitLane;
          _debugLaneShowTimer = 1.5; // 1.5 saniye göster
        }
        
        if (hitLane != null) {
          // Önce nota var mı kontrol et
          final hasNote = _checkAndHitNote(hitLane);
          
          // Nota yoksa bile drum sesini çal (ama nota varsa zaten _onLaneTap içinde çalıyor)
          if (!hasNote) {
            DrumSfx.playLane(hitLane);
          }
          _drumFlashTimers[hitLane] = 0.15;
        }
      } else {
        // Drum kit dışında - eski lane sistemi
        final laneIndex = (tapX / _laneWidth).floor().clamp(0, laneCount - 1);
        _checkAndHitNote(laneIndex);
      }
    }
  }
  
  /// Nota kontrolü yapar ve vurursa true döner
  bool _checkAndHitNote(int laneIndex) {
    Note? closestNote;
    double closestDistance = double.infinity;

    for (final note in _activeNotes) {
      if (note.laneIndex == laneIndex && !note.isHit && !note.isMissed) {
        final distance = (note.position.y - _hitZoneY).abs();
        if (distance < closestDistance && distance < 55) {
          closestDistance = distance;
          closestNote = note;
        }
      }
    }

    if (closestNote != null) {
      closestNote.isHit = true;
      DrumSfx.playLane(laneIndex);
      _onHit(closestDistance);
      _drumFlashTimers[laneIndex] = 0.15;
      _activeNotes.remove(closestNote);
      closestNote.removeFromParent();
      return true;
    }
    return false;
  }
  
  // Drum bölgesinin merkez X koordinatını hesapla
  double _getDrumRegionCenterX(int laneIndex) {
    if (laneIndex < 0 || laneIndex >= _drumRegions.length) return size.x / 2;
    final region = _drumRegions[laneIndex];
    return ((region[0] + region[1]) / 2) * size.x;
  }
}

/// Menü butonu
class MenuButton extends PositionComponent with TapCallbacks {
  MenuButton({
    required this.label,
    required Vector2 size,
    required Vector2 position,
    required this.color,
    required this.onPressed,
    this.isSelected = false,
  }) {
    this.size = size;
    this.position = position;
    anchor = Anchor.topCenter;
  }

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  void render(ui.Canvas canvas) {
    final bgColor = isSelected ? color.withValues(alpha: 0.3) : const ui.Color(0xFF1B1B24);
    final borderColor = isSelected ? color : const ui.Color(0xFF2A2A34);

    // Arka plan
    final bgPaint = ui.Paint()..color = bgColor;
    final rect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      const ui.Radius.circular(12),
    );
    canvas.drawRRect(rect, bgPaint);

    // Kenarlık
    final borderPaint = ui.Paint()
      ..color = borderColor
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rect, borderPaint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isSelected ? color : const Color(0xFFFFFFFF),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    onPressed();
  }
}

/// Düşen nota
class Note extends CircleComponent {
  Note({
    required this.laneIndex,
    required Vector2 position,
    required double radius,
    required Color color,
    required this.speed,
  }) : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
          paint: ui.Paint()..color = color,
        );

  final int laneIndex;
  final double speed;
  bool isHit = false;
  bool isMissed = false;

  @override
  void render(ui.Canvas canvas) {
    // Glow efekti
    final glowPaint = ui.Paint()
      ..color = paint.color.withValues(alpha: 0.25)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    canvas.drawCircle(ui.Offset.zero, radius * 1.4, glowPaint);

    // Ana daire
    super.render(canvas);

    // İç parlak merkez
    final innerPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(ui.Offset.zero, radius * 0.25, innerPaint);
  }
}
