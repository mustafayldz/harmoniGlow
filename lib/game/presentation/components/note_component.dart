import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// ============================================================================
/// NOTE COMPONENT - Ekranda düşen nota diski
/// ============================================================================
///
/// Bu component, oyuncunun vurması gereken düşen notaları temsil eder.
/// Her nota belirli bir lane'e ait renkli bir daire olarak görünür.
///
/// ## Nota Yaşam Döngüsü
///
/// ```
/// 1. SPAWN: Ekranın üstünde (-30y) oluşturulur
/// 2. DÜŞME: Her frame'de position.y += speed * dt
/// 3. HIT ZONE: hitZoneY'ye ulaştığında timing değerlendirilir
/// 4. SONLANMA:
///    - isHit = true: Oyuncu vurdu, component kaldırılır
///    - isMissed = true: Oyuncu kaçırdı, component kaldırılır
///    - position.y > screenHeight + 50: Ekrandan çıktı, kaldırılır
/// ```
///
/// ## Görsel Yapı
///
/// ```
///      ╭─────────────╮
///     ╱   ░░░░░░░░░   ╲   <- Glow efekti (performanceMode=false)
///    │   ╭───────╮    │
///    │   │       │    │   <- Ana daire (lane rengi)
///    │   │   ●   │    │   <- Beyaz merkez nokta
///    │   │       │    │
///    │   ╰───────╯    │
///     ╲   ░░░░░░░░░   ╱
///      ╰─────────────╯
/// ```
///
/// ## Örnek Kullanım
///
/// ```dart
/// final note = NoteComponent(
///   laneIndex: 5,              // Kick drum
///   hitTime: 5.0,              // 5. saniyede vurulmalı
///   position: Vector2(200, -30),
///   radius: 25,
///   color: Color(0xFF88D8B0),  // Yeşil
///   speed: 220,
/// );
/// add(note);
/// ```
/// ============================================================================
class NoteComponent extends CircleComponent {
  /// Yeni bir nota component'i oluşturur.
  ///
  /// [laneIndex] Bu notanın ait olduğu lane (0-7).
  /// [hitTime] Notanın hit zone'a ulaşma zamanı (saniye).
  /// [position] Notanın başlangıç pozisyonu.
  /// [radius] Notanın yarıçapı (piksel).
  /// [color] Notanın rengi (lane rengine göre).
  /// [speed] Notanın düşme hızı (piksel/saniye).
  /// [performanceMode] true ise glow efekti devre dışı.
  NoteComponent({
    required this.laneIndex,
    required this.hitTime,
    required Vector2 position,
    required double radius,
    required Color color,
    required this.hitZoneY,
    required this.speed,
    this.performanceMode = false,
    this.minScale = 0.35,
  }) : spawnY = position.y,
       super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
          paint: ui.Paint()..color = color,
        );

  /// Bu notanın ait olduğu lane (enstrüman) numarası.
  ///
  /// | Lane | Enstrüman    | Renk       |
  /// |------|--------------|------------|
  /// | 0    | Close Hi-Hat | Kırmızı    |
  /// | 1    | Open Hi-Hat  | Sarı       |
  /// | 2    | Crash        | Turkuaz    |
  /// | 3    | Ride         | Açık Yeşil |
  /// | 4    | Snare        | Mint       |
  /// | 5    | Kick         | Yeşil      |
  /// | 6    | Tom 1        | Mor        |
  /// | 7    | Floor Tom    | Pembe      |
  final int laneIndex;

  /// Notanın hit zone'a ulaşması gereken oyun zamanı (saniye).
  ///
  /// Oyuncunun tam bu anda dokunması "Perfect" timing verir.
  /// Timing judgement için game logic bu değeri kullanır.
  final double hitTime;

  /// Notanın düşme hızı (piksel/saniye).
  ///
  /// Her frame'de position.y += speed * dt formülüyle güncellenir.
  /// Zorluk seviyesine göre değişir:
  /// - Easy: 180 px/s
  /// - Medium: 220 px/s
  /// - Hard: 260 px/s
  final double speed;

  /// Notanın spawn olduğu Y koordinatı.
  final double spawnY;

  /// Hit zone Y koordinatı.
  final double hitZoneY;

  /// Minimum ölçek (spawn anında).
  final double minScale;

  /// Performans modu aktif mi?
  ///
  /// true ise glow efekti çizilmez, FPS artar.
  /// Düşük performanslı cihazlar için önerilir.
  final bool performanceMode;

  /// Nota oyuncu tarafından vuruldu mu?
  ///
  /// true ise nota artık işlenmez ve kaldırılmaya hazırdır.
  bool isHit = false;

  /// Hit sonrası notanın ekranda kalacağı süre (saniye).
  double _hitDisplayRemaining = 0.0;

  /// Nota kaçırıldı mı (miss)?
  ///
  /// true ise nota artık işlenmez ve kaldırılmaya hazırdır.
  /// Hit window'u geçtikten sonra true olur.
  bool isMissed = false;

  @override
  void update(double dt) {
    super.update(dt);

    // Hit olmuş nota kısa süre yeşil kalsın ve sonra kaldır.
    if (isHit) {
      if (_hitDisplayRemaining > 0) {
        _hitDisplayRemaining -= dt;
        if (_hitDisplayRemaining <= 0) {
          removeFromParent();
        }
      }
      return;
    }

    final total = (hitZoneY - spawnY).abs();
    if (total <= 0.1) return;

    final progress = ((position.y - spawnY) / (hitZoneY - spawnY))
        .clamp(0.0, 1.0);
    final s = (minScale + (1.0 - minScale) * progress).clamp(0.0, 1.2);
    scale = Vector2.all(s);
  }

  /// Notayı hit olarak işaretler ve kısa süre yeşil gösterir.
  void markHit({
    Color hitColor = const Color(0xFF10B981),
    double displayDuration = 0.12,
  }) {
    isHit = true;
    _hitDisplayRemaining = displayDuration;
    paint.color = hitColor;
  }

  // ===========================================================================
  // RENDER - Notayı çizer
  // ===========================================================================

  @override
  void render(ui.Canvas canvas) {
    // -------------------------------------------------------------------------
    // GLOW EFEKTİ: Performans modu kapalıysa çiz
    // -------------------------------------------------------------------------
    // Glow, notanın arkasında bulanık bir hale oluşturur.
    // MaskFilter.blur ile gaussian blur efekti sağlanır.
    if (!performanceMode) {
      canvas.drawCircle(
        ui.Offset.zero,
        radius * 1.4, // Glow %40 daha büyük
        ui.Paint()
          ..color = paint.color.withValues(alpha: 0.25) // %25 opaklık
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
    }

    // -------------------------------------------------------------------------
    // ANA DAİRE: CircleComponent'in varsayılan render'ı
    // -------------------------------------------------------------------------
    // Lane renginde dolu daire çizer.
    super.render(canvas);

    // -------------------------------------------------------------------------
    // MERKEZ NOKTA: Beyaz vurgu noktası
    // -------------------------------------------------------------------------
    // Notanın merkezinde küçük beyaz bir nokta, görsel derinlik sağlar.
    canvas.drawCircle(
      ui.Offset.zero,
      radius * 0.25, // Ana çapın %25'i
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  }

  @override
  String toString() =>
      'Note(lane: $laneIndex, hitTime: ${hitTime.toStringAsFixed(2)}s, '
      'y: ${position.y.toStringAsFixed(0)}, hit: $isHit, missed: $isMissed)';
}
