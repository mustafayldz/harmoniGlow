import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

class JustAudioDrumManager {
  factory JustAudioDrumManager() => _instance;

  JustAudioDrumManager._internal() {
    _initPlayers();
  }

  static final JustAudioDrumManager _instance =
      JustAudioDrumManager._internal();

  final Map<String, String> _paths = {
    'Hi-Hat': 'assets/sounds/open_hihat.m4a',
    'Hi-Hat Closed': 'assets/sounds/close_hihat.m4a',
    'Crash Cymbal': 'assets/sounds/crash_2.m4a',
    'Ride Cymbal': 'assets/sounds/ride_1.m4a',
    'Snare Drum': 'assets/sounds/snare_hard.m4a',
    'Tom 1': 'assets/sounds/tom_1.m4a',
    'Tom 2': 'assets/sounds/tom_2.m4a',
    'Tom Floor': 'assets/sounds/tom_floor.m4a',
    'Kick Drum': 'assets/sounds/kick.m4a',
  };

  final Map<String, List<AudioPlayer>> _playerPool = {};
  final Map<String, int> _poolIndex = {};
  bool _initialized = false;

  Future<void> _initPlayers() async {
    if (_initialized) return;

    try {
      for (final drumPart in _paths.keys) {
        final path = _paths[drumPart];
        if (path == null) continue;

        final pool = <AudioPlayer>[];

        // Her davul parçası için 2 player oluştur
        for (int i = 0; i < 2; i++) {
          final player = AudioPlayer();

          try {
            // Ses dosyasını pre-load et
            await player.setAsset(path);
            debugPrint('✅ Preloaded $drumPart player $i');

            pool.add(player);
          } catch (e) {
            debugPrint('⚠️ Failed to preload $drumPart player $i: $e');
            // Boş player ekle, runtime'da yüklemeyi deneriz
            pool.add(player);
          }
        }

        _playerPool[drumPart] = pool;
        _poolIndex[drumPart] = 0;
      }

      _initialized = true;
      debugPrint('✅ JustAudioDrumManager initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing JustAudioDrumManager: $e');
      _initialized = false;
    }
  }

  Future<void> reinitialize() async {
    if (!_initialized) {
      await _initPlayers();
    }
  }

  Future<void> play(String drumPart) async {
    final path = _paths[drumPart];
    if (path == null) return;

    final pool = _playerPool[drumPart];
    if (pool == null || pool.isEmpty) return;

    try {
      // Round-robin approach ile player seç
      final index = _poolIndex[drumPart] ?? 0;
      final player = pool[index];

      // Next index for round-robin
      _poolIndex[drumPart] = (index + 1) % pool.length;

      // Eğer player çalıyorsa, durdur ve başa sar
      if (player.playing) {
        await player.stop();
      }

      await player.seek(Duration.zero);

      // Eğer asset yüklenmemişse, yükle
      if (player.audioSource == null) {
        await player.setAsset(path);
      }

      // Çal
      await player.play();

      debugPrint('🥁 Playing $drumPart with JustAudio player $index');
    } catch (e) {
      debugPrint('❌ Error playing $drumPart: $e');

      // Fallback: yeni player oluştur ve çal
      try {
        final fallbackPlayer = AudioPlayer();
        await fallbackPlayer.setAsset(path);
        await fallbackPlayer.play();

        debugPrint('🔄 Fallback JustAudio player created for $drumPart');
      } catch (e2) {
        debugPrint('❌ Fallback also failed for $drumPart: $e2');
      }
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
    _initialized = false;
  }
}
