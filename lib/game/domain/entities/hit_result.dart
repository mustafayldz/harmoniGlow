enum HitQuality {
  perfect,
  good,
  miss,
}

class HitResult {

  const HitResult({
    required this.lane,
    required this.timingOffset,
    required this.quality,
    required this.hitTime,
    required this.isHit,
  });

  /// Good hit için factory.
  factory HitResult.good({
    required int lane,
    required double timingOffset,
    required double hitTime,
  }) => HitResult(
      lane: lane,
      timingOffset: timingOffset,
      quality: HitQuality.good,
      hitTime: hitTime,
      isHit: true,
    );

  /// Perfect hit için factory.
  factory HitResult.perfect({
    required int lane,
    required double timingOffset,
    required double hitTime,
  }) => HitResult(
      lane: lane,
      timingOffset: timingOffset,
      quality: HitQuality.perfect,
      hitTime: hitTime,
      isHit: true,
    );

  /// Miss durumu için factory.
  factory HitResult.miss({
    required int lane,
    required double hitTime,
  }) => HitResult(
      lane: lane,
      timingOffset: 0,
      quality: HitQuality.miss,
      hitTime: hitTime,
      isHit: false,
    );
  /// Vurulan lane index'i.
  final int lane;

  /// Timing offset (ms) - 0 = perfect timing, +/- = erken/geç.
  final double timingOffset;

  /// Hit kalitesi (perfect/good/miss).
  final HitQuality quality;

  /// Vuruş zamanı (oyun başlangıcından itibaren geçen süre).
  final double hitTime;

  /// Bu vuruş bir nota ile eşleşti mi?
  final bool isHit;

  /// Hit başarılı mı?
  bool get isSuccessful => isHit && quality != HitQuality.miss;

  /// Perfect hit mi?
  bool get isPerfect => quality == HitQuality.perfect;

  /// Good hit mi?
  bool get isGood => quality == HitQuality.good;

  @override
  String toString() => 'HitResult(lane: $lane, quality: $quality, offset: ${timingOffset.toStringAsFixed(2)}ms, time: ${hitTime.toStringAsFixed(2)}s)';
}
