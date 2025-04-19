import 'dart:async';

class BeatScheduler {
  BeatScheduler({
    required this.bpm,
    required this.songDurationSeconds,
    required this.onBeat,
  });
  final int bpm;
  final int songDurationSeconds;
  final Function(List<int>) onBeat;

  late final Timer _timer;
  int _currentBeatIndex = 0;
  int _currentSecond = 0;

  // Bölüm zamanları (saniye cinsinden) ve preset adları
  final Map<String, List<int>> patternPresets = {
    'none': [0],
    'simple': [1, 8],
    'chorus': [1, 4, 2],
    'ride': [3],
  };

  void start() {
    final intervalMs = (60000 / bpm).round();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentSecond > songDurationSeconds) {
        timer.cancel();
        return;
      }

      final pattern = _getPatternForSecond(_currentSecond);
      final beatNotes = _getBeatForPattern(pattern, _currentBeatIndex);

      onBeat(beatNotes);

      _currentBeatIndex++;
      _currentSecond = (_currentBeatIndex * intervalMs / 1000).floor();
    });
  }

  List<int> _getBeatForPattern(String patternName, int beatIndex) {
    final base = patternPresets[patternName] ?? [0];
    // 4-beat döngü örneği (kick-snare-kick-snare)
    if (patternName == 'simple') {
      final i = beatIndex % 4;
      if (i == 0 || i == 2) return [1, 8];
      if (i == 1 || i == 3) return [1, 4];
    }
    return base;
  }

  String _getPatternForSecond(int second) {
    if (second < 68) return 'none';
    if (second < 100) return 'simple';
    if (second < 132) return 'chorus';
    if (second < 164) return 'simple';
    if (second < 196) return 'chorus';
    if (second < 228) return 'ride';
    return 'none';
  }

  void stop() {
    _timer.cancel();
  }
}

// Kullanım:
// final scheduler = BeatScheduler(
//   bpm: 128,
//   songDurationSeconds: 278,
//   onBeat: (notes) {
//     sendData.sendHexData(bloc, notes);
//   },
// );
// scheduler.start();
