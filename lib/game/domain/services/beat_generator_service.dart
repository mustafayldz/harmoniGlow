import 'dart:math';

import 'package:drumly/game/core/enums/game_enums.dart';
import 'package:drumly/game/domain/entities/note_event.dart';
import 'package:drumly/game/domain/services/beat_clock.dart';
import 'package:drumly/game/domain/services/pattern_generator.dart';

/// ============================================================================
/// BEAT GENERATOR SERVICE V2 - Pattern-based beat generation
/// ============================================================================
///
/// Yeni sistem BeatClock ve PatternGenerator kullanarak
/// müzikal olarak daha tutarlı beat'ler üretir.
///
/// ## Özellikler
/// - BPM bazlı timing (BeatClock)
/// - Gerçek drum pattern'leri (PatternGenerator)
/// - Bar ve beat yapısı
/// - Dynamic pattern değişimi
/// ============================================================================
class BeatGeneratorService {
  BeatGeneratorService._();

  /// Zorluk seviyesine göre BPM seçer.
  static int _pickBpm(Difficulty difficulty, Random random) => switch (difficulty) {
        // Easy: 95-115 BPM (yavaş, rahat tempo)
        Difficulty.easy => 95 + random.nextInt(21),

        // Medium: 110-135 BPM (orta tempo)
        Difficulty.medium => 110 + random.nextInt(26),

        // Hard: 130-160 BPM (hızlı, zorlu tempo)
        Difficulty.hard => 130 + random.nextInt(31),
      };

  /// Belirtilen parametrelerle nota deseni üretir - YENİ SİSTEM.
  ///
  /// [difficulty] Oyun zorluk seviyesi.
  /// [seed] Rastgele sayı üreteci seed'i.
  /// [duration] Toplam oyun süresi (saniye).
  /// [startOffset] İlk notanın spawn zamanı (saniye).
  ///
  /// Returns: Zamana göre sıralanmış NoteEvent listesi.
  static List<NoteEvent> generate({
    required Difficulty difficulty,
    required int seed,
    required double duration,
    required double startOffset,
  }) {
    final random = Random(seed);
    final bpm = _pickBpm(difficulty, random).toDouble();
    
    // BeatClock ile timing hesapla
    final clock = BeatClock(bpm: bpm);
    
    // PatternGenerator ile pattern üret
    final patternGen = PatternGenerator(
      difficulty: difficulty,
      laneCount: 8,
      random: random,
    );

    // Kaç bar gerekli?
    final totalBars = ((duration - startOffset) / clock.secondsPerBar).ceil();
    
    // Pattern üret (her bar için 4 beat)
    final pattern = patternGen.generateDynamicPattern(totalBars, 0);
    
    // Fill ekle (her 16 beat'te = her 4 bar'da)
    patternGen.insertFills(pattern);
    
    // Variation ekle (%15 değişim)
    patternGen.addVariation(pattern, 0.15);

    // Pattern'den NoteEvent'lere çevir
    final events = <NoteEvent>[];
    var currentTime = startOffset;
    
    for (var beatIndex = 0; beatIndex < pattern.length; beatIndex++) {
      final lanes = pattern[beatIndex];
      
      // Bu beat için tüm lane'leri ekle
      for (final lane in lanes) {
        events.add(NoteEvent(currentTime, lane));
      }
      
      // Bir sonraki beat'e geç
      currentTime += clock.secondsPerBeat;
      
      // Duration'ı aşmayalım
      if (currentTime > startOffset + duration) {
        break;
      }
    }

    // Zamana göre sırala (time yerine ilk parametre)
    events.sort((a, b) => a.hitTime.compareTo(b.hitTime));
    
    return events;
  }

  /// Eski generate metodu - backward compatibility için.
  @Deprecated('Use generate() with new pattern system')
  static List<NoteEvent> generateBeats({
    required Difficulty difficulty,
    required double duration,
  }) => generate(
      difficulty: difficulty,
      seed: DateTime.now().millisecondsSinceEpoch,
      duration: duration,
      startOffset: 1.5,
    );
}

