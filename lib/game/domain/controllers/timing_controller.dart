import 'package:drumly/game/domain/entities/hit_result.dart';
import 'package:drumly/game/domain/entities/hit_windows.dart';

class TimingController {

  TimingController({required this.hitWindows});
  /// Hit windows (timing pencereleri).
  final HitWindows hitWindows;

  /// Timing offset'e göre hit quality belirler.
  ///
  /// [timingOffset] Ideal zamandan sapma (ms) - pozitif = geç, negatif = erken.
  ///
  /// Returns: HitQuality (perfect/good/miss)
  HitQuality evaluateHitQuality(double timingOffset) {
    final absOffset = timingOffset.abs();

    if (absOffset <= hitWindows.perfectMs) {
      return HitQuality.perfect;
    } else if (absOffset <= hitWindows.goodMs) {
      return HitQuality.good;
    } else {
      return HitQuality.miss;
    }
  }

  /// İki zaman arasındaki timing offset'i hesaplar.
  ///
  /// [noteTime] Notanın ideal vuruş zamanı.
  /// [tapTime] Kullanıcının tap yaptığı zaman.
  ///
  /// Returns: Offset (ms) - 0 = perfect, pozitif = geç, negatif = erken.
  double calculateTimingOffset(double noteTime, double tapTime) => (tapTime - noteTime) * 1000;

  /// Notanın hit window içinde olup olmadığını kontrol eder.
  ///
  /// [noteTime] Notanın ideal vuruş zamanı.
  /// [currentTime] Şu anki oyun zamanı.
  ///
  /// Returns: true ise nota hit edilebilir.
  bool isInHitWindow(double noteTime, double currentTime) {
    final offset = calculateTimingOffset(noteTime, currentTime);
    return offset.abs() <= hitWindows.goodMs;
  }

  /// Notanın miss olup olmadığını kontrol eder (geç kalmış).
  ///
  /// [noteTime] Notanın ideal vuruş zamanı.
  /// [currentTime] Şu anki oyun zamanı.
  ///
  /// Returns: true ise nota kaçırılmış (geçmiş).
  bool isMissed(double noteTime, double currentTime) {
    final offset = calculateTimingOffset(noteTime, currentTime);
    return offset > hitWindows.goodMs;
  }

  /// HitResult oluşturur (timing evaluation ile).
  HitResult createHitResult({
    required int lane,
    required double noteTime,
    required double tapTime,
  }) {
    final timingOffset = calculateTimingOffset(noteTime, tapTime);
    final quality = evaluateHitQuality(timingOffset);

    if (quality == HitQuality.miss) {
      return HitResult.miss(lane: lane, hitTime: tapTime);
    } else if (quality == HitQuality.perfect) {
      return HitResult.perfect(
        lane: lane,
        timingOffset: timingOffset,
        hitTime: tapTime,
      );
    } else {
      return HitResult.good(
        lane: lane,
        timingOffset: timingOffset,
        hitTime: tapTime,
      );
    }
  }
}
