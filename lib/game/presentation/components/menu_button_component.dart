import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

/// ============================================================================
/// MENU BUTTON COMPONENT - Oyun içi menü butonu
/// ============================================================================
///
/// Bu component, Flame oyun motoru içinde kullanılan özel bir buton widget'ıdır.
/// Ana menü ve game over ekranlarında kullanılır.
///
/// ## Görsel Özellikler
///
/// - Yuvarlatılmış köşeler (12px radius)
/// - Seçili durumda renk değişimi
/// - Hover efekti (mobilde dokunma feedback'i)
///
/// ## Örnek Kullanım
///
/// ```dart
/// final button = MenuButtonComponent(
///   label: 'BAŞLA',
///   size: Vector2(200, 50),
///   position: Vector2(100, 200),
///   color: Color(0xFF4ECDC4),
///   onPressed: () => startGame(),
/// );
/// add(button);
/// ```
/// ============================================================================
class MenuButtonComponent extends PositionComponent with TapCallbacks {
  /// Yeni bir menü butonu oluşturur.
  ///
  /// [label] Buton üzerinde gösterilecek metin.
  /// [size] Butonun boyutu (genişlik x yükseklik).
  /// [position] Butonun ekrandaki konumu.
  /// [color] Butonun vurgu rengi (border ve seçili durumda).
  /// [onPressed] Butona tıklandığında çağrılacak callback.
  /// [isSelected] Butonun seçili durumda olup olmadığı.
  MenuButtonComponent({
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

  /// Buton üzerinde gösterilecek metin.
  final String label;

  /// Butonun vurgu rengi.
  ///
  /// Normal durumda border rengi olarak kullanılır.
  /// Seçili durumda arka plan rengi de bu renge dönüşür (alfa ile).
  final Color color;

  /// Butona tıklandığında çağrılacak callback fonksiyonu.
  final VoidCallback onPressed;

  /// Butonun seçili durumda olup olmadığı.
  ///
  /// true ise:
  /// - Arka plan rengi: color.withAlpha(0.3)
  /// - Border rengi: color
  /// - Metin rengi: color
  ///
  /// false ise:
  /// - Arka plan rengi: koyu gri (#1B1B24)
  /// - Border rengi: orta gri (#2A2A34)
  /// - Metin rengi: beyaz
  final bool isSelected;

  // ===========================================================================
  // RENDER - Butonu çizer
  // ===========================================================================

  @override
  void render(ui.Canvas canvas) {
    // Arka plan ve border renklerini seçili duruma göre belirle
    final backgroundColor =
        isSelected ? color.withValues(alpha: 0.3) : const ui.Color(0xFF1B1B24);
    final borderColor = isSelected ? color : const ui.Color(0xFF2A2A34);

    // Yuvarlatılmış dikdörtgen oluştur
    final roundedRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      const ui.Radius.circular(12),
    );

    // Arka planı çiz
    canvas.drawRRect(
      roundedRect,
      ui.Paint()..color = backgroundColor,
    );

    // Border'ı çiz
    canvas.drawRRect(
      roundedRect,
      ui.Paint()
        ..color = borderColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Metin rengini seçili duruma göre belirle
    final textColor = isSelected ? color : const Color(0xFFFFFFFF);

    // Metni çiz (ortalanmış)
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Metni butonun ortasına yerleştir
    final textX = (size.x - textPainter.width) / 2;
    final textY = (size.y - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  // ===========================================================================
  // TAP CALLBACK - Dokunma olayını işler
  // ===========================================================================

  @override
  void onTapUp(TapUpEvent event) {
    onPressed();
  }
}
