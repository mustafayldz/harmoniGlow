import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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

  Future<void> _initPlayers() async {
    if (_initialized) return;

    try {
      for (var key in _paths.keys) {
        final path = _paths[key];
        if (path == null) continue;

        _playerPool[key] = await Future.wait(
          List.generate(3, (_) async {
            // 3 player per drum part
            final player = AudioPlayer();

            try {
              // iOS için PlayerMode.lowLatency kullan
              await player.setPlayerMode(PlayerMode.lowLatency);

              // Ses dosyasını pre-load et
              await player.setSource(AssetSource(path));

              debugPrint('✅ Preloaded $key successfully');
              return player;
            } catch (e) {
              debugPrint('⚠️ Failed to preload $key: $e');
              return player; // Boş player döndür
            }
          }),
        );
      }

      _initialized = true;
      debugPrint('✅ DrumPlayerManager initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing DrumPlayerManager: $e');
      _initialized = false;
    }
  }

  /// Manuel yeniden başlatmak için (dispose sonrası)
  Future<void> reinitialize() async {
    await _initPlayers();
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

      // Player'ı durdur ve başa sar
      await player.stop();
      await player.seek(Duration.zero);

      // Ses dosyasını tekrar yükle (iOS sorunu için)
      await player.setSource(AssetSource(path));

      // Çal
      await player.resume();

      debugPrint('🥁 Playing $drumPart with player $index');
    } catch (e) {
      debugPrint('❌ Error playing $drumPart: $e');

      // Fallback: yeni player oluştur
      try {
        final fallbackPlayer = AudioPlayer();
        await fallbackPlayer.setPlayerMode(PlayerMode.lowLatency);
        await fallbackPlayer.setSource(AssetSource(path));
        await fallbackPlayer.resume();

        debugPrint('🔄 Fallback player created for $drumPart');
      } catch (e2) {
        debugPrint('❌ Error creating fallback player for $drumPart: $e2');
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
    _initialized = false; // yeniden init için hazırla
  }
}
