import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

class PauseButtonComponent extends PositionComponent with TapCallbacks {
  PauseButtonComponent({
    required this.onPressed,
    required Vector2 position,
    this.isPaused = false,
  }) {
    this.position = position;
    size = Vector2(44, 44);
    anchor = Anchor.topRight;
    priority = 9999;
  }

  final VoidCallback onPressed;
  bool isPaused;

  void setPaused(bool value) {
    if (isPaused == value) return;
    isPaused = value;
  }

  @override
  void render(ui.Canvas canvas) {
    final bg = ui.Paint()..color = const ui.Color(0xAA000000);
    final border = ui.Paint()
      ..color = const ui.Color(0x33FFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, bg);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, border);

    final iconPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);

    if (isPaused) {
      final path = ui.Path()
        ..moveTo(16, 12)
        ..lineTo(16, 32)
        ..lineTo(30, 22)
        ..close();
      canvas.drawPath(path, iconPaint);
    } else {
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(16, 13, 4, 18),
          const ui.Radius.circular(2),
        ),
        iconPaint,
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(24, 13, 4, 18),
          const ui.Radius.circular(2),
        ),
        iconPaint,
      );
    }
  }

  @override
  void onTapUp(TapUpEvent event) => onPressed();
}
