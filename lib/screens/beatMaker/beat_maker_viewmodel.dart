import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class BeatMakerViewmodel {
  final Map<String, String> drumSounds = {
    'hihat': 'assets/sounds/close_hihat.wav',
    'crash': 'assets/sounds/crash_2.wav',
    'ride': 'assets/sounds/ride_1.wav',
    'snare': 'assets/sounds/snare_hard.wav',
    'tom1': 'assets/sounds/tom_1.wav',
    'tom2': 'assets/sounds/tom_2.wav',
    'tom_floor': 'assets/sounds/tom_floor.wav',
    'kick': 'assets/sounds/kick.wav',
  };

  final Map<String, AudioPlayer> _players =
      {}; // Her parça için bir player saklanır

  Future<void> playSound(String drumPart) async {
    final path = drumSounds[drumPart];
    if (path == null) return;

    print('Playing sound for $drumPart: $path');

    // Player varsa al, yoksa oluştur ve sakla
    final player = _players.putIfAbsent(drumPart, () => AudioPlayer());

    try {
      // Çalmadan önce sıfırla
      await player.stop();
      await player.setAsset(path);
      await player.play();
    } catch (e) {
      debugPrint('Error playing $drumPart: $e');
    }
  }

  // Uygulama kapanırken veya işin bittiğinde tüm player'ları temizle
  Future<void> disposeAll() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}
