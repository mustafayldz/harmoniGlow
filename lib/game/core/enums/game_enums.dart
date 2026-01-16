/// Oyun zorluk seviyeleri.
///
/// Her seviye farklı BPM aralığı, not hızı ve judgement penceresi kullanır:
/// - [easy]: Yeni başlayanlar için. Yavaş notalar, geniş hit penceresi.
/// - [medium]: Orta seviye oyuncular için. Dengeli zorluk.
/// - [hard]: Uzman oyuncular için. Hızlı notalar, dar hit penceresi.
enum Difficulty {
  /// Kolay mod: BPM 95-115, not hızı 180px/s, Perfect ±60ms
  easy,

  /// Orta mod: BPM 110-135, not hızı 220px/s, Perfect ±50ms
  medium,

  /// Zor mod: BPM 130-160, not hızı 260px/s, Perfect ±40ms
  hard,
}

/// Oyunun mevcut durumu.
///
/// State machine pattern ile oyun akışını kontrol eder:
/// - [menu]: Ana menü ekranı, oyun başlamadı
/// - [playing]: Oyun aktif, notalar düşüyor
/// - [gameOver]: Oyun bitti, skor ekranı gösteriliyor
enum GameState {
  /// Ana menü: Zorluk seçimi ve başlat butonu görünür
  menu,

  /// Oyun devam ediyor: Notalar spawn oluyor, input alınıyor
  playing,

  /// Oyun bitti: Final skor ve tekrar oyna seçenekleri
  gameOver,
}
