import 'package:audioplayers/audioplayers.dart';

class DrumPlayerManager {
  factory DrumPlayerManager() => _instance;
  // Singleton yapısı
  DrumPlayerManager._internal() {
    _initPlayers();
  }

  static final DrumPlayerManager _instance = DrumPlayerManager._internal();

  final Map<String, String> _paths = {
    'Hi-Hat': 'sounds/open_hihat.ogg',
    'Hi-Hat Closed': 'sounds/close_hihat.ogg',
    'Crash Cymbal': 'sounds/crash_2.ogg',
    'Ride Cymbal': 'sounds/ride_1.ogg',
    'Snare Drum': 'sounds/snare_hard.ogg',
    'Tom 1': 'sounds/tom_1.ogg',
    'Tom 2': 'sounds/tom_2.ogg',
    'Tom Floor': 'sounds/tom_floor.ogg',
    'Kick Drum': 'sounds/kick.ogg',
  };

  final Map<String, List<AudioPlayer>> _playerPool = {};
  final Map<String, int> _poolIndex = {};
  bool _initialized = false;

  void _initPlayers() {
    if (_initialized) return;

    for (var key in _paths.keys) {
      _playerPool[key] = List.generate(9, (_) {
        final player = AudioPlayer();
        player.setPlayerMode(PlayerMode.lowLatency);
        return player;
      });
    }

    _initialized = true;
  }

  /// Manuel yeniden başlatmak için (dispose sonrası)
  void reinitialize() {
    _initPlayers();
  }

  Future<void> play(String drumPart) async {
    final path = _paths[drumPart];
    if (path == null) return;

    final pool = _playerPool[drumPart];
    if (pool == null || pool.isEmpty) return;

    final index = _poolIndex[drumPart] ?? 0;
    final player = pool[index % pool.length];
    _poolIndex[drumPart] = (index + 1) % pool.length;

    try {
      await player.stop(); // önceki sesi durdur
      await player.setSource(AssetSource(path));
      await player.resume();
    } catch (e) {
      print('❌ Error playing $drumPart: $e');
    }
  }

  Future<void> dispose() async {
    for (final pool in _playerPool.values) {
      for (final player in pool) {
        await player.dispose();
      }
    }

    _playerPool.clear();
    _poolIndex.clear();
    _initialized = false; // yeniden init için hazırla
  }
}
