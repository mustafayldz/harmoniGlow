import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

enum Difficulty { easy, medium, hard }
enum GameState { menu, playing, gameOver }

/// Ana oyun sınıfı - Menü ve DrumHero oyununu içerir
class DrumHeroGame extends FlameGame with TapCallbacks {
  DrumHeroGame({
    this.onExit,
  });

  final VoidCallback? onExit;

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
  late double _spawnInterval;

  // Menü bileşenleri
  final List<Component> _menuComponents = [];
  
  // Oyun bileşenleri
  final List<HitZone> _hitZones = [];
  final List<Note> _activeNotes = [];
  TextComponent? _gameScoreText;
  TextComponent? _comboText;

  // Zamanlama
  double _timeSinceLastSpawn = 0;
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
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (size.x <= 1 || size.y <= 1) return;

    _laneWidth = size.x / laneCount;
    _hitZoneY = size.y - 120;

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
    const btnH = 54.0;
    const gap = 14.0;

    // Başlık
    final title = TextComponent(
      text: 'DRUM HERO',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 60),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );

    // Alt başlık
    final subtitle = TextComponent(
      text: 'Ritmi Yakala!',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 115),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFF8A7CFF),
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    // High Score
    final highScoreText = TextComponent(
      text: 'En Yüksek Skor: $_highScore',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFFBDBDBD),
        ),
      ),
    );

    // Başla butonu
    final startButton = MenuButton(
      label: '▶  BAŞLA',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 210),
      color: const Color(0xFF4ECDC4),
      onPressed: _startGame,
    );

    // Seviye başlığı
    final difficultyLabel = TextComponent(
      text: 'Zorluk Seviyesi',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 290),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFFBDBDBD),
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // Zorluk butonları
    final easyButton = MenuButton(
      label: 'KOLAY',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 330),
      color: const Color(0xFF22C55E),
      isSelected: _selectedDifficulty == Difficulty.easy,
      onPressed: () => _setDifficulty(Difficulty.easy),
    );

    final mediumButton = MenuButton(
      label: 'ORTA',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 330 + btnH + gap),
      color: const Color(0xFFFFE66D),
      isSelected: _selectedDifficulty == Difficulty.medium,
      onPressed: () => _setDifficulty(Difficulty.medium),
    );

    final hardButton = MenuButton(
      label: 'ZOR',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 330 + 2 * (btnH + gap)),
      color: const Color(0xFFFF6B6B),
      isSelected: _selectedDifficulty == Difficulty.hard,
      onPressed: () => _setDifficulty(Difficulty.hard),
    );

    // Nasıl oynanır
    final howToPlay = TextComponent(
      text: '🎵 Notalar düştüğünde dairelere dokun!',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, screenSize.y - 60),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF666666),
        ),
      ),
    );

    _menuComponents.addAll([
      title, subtitle, highScoreText, startButton,
      difficultyLabel, easyButton, mediumButton, hardButton, howToPlay,
    ]);

    for (final comp in _menuComponents) {
      add(comp);
    }
  }

  void _setDifficulty(Difficulty d) {
    _selectedDifficulty = d;
    _buildMenu(size);
  }

  void _startGame() {
    _gameState = GameState.playing;
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _gameTime = 0;
    _timeSinceLastSpawn = 0;

    // Zorluk ayarları
    switch (_selectedDifficulty) {
      case Difficulty.easy:
        _noteSpeed = 180;
        _spawnInterval = 1.4;
        break;
      case Difficulty.medium:
        _noteSpeed = 260;
        _spawnInterval = 0.9;
        break;
      case Difficulty.hard:
        _noteSpeed = 350;
        _spawnInterval = 0.55;
        break;
    }

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
    for (final h in _hitZones) {
      h.removeFromParent();
    }
    _hitZones.clear();
    for (final n in _activeNotes) {
      n.removeFromParent();
    }
    _activeNotes.clear();
    _gameScoreText?.removeFromParent();
    _comboText?.removeFromParent();

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

    // Hit zone'ları oluştur
    for (int i = 0; i < laneCount; i++) {
      final hitZone = HitZone(
        laneIndex: i,
        position: Vector2(i * _laneWidth + _laneWidth / 2, _hitZoneY),
        radius: _laneWidth * 0.38,
        color: laneColors[i],
      );
      _hitZones.add(hitZone);
      add(hitZone);
    }
  }

  void _buildGameOverUI(Vector2 screenSize) {
    // Önceki bileşenleri temizle
    for (final h in _hitZones) {
      h.removeFromParent();
    }
    _hitZones.clear();
    for (final n in _activeNotes) {
      n.removeFromParent();
    }
    _activeNotes.clear();
    _gameScoreText?.removeFromParent();
    _comboText?.removeFromParent();
    for (final comp in _menuComponents) {
      comp.removeFromParent();
    }
    _menuComponents.clear();

    final centerX = screenSize.x / 2;
    final btnW = (screenSize.x * 0.72).clamp(220.0, 420.0);
    const btnH = 54.0;

    final gameOverTitle = TextComponent(
      text: 'OYUN BİTTİ!',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );

    final finalScore = TextComponent(
      text: 'Skor: $_score',
      anchor: Anchor.topCenter,
      position: Vector2(centerX, 170),
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
      position: Vector2(centerX, 220),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Color(0xFFFFD700),
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
      position: Vector2(centerX, 270),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: ratingColor,
        ),
      ),
    );

    final playAgainButton = MenuButton(
      label: '🔄  TEKRAR OYNA',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 350),
      color: const Color(0xFF4ECDC4),
      onPressed: _startGame,
    );

    final menuButton = MenuButton(
      label: '🏠  ANA MENÜ',
      size: Vector2(btnW, btnH),
      position: Vector2(centerX, 420),
      color: const Color(0xFF666666),
      onPressed: _goToMenu,
    );

    _menuComponents.addAll([
      gameOverTitle, finalScore, comboInfo, rating,
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
    _timeSinceLastSpawn += dt;

    // Oyun süresi kontrolü
    if (_gameTime >= gameDuration) {
      _endGame();
      return;
    }

    // Yeni nota spawn et
    if (_timeSinceLastSpawn >= _spawnInterval) {
      _spawnNote();
      _timeSinceLastSpawn = 0;
    }

    // Notaları güncelle
    _updateNotes(dt);
  }

  void _spawnNote() {
    final random = Random();
    final notesToSpawn = random.nextInt(3) + 1;
    final usedLanes = <int>{};

    for (int i = 0; i < notesToSpawn; i++) {
      int lane;
      do {
        lane = random.nextInt(laneCount);
      } while (usedLanes.contains(lane));
      usedLanes.add(lane);

      final note = Note(
        laneIndex: lane,
        position: Vector2(lane * _laneWidth + _laneWidth / 2, -30),
        radius: _laneWidth * 0.32,
        color: laneColors[lane],
        speed: _noteSpeed,
      );
      _activeNotes.add(note);
      add(note);
    }
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

  void _onLaneTap(int laneIndex) {
    if (_gameState != GameState.playing) return;

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
      _onHit(closestDistance);
      _hitZones[laneIndex].flash();
      _activeNotes.remove(closestNote);
      closestNote.removeFromParent();
    }
  }

  void _onHit(double distance) {
    int points;
    String rating;

    if (distance < 12) {
      points = 100;
      rating = 'PERFECT!';
    } else if (distance < 25) {
      points = 75;
      rating = 'GREAT!';
    } else if (distance < 40) {
      points = 50;
      rating = 'GOOD';
    } else {
      points = 25;
      rating = 'OK';
    }

    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;

    final comboBonus = (_combo ~/ 10) * 10;
    _score += points + comboBonus;

    _gameScoreText?.text = 'Skor: $_score';
    _comboText?.text = _combo > 1 ? '$_combo Combo! $rating' : rating;
  }

  void _onMiss() {
    _combo = 0;
    _comboText?.text = 'MISS!';
  }

  void _endGame() {
    if (_score > _highScore) {
      _highScore = _score;
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
    // Lane çizgileri
    final lanePaint = ui.Paint()
      ..color = const ui.Color(0xFF151525)
      ..strokeWidth = 1;

    for (int i = 1; i < laneCount; i++) {
      final x = i * _laneWidth;
      canvas.drawLine(
        ui.Offset(x, 0),
        ui.Offset(x, size.y),
        lanePaint,
      );
    }

    // Hit zone çizgisi
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
      final laneIndex = (tapX / _laneWidth).floor().clamp(0, laneCount - 1);
      _onLaneTap(laneIndex);
    }
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

/// Alt kısımdaki vuruş bölgesi
class HitZone extends CircleComponent {
  HitZone({
    required this.laneIndex,
    required Vector2 position,
    required double radius,
    required Color color,
  }) : _baseColor = color,
       super(
         position: position,
         radius: radius,
         anchor: Anchor.center,
       );

  final int laneIndex;
  final Color _baseColor;
  double _flashTimer = 0;

  void flash() {
    _flashTimer = 0.15;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) {
      _flashTimer -= dt;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final isFlashing = _flashTimer > 0;

    // Dış halka
    final ringPaint = ui.Paint()
      ..color = isFlashing ? _baseColor : _baseColor.withValues(alpha: 0.35)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = isFlashing ? 4 : 2.5;
    canvas.drawCircle(ui.Offset.zero, radius, ringPaint);

    // Flash efekti
    if (isFlashing) {
      final flashPaint = ui.Paint()
        ..color = _baseColor.withValues(alpha: 0.4)
        ..style = ui.PaintingStyle.fill;
      canvas.drawCircle(ui.Offset.zero, radius * 0.85, flashPaint);
    }

    // İç nokta
    final dotPaint = ui.Paint()
      ..color = _baseColor.withValues(alpha: isFlashing ? 1.0 : 0.5)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(ui.Offset.zero, radius * 0.18, dotPaint);
  }
}
