import 'package:drumly/game/core/enums/game_enums.dart';

/// ============================================================================
/// HIT WINDOWS ENTITY - MS bazlı timing judgement pencereleri
/// ============================================================================
///
/// Bu sınıf, oyuncunun bir notaya ne kadar doğru zamanda vurduğunu
/// değerlendirmek için kullanılan zaman pencerelerini tanımlar.
///
/// ## Judgement Sistemi
///
/// Oyuncu bir nota için dokunduğunda, dokunma anı ile notanın hit zamanı
/// arasındaki fark (milisaniye cinsinden) kontrol edilir:
///
/// ```
/// |timeDiff| <= perfectMs  -> PERFECT (100 puan)
/// |timeDiff| <= greatMs    -> GREAT   (75 puan)
/// |timeDiff| <= goodMs     -> GOOD    (50 puan)
/// |timeDiff| <= missMs     -> OK      (25 puan)
/// |timeDiff| > missMs      -> MISS    (0 puan, combo reset)
/// ```
///
/// ## Zorluk Seviyelerine Göre Pencereler
///
/// | Seviye | Perfect | Great | Good  | Miss  |
/// |--------|---------|-------|-------|-------|
/// | Easy   | ±60ms   | ±110ms| ±160ms| ±200ms|
/// | Medium | ±50ms   | ±95ms | ±140ms| ±175ms|
/// | Hard   | ±40ms   | ±80ms | ±120ms| ±150ms|
///
/// ## Örnek Kullanım
///
/// ```dart
/// final windows = HitWindows.forDifficulty(Difficulty.medium);
/// final timeDiffMs = (gameTime - note.hitTime) * 1000;
///
/// if (timeDiffMs.abs() <= windows.perfectMs) {
///   // PERFECT!
/// }
/// ```
/// ============================================================================
class HitWindows {
  /// Yeni bir hit windows tanımı oluşturur.
  ///
  /// [perfectMs] Perfect judgement için max ms tolerans.
  /// [greatMs] Great judgement için max ms tolerans.
  /// [goodMs] Good judgement için max ms tolerans.
  /// [missMs] Bu değerin üstü MISS sayılır.
  const HitWindows({
    required this.perfectMs,
    required this.greatMs,
    required this.goodMs,
    required this.missMs,
  });

  /// Perfect judgement için maksimum milisaniye toleransı.
  ///
  /// Oyuncunun dokunma zamanı ile notanın hit zamanı arasındaki
  /// fark bu değerden küçükse PERFECT sayılır.
  final double perfectMs;

  /// Great judgement için maksimum milisaniye toleransı.
  ///
  /// Perfect değilse ama bu değerden küçükse GREAT sayılır.
  final double greatMs;

  /// Good judgement için maksimum milisaniye toleransı.
  ///
  /// Great değilse ama bu değerden küçükse GOOD sayılır.
  final double goodMs;

  /// Miss judgement için eşik değeri (milisaniye).
  ///
  /// Bu değerin üstündeki farklarda nota kaçırılmış sayılır.
  /// Good değilse ama bu değerden küçükse OK sayılır.
  /// Bu değerden büyükse MISS.
  final double missMs;

  // ===========================================================================
  // PRESET DEĞERLER - Her zorluk seviyesi için önceden tanımlı pencereler
  // ===========================================================================

  /// Kolay mod için hit pencereleri.
  ///
  /// En geniş tolerans - yeni başlayanlar için ideal.
  /// Perfect bile ±60ms ile kolay yakalanır.
  static const easy = HitWindows(
    perfectMs: 60, // ±60ms = 120ms toplam pencere
    greatMs: 110, // ±110ms
    goodMs: 160, // ±160ms
    missMs: 200, // ±200ms
  );

  /// Orta mod için hit pencereleri.
  ///
  /// Dengeli zorluk - ortalama bir ritim oyunu deneyimi.
  static const medium = HitWindows(
    perfectMs: 50, // ±50ms = 100ms toplam pencere
    greatMs: 95, // ±95ms
    goodMs: 140, // ±140ms
    missMs: 175, // ±175ms
  );

  /// Zor mod için hit pencereleri.
  ///
  /// Dar tolerans - uzman oyuncular için.
  /// Perfect için çok hassas timing gerekir (±40ms).
  static const hard = HitWindows(
    perfectMs: 40, // ±40ms = 80ms toplam pencere
    greatMs: 80, // ±80ms
    goodMs: 120, // ±120ms
    missMs: 150, // ±150ms
  );

  /// Zorluk seviyesine göre uygun hit windows'u döndürür.
  ///
  /// [difficulty] Oyunun zorluk seviyesi.
  /// Returns: İlgili zorluk için HitWindows instance'ı.
  static HitWindows forDifficulty(Difficulty difficulty) =>
      switch (difficulty) {
        Difficulty.easy => easy,
        Difficulty.medium => medium,
        Difficulty.hard => hard,
      };

  /// Verilen zaman farkına göre judgement string'i döndürür.
  ///
  /// [timeDiffMs] Dokunma zamanı ile hit zamanı arasındaki fark (ms).
  /// Returns: 'PERFECT', 'GREAT', 'GOOD' veya 'OK'.
  String judge(double timeDiffMs) {
    final absMs = timeDiffMs.abs();
    if (absMs <= perfectMs) return 'PERFECT';
    if (absMs <= greatMs) return 'GREAT';
    if (absMs <= goodMs) return 'GOOD';
    return 'OK';
  }

  /// Verilen zaman farkının miss sayılıp sayılmadığını kontrol eder.
  ///
  /// [timeDiffMs] Dokunma zamanı ile hit zamanı arasındaki fark (ms).
  /// Returns: Fark missMs'den büyükse `true`.
  bool isMiss(double timeDiffMs) => timeDiffMs.abs() > missMs;

  @override
  String toString() =>
      'HitWindows(perfect: ±${perfectMs}ms, great: ±${greatMs}ms, '
      'good: ±${goodMs}ms, miss: >${missMs}ms)';
}
