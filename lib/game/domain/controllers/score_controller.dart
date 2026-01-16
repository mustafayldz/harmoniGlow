import 'package:flutter/services.dart';
import 'package:drumly/game/domain/entities/hit_result.dart';

class ScoreController {

  ScoreController({this.enableHaptic = true});
  /// Haptic feedback aktif mi?
  final bool enableHaptic;

  /// Base skorlar (hit quality'ye göre).
  static const int perfectScore = 100;
  static const int goodScore = 50;
  static const int missScore = 0;

  /// Combo çarpanları.
  static const Map<int, double> comboMultipliers = {
    10: 1.2, // 10 combo = 1.2x
    20: 1.5, // 20 combo = 1.5x
    50: 2.0, // 50 combo = 2x
    100: 3.0, // 100 combo = 3x
  };

  /// Mevcut skor.
  int _score = 0;

  /// Mevcut combo.
  int _combo = 0;

  /// En yüksek combo.
  int _maxCombo = 0;

  /// Toplam hit sayısı.
  int _totalHits = 0;

  /// Perfect hit sayısı.
  int _perfectHits = 0;

  /// Good hit sayısı.
  int _goodHits = 0;

  /// Miss sayısı.
  int _missCount = 0;

  // Getters
  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get totalHits => _totalHits;
  int get perfectHits => _perfectHits;
  int get goodHits => _goodHits;
  int get missCount => _missCount;

  /// Accuracy (doğruluk yüzdesi).
  double get accuracy {
    if (_totalHits == 0) return 100.0;
    final successfulHits = _perfectHits + _goodHits;
    return (successfulHits / _totalHits) * 100;
  }

  /// Perfect accuracy (sadece perfect hit'ler).
  double get perfectAccuracy {
    if (_totalHits == 0) return 100.0;
    return (_perfectHits / _totalHits) * 100;
  }

  /// Hit sonucunu işler ve skor ekler.
  void processHit(HitResult result) {
    _totalHits++;

    if (result.isSuccessful) {
      // Hit başarılı
      _updateCombo(increment: true);

      // Quality'ye göre skor ekle ve haptic feedback
      if (result.isPerfect) {
        _perfectHits++;
        _addScore(perfectScore);
        _triggerHaptic(HapticFeedbackType.heavy); // Perfect = heavy
      } else if (result.isGood) {
        _goodHits++;
        _addScore(goodScore);
        _triggerHaptic(HapticFeedbackType.medium); // Good = medium
      }
    } else {
      // Miss
      _missCount++;
      _updateCombo(increment: false);
      _triggerHaptic(HapticFeedbackType.light); // Miss = light
    }
  }

  /// Skor ekler (combo çarpanı ile).
  void _addScore(int baseScore) {
    final multiplier = _getComboMultiplier();
    final finalScore = (baseScore * multiplier).round();
    _score += finalScore;
  }

  /// Combo'yu günceller.
  void _updateCombo({required bool increment}) {
    if (increment) {
      _combo++;
      if (_combo > _maxCombo) {
        _maxCombo = _combo;
      }
    } else {
      _combo = 0;
    }
  }

  /// Mevcut combo için çarpanı döndürür.
  double _getComboMultiplier() {
    double multiplier = 1.0;

    for (final entry in comboMultipliers.entries) {
      if (_combo >= entry.key) {
        multiplier = entry.value;
      }
    }

    return multiplier;
  }

  /// Haptic feedback tetikler.
  void _triggerHaptic(HapticFeedbackType type) {
    if (!enableHaptic) return;

    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Sıfırlar (yeni oyun için).
  void reset() {
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _totalHits = 0;
    _perfectHits = 0;
    _goodHits = 0;
    _missCount = 0;
  }

  /// Oyun sonu istatistikleri.
  Map<String, dynamic> getStats() => {
      'score': _score,
      'maxCombo': _maxCombo,
      'accuracy': accuracy,
      'perfectAccuracy': perfectAccuracy,
      'totalHits': _totalHits,
      'perfectHits': _perfectHits,
      'goodHits': _goodHits,
      'missCount': _missCount,
    };

  @override
  String toString() => 'ScoreController(score: $_score, combo: $_combo, accuracy: ${accuracy.toStringAsFixed(1)}%)';
}

/// ============================================================================
/// HAPTIC FEEDBACK TYPE
/// ============================================================================

enum HapticFeedbackType {
  light,
  medium,
  heavy,
}
