import 'package:audioplayers/audioplayers.dart';
import '../core/enums/drum_type.dart';

class DrumSoundService {
  static final DrumSoundService _instance = DrumSoundService._internal();
  factory DrumSoundService() => _instance;
  DrumSoundService._internal();

  final Map<DrumType, AudioPlayer> _players = {};
  final List<AudioPlayer> _activePlayers = [];

  final Map<DrumType, String> _soundPaths = {
    DrumType.kick: 'sounds/kick.m4a',
    DrumType.snare: 'sounds/snare_hard.m4a',
    DrumType.hihat: 'sounds/close_hihat.m4a',
    DrumType.tom1: 'sounds/tom_1.m4a',
    DrumType.tom2: 'sounds/tom_2.m4a',
  };

  Future<void> initialize() async {
    // Initialize audio players for each drum type
    for (final drumType in DrumType.values) {
      _players[drumType] = AudioPlayer();
      await _players[drumType]!.setSourceAsset(_soundPaths[drumType]!);
    }
  }

  Future<void> playDrumSound(DrumType drumType) async {
    try {
      final player = _players[drumType];
      if (player != null) {
        await player.stop(); // Stop any currently playing sound
        await player.resume(); // Play the sound
      }
    } catch (e) {
      print('Error playing drum sound: $e');
    }
  }

  Future<void> playHitEffect() async {
    // Play a special effect sound for successful hits
    try {
      final player = AudioPlayer();
      _activePlayers.add(player);
      await player.setSourceAsset('sounds/ride_1.m4a');
      await player.resume();

      // Remove player after it finishes
      player.onPlayerComplete.listen((_) {
        _activePlayers.remove(player);
        player.dispose();
      });
    } catch (e) {
      print('Error playing hit effect: $e');
    }
  }

  Future<void> playMissEffect() async {
    // DO NOT play miss effect automatically
    // Only play when explicitly called
    try {
      final player = AudioPlayer();
      _activePlayers.add(player);
      await player.setSourceAsset('sounds/crash_2.m4a');
      await player.resume();

      // Remove player after it finishes
      player.onPlayerComplete.listen((_) {
        _activePlayers.remove(player);
        player.dispose();
      });
    } catch (e) {
      print('Error playing miss effect: $e');
    }
  }

  Future<void> stopAllSounds() async {
    // Stop all drum sounds
    for (final player in _players.values) {
      try {
        await player.stop();
      } catch (e) {
        print('Error stopping player: $e');
      }
    }

    // Stop all active effect players
    for (final player in _activePlayers) {
      try {
        await player.stop();
        player.dispose();
      } catch (e) {
        print('Error stopping active player: $e');
      }
    }
    _activePlayers.clear();
  }

  void dispose() {
    stopAllSounds();
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
