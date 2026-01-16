/// ============================================================================
/// NOTE EVENT ENTITY - Beat Generator'dan çıkan ham nota olayı
/// ============================================================================
///
/// Bu sınıf, beat generator tarafından üretilen bir nota olayını temsil eder.
/// Henüz spawn edilmemiş, sadece "ne zaman ve hangi lane'de" bilgisini tutar.
///
/// ## Nota Akışı
///
/// ```
/// BeatGenerator -> NoteEvent -> ScheduledNote -> Note (görsel component)
/// ```
///
/// 1. BeatGenerator, NoteEvent listesi üretir
/// 2. Her NoteEvent, spawn zamanı hesaplanarak ScheduledNote'a dönüşür
/// 3. Spawn zamanı gelince ScheduledNote'dan Note component oluşturulur
/// ============================================================================
class NoteEvent {
  /// Yeni bir nota olayı oluşturur.
  ///
  /// [hitTime] Notanın hit zone'a ulaşması gereken zaman (saniye).
  /// [lane] Notanın hangi enstrümana ait olduğu (0-7).
  const NoteEvent(this.hitTime, this.lane);

  /// Notanın hit zone'a varması gereken oyun zamanı (saniye).
  ///
  /// Oyuncunun tam bu anda dokunması beklenir.
  /// Erken veya geç dokunma, timing judgement'a göre değerlendirilir.
  final double hitTime;

  /// Notanın ait olduğu lane (enstrüman) numarası.
  ///
  /// | Lane | Enstrüman    | Tipik Vuruş Paterni          |
  /// |------|--------------|------------------------------|
  /// | 0    | Close Hi-Hat | Her beat'te (tempo tutucu)   |
  /// | 1    | Open Hi-Hat  | Fill sonlarında              |
  /// | 2    | Crash        | Bar başlarında (vurgu)       |
  /// | 3    | Ride         | Hard modda ekstra ritim      |
  /// | 4    | Snare        | 2 ve 4. beat (backbeat)      |
  /// | 5    | Kick         | 1 ve 3. beat (temel ritim)   |
  /// | 6    | Tom 1        | Fill'lerde (tom roll)        |
  /// | 7    | Floor Tom    | Fill'lerde (tom roll)        |
  final int lane;

  @override
  String toString() =>
      'NoteEvent(hitTime: ${hitTime.toStringAsFixed(2)}s, lane: $lane)';
}
