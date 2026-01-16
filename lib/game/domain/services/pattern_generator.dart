import 'dart:math';
import 'package:drumly/game/core/enums/game_enums.dart';

/// Müzikal pattern generator - gerçek davul pattern'leri üretir.
class PatternGenerator {

  PatternGenerator({
    required this.difficulty,
    required this.laneCount,
    Random? random,
  }) : _random = random ?? Random();
  final Random _random;
  final Difficulty difficulty;
  final int laneCount;

  /// Temel davul pattern'i üret (kick, snare, hi-hat).
  /// 
  /// Returns: Her beat için hangi lane'lerin vuralacağı.
  /// Example: [[5], [0, 4], [5], [0, 4]] = kick-snare-kick-snare
  List<List<int>> generateBasicPattern(int barCount) {
    final pattern = <List<int>>[];
    final beatsPerBar = 4;

    for (var bar = 0; bar < barCount; bar++) {
      for (var beat = 0; beat < beatsPerBar; beat++) {
        final lanes = <int>[];

        // Beat 0 ve 2: Kick (lane 5)
        if (beat == 0 || beat == 2) {
          lanes.add(5);
        }

        // Beat 1 ve 3: Snare (lane 4)
        if (beat == 1 || beat == 3) {
          lanes.add(4);
        }

        // Her beat: Hi-hat (lane 0)
        if (difficulty != Difficulty.easy) {
          lanes.add(0);
        }

        pattern.add(lanes);
      }
    }

    return pattern;
  }

  /// Rock pattern - daha kompleks.
  List<List<int>> generateRockPattern(int barCount) {
    final pattern = <List<int>>[];
    final beatsPerBar = 4;

    for (var bar = 0; bar < barCount; bar++) {
      for (var beat = 0; beat < beatsPerBar; beat++) {
        final lanes = <int>[];

        // Kick pattern: 1, 2.5, 3
        if (beat == 0) {
          lanes.add(5); // Kick
        } else if (beat == 2) {
          lanes.add(5); // Kick
          if (difficulty == Difficulty.hard) {
            lanes.add(6); // Tom
          }
        }

        // Snare: 2, 4
        if (beat == 1 || beat == 3) {
          lanes.add(4); // Snare
        }

        // Hi-hat: Her beat + 8th notlar
        if (difficulty == Difficulty.hard) {
          lanes.add(0); // Closed hi-hat
          if (beat == 3) {
            lanes.add(1); // Open hi-hat
          }
        } else if (difficulty == Difficulty.medium) {
          lanes.add(0);
        }

        // Crash on downbeat
        if (beat == 0 && bar % 4 == 0) {
          lanes.add(2); // Crash
        }

        pattern.add(lanes);
      }
    }

    return pattern;
  }

  /// Jazz pattern - swing feel.
  List<List<int>> generateJazzPattern(int barCount) {
    final pattern = <List<int>>[];
    final beatsPerBar = 4;

    for (var bar = 0; bar < barCount; bar++) {
      for (var beat = 0; beat < beatsPerBar; beat++) {
        final lanes = <int>[];

        // Ride cymbal pattern (swing)
        if (difficulty != Difficulty.easy) {
          lanes.add(3); // Ride
        }

        // Kick: syncopated
        if (beat == 0 || (beat == 2 && _random.nextDouble() > 0.5)) {
          lanes.add(5);
        }

        // Snare: 2 and 4 (backbeat)
        if (beat == 1 || beat == 3) {
          lanes.add(4);
        }

        // Hi-hat with foot (beat 2 and 4)
        if ((beat == 1 || beat == 3) && difficulty == Difficulty.hard) {
          lanes.add(0);
        }

        pattern.add(lanes);
      }
    }

    return pattern;
  }

  /// Fill pattern - bar sonlarında kullanılır.
  List<List<int>> generateFillPattern() {
    final pattern = <List<int>>[];
    
    if (difficulty == Difficulty.easy) {
      // Basit fill: snare + tom
      pattern.add([4]); // Snare
      pattern.add([6]); // Tom 1
      pattern.add([7]); // Tom 2
      pattern.add([2]); // Crash finish
    } else if (difficulty == Difficulty.medium) {
      // 16th note fill
      pattern.add([4, 6]);
      pattern.add([6, 7]);
      pattern.add([7, 4]);
      pattern.add([2, 5]); // Crash + kick
    } else {
      // Karmaşık fill
      pattern.add([4]);
      pattern.add([6, 7]);
      pattern.add([4]);
      pattern.add([6, 7, 2]); // Triple hit + crash
    }

    return pattern;
  }

  /// Random variation ekle - aynı pattern'in tekrarını önler.
  void addVariation(List<List<int>> pattern, double variationAmount) {
    for (var i = 0; i < pattern.length; i++) {
      if (_random.nextDouble() < variationAmount) {
        // Bu beat'i değiştir
        final lanes = pattern[i];
        
        // %50 şans: lane ekle
        if (_random.nextBool() && lanes.length < 3) {
          final newLane = _random.nextInt(laneCount);
          if (!lanes.contains(newLane)) {
            lanes.add(newLane);
          }
        }
        // %50 şans: lane çıkar
        else if (lanes.isNotEmpty && _random.nextBool()) {
          lanes.removeAt(_random.nextInt(lanes.length));
        }
      }
    }
  }

  /// Dinamik pattern seçici - oyun ilerledikçe pattern değiştirir.
  List<List<int>> generateDynamicPattern(int barCount, int currentBar) {
    // İlk 4 bar: Basic
    if (currentBar < 4) {
      return generateBasicPattern(barCount);
    }
    // Bar 4-8: Rock
    else if (currentBar < 8) {
      return generateRockPattern(barCount);
    }
    // Bar 8-12: Jazz
    else if (currentBar < 12) {
      return generateJazzPattern(barCount);
    }
    // Bar 12+: Mix
    else {
      final choice = _random.nextInt(3);
      return switch (choice) {
        0 => generateBasicPattern(barCount),
        1 => generateRockPattern(barCount),
        _ => generateJazzPattern(barCount),
      };
    }
  }

  /// Fill ekle (her 4 bar'da bir).
  void insertFills(List<List<int>> pattern, {int fillInterval = 16}) {
    for (var i = fillInterval - 4; i < pattern.length; i += fillInterval) {
      final fill = generateFillPattern();
      for (var j = 0; j < fill.length && (i + j) < pattern.length; j++) {
        pattern[i + j] = fill[j];
      }
    }
  }
}
