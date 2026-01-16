/// BeatClock - Müzikal ritim takibi için clock.
/// 
/// Her oyun frame'inde mevcut beat pozisyonunu hesaplar.
/// BPM bazlı timing sağlar.
class BeatClock {

  BeatClock({
    required this.bpm,
    this.beatsPerBar = 4,
  });
  final double bpm;
  final int beatsPerBar;
  
  double _currentTime = 0.0;

  /// Clock'u güncelle.
  void update(double dt) {
    _currentTime += dt;
  }

  /// Clock'u sıfırla.
  void reset() {
    _currentTime = 0.0;
  }

  /// Mevcut beat pozisyonu (0.0 = beat başlangıcı, 1.0 = sonraki beat).
  double get currentBeatPosition {
    final secondsPerBeat = 60.0 / bpm;
    return (_currentTime % secondsPerBeat) / secondsPerBeat;
  }

  /// Kaçıncı beat'teyiz (toplam beat sayısı).
  int get currentBeatNumber {
    final secondsPerBeat = 60.0 / bpm;
    return (_currentTime / secondsPerBeat).floor();
  }

  /// Kaçıncı bar'dayız.
  int get currentBar => (currentBeatNumber / beatsPerBar).floor();

  /// Bar içindeki beat pozisyonu (0, 1, 2, 3 for 4/4).
  int get beatInBar => currentBeatNumber % beatsPerBar;

  /// Bir sonraki beat'e kalan süre (saniye).
  double get timeUntilNextBeat {
    final secondsPerBeat = 60.0 / bpm;
    return secondsPerBeat - (_currentTime % secondsPerBeat);
  }

  /// Belirli bir beat'e kalan süre.
  double timeUntilBeat(int targetBeat) {
    final secondsPerBeat = 60.0 / bpm;
    final targetTime = targetBeat * secondsPerBeat;
    return targetTime - _currentTime;
  }

  /// İki beat arasındaki süre (saniye).
  double get secondsPerBeat => 60.0 / bpm;

  /// Bir bar'ın süresi (saniye).
  double get secondsPerBar => secondsPerBeat * beatsPerBar;

  /// Şu an beat'in tam üzerinde miyiz? (tolerance ile).
  bool isOnBeat({double tolerance = 0.1}) {
    final beatPos = currentBeatPosition;
    return beatPos < tolerance || beatPos > (1.0 - tolerance);
  }

  /// Downbeat mi? (Bar'ın ilk beat'i)
  bool get isDownbeat => beatInBar == 0;
}
