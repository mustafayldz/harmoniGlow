/// ============================================================================
/// SCHEDULED NOTE ENTITY - Spawn zamanı hesaplanmış nota
/// ============================================================================
///
/// Bu sınıf, NoteEvent'ten türetilen ve spawn zamanı hesaplanmış bir notayı
/// temsil eder. Oyun döngüsü bu listeyi tarar ve spawn zamanı gelen notaları
/// ekranda görsel olarak oluşturur.
///
/// ## Spawn Zamanı Hesaplama
///
/// ```
/// travelTime = (hitZoneY + notaYüksekliği) / noteSpeed
/// spawnAt = hitTime - travelTime
/// ```
///
/// Örnek:
/// - hitTime = 5.0s (oyuncunun vurması gereken an)
/// - travelTime = 2.0s (notanın hit zone'a ulaşma süresi)
/// - spawnAt = 3.0s (notanın ekranda görünme anı)
///
/// ## Kullanım
///
/// ```dart
/// // Oyun update döngüsünde:
/// while (_nextSpawnIndex < _scheduled.length &&
///        _scheduled[_nextSpawnIndex].spawnAt <= _gameTime) {
///   _spawnNote(_scheduled[_nextSpawnIndex]);
///   _nextSpawnIndex++;
/// }
/// ```
/// ============================================================================
class ScheduledNote {
  /// Yeni bir scheduled nota oluşturur.
  ///
  /// [spawnAt] Notanın ekranda görünme zamanı (saniye).
  /// [hitTime] Notanın hit zone'a ulaşma zamanı (saniye).
  /// [lane] Notanın hangi enstrümana ait olduğu (0-7).
  const ScheduledNote({
    required this.spawnAt,
    required this.hitTime,
    required this.lane,
  });

  /// Notanın ekranda spawn olacağı oyun zamanı (saniye).
  ///
  /// Bu değer `hitTime - travelTime` formülüyle hesaplanır.
  /// Oyun döngüsünde `gameTime >= spawnAt` olduğunda nota oluşturulur.
  final double spawnAt;

  /// Notanın hit zone'a ulaşacağı oyun zamanı (saniye).
  ///
  /// Oyuncunun tam bu anda dokunması "Perfect" timing verir.
  /// Bu değer NoteEvent'ten doğrudan alınır.
  final double hitTime;

  /// Notanın ait olduğu lane (enstrüman) numarası (0-7).
  ///
  /// Bu değer, notanın hangi pad'in üzerinden düşeceğini ve
  /// hangi sesin çalınacağını belirler.
  final int lane;

  @override
  String toString() => 'ScheduledNote(spawn: ${spawnAt.toStringAsFixed(2)}s, '
      'hit: ${hitTime.toStringAsFixed(2)}s, lane: $lane)';
}
