import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// ModernBackgroundComponent - Animasyonlu gradient arka plan.
class ModernBackgroundComponent extends Component {

  ModernBackgroundComponent({required this.screenSize});
  final ui.Size screenSize;
  double _animationPhase = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _animationPhase += dt * 0.3; // Yavaş animasyon
    if (_animationPhase > 1.0) _animationPhase -= 1.0;
  }

  @override
  void render(ui.Canvas canvas) {
    // Animated gradient colors
    final color1 = ui.Color.lerp(
      const ui.Color(0xFF1A1A2E),
      const ui.Color(0xFF16213E),
      _animationPhase,
    )!;
    
    final color2 = ui.Color.lerp(
      const ui.Color(0xFF0F3460),
      const ui.Color(0xFF533483),
      _animationPhase,
    )!;

    final gradient = ui.Gradient.linear(
      const ui.Offset(0, 0),
      ui.Offset(screenSize.width, screenSize.height),
      [color1, color2],
      [0.0, 1.0],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, screenSize.width, screenSize.height),
      paint,
    );
  }
}

/// ModernScoreUI - Modern görünümlü skor gösterimi.
class ModernScoreUI extends PositionComponent {

  ModernScoreUI({required super.position, required super.size});
  int _score = 0;
  int _combo = 0;
  double _comboScale = 1.0;
  String _hitFeedback = '';
  double _feedbackOpacity = 0.0;

  void updateScore(int score, int combo) {
    _score = score;
    if (combo > _combo) {
      _comboScale = 1.3; // Combo arttığında büyüt
    }
    _combo = combo;
  }

  void showHitFeedback(String feedback) {
    _hitFeedback = feedback;
    _feedbackOpacity = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Combo scale animasyonu
    if (_comboScale > 1.0) {
      _comboScale -= dt * 2.0;
      if (_comboScale < 1.0) _comboScale = 1.0;
    }
    
    // Feedback fade out
    if (_feedbackOpacity > 0) {
      _feedbackOpacity -= dt * 2.0;
      if (_feedbackOpacity < 0) _feedbackOpacity = 0;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // Score text
    final scorePainter = TextPainter(
      text: TextSpan(
        text: '$_score',
        style: const TextStyle(
          color: ui.Color(0xFFFFFFFF),
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    scorePainter.paint(canvas, const Offset(20, 20));

    // Combo text (if > 0)
    if (_combo > 0) {
      final comboPainter = TextPainter(
        text: TextSpan(
          text: 'COMBO x$_combo',
          style: TextStyle(
            color: _combo >= 50
                ? const ui.Color(0xFFFFC107) // Gold for high combo
                : const ui.Color(0xFF2196F3), // Blue
            fontSize: 32 * _comboScale,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      comboPainter.paint(
        canvas,
        Offset(20, 80 - (comboPainter.height * (_comboScale - 1.0) / 2)),
      );
    }

    // Hit feedback (PERFECT, GOOD, etc.)
    if (_feedbackOpacity > 0) {
      final feedbackColor = switch (_hitFeedback) {
        'PERFECT' => const ui.Color(0xFF4CAF50),
        'GOOD' => const ui.Color(0xFF2196F3),
        'MISS' => const ui.Color(0xFFF44336),
        _ => const ui.Color(0xFFFFFFFF),
      };

      final feedbackPainter = TextPainter(
        text: TextSpan(
          text: _hitFeedback,
          style: TextStyle(
            color: feedbackColor.withValues(alpha: _feedbackOpacity),
            fontSize: 36,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: ui.Color.fromARGB(
                  (255 * _feedbackOpacity).toInt(),
                  0,
                  0,
                  0,
                ),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final centerX = (size.x - feedbackPainter.width) / 2;
      feedbackPainter.paint(canvas, Offset(centerX, 150));
    }
  }
}

/// Hit zone indicator - Modern görünümlü çizgi.
class HitZoneIndicator extends PositionComponent {

  HitZoneIndicator({
    required this.screenWidth,
    required this.lineY,
  }) : super(
          position: Vector2(0, lineY),
          size: Vector2(screenWidth, 4),
        );
  final double screenWidth;
  final double lineY;

  @override
  void render(ui.Canvas canvas) {
    // Gradient line
    final gradient = ui.Gradient.linear(
      const ui.Offset(0, 0),
      ui.Offset(size.x, 0),
      [
        const ui.Color(0x00FFFFFF),
        const ui.Color(0xFFFFFFFF),
        const ui.Color(0x00FFFFFF),
      ],
      [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const ui.Offset(0, 2),
      ui.Offset(size.x, 2),
      paint,
    );
  }
}
