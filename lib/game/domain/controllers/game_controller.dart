import 'package:flame/components.dart';
import 'package:drumly/game/domain/controllers/input_controller.dart';
import 'package:drumly/game/domain/controllers/score_controller.dart';
import 'package:drumly/game/domain/controllers/timing_controller.dart';
import 'package:drumly/game/domain/entities/hit_result.dart';
import 'package:drumly/game/domain/entities/scheduled_note.dart';

class GameController {

  GameController({
    required this.inputController,
    required this.timingController,
    required this.scoreController,
  });
  /// Input kontrolcüsü.
  final InputController inputController;

  /// Timing kontrolcüsü.
  final TimingController timingController;

  /// Skor kontrolcüsü.
  final ScoreController scoreController;

  /// Spawn edilecek notalar (zamanlanmış).
  List<ScheduledNote> _scheduledNotes = [];

  /// Aktif notalar (ekranda düşenler) - lane bazında.
  final List<List<_ActiveNote>> _activeNotesByLane = List.generate(8, (_) => []);

  /// Mevcut oyun zamanı (saniye).
  double _currentTime = 0;

  /// Spawn index (bir sonraki spawn edilecek nota).
  int _nextSpawnIndex = 0;

  // Getters
  int get score => scoreController.score;
  int get combo => scoreController.combo;
  int get maxCombo => scoreController.maxCombo;
  double get accuracy => scoreController.accuracy;

  /// Oyunu başlatır (notaları yükler).
  void startGame(List<ScheduledNote> scheduledNotes) {
    _scheduledNotes = scheduledNotes;
    _nextSpawnIndex = 0;
    _currentTime = 0;
    scoreController.reset();
    _clearAllNotes();
  }

  /// Oyun zamanını günceller (her frame).
  void update(double dt) {
    _currentTime += dt;
  }

  /// Spawn zamanı gelen notaları kontrol eder.
  ///
  /// Returns: Spawn edilmesi gereken notalar.
  List<ScheduledNote> checkForSpawns() {
    final toSpawn = <ScheduledNote>[];

    while (_nextSpawnIndex < _scheduledNotes.length &&
        _scheduledNotes[_nextSpawnIndex].spawnAt <= _currentTime) {
      final note = _scheduledNotes[_nextSpawnIndex];
      toSpawn.add(note);

      // Aktif notalara ekle
      _activeNotesByLane[note.lane].add(
        _ActiveNote(
          hitTime: note.hitTime,
          spawnTime: _currentTime,
        ),
      );

      _nextSpawnIndex++;
    }

    return toSpawn;
  }

  /// Tap işlemi (kullanıcı ekrana dokundu).
  ///
  /// Returns: HitResult veya null (hit olmadı).
  HitResult? processTap(Vector2 tapPosition) {
    // 1. Lane detection
    final lane = inputController.detectLane(tapPosition);
    if (lane == null) {
      return null; // Hiçbir lane'e vurmadı
    }

    // 2. En yakın notayı bul
    final closestNote = _findClosestNote(lane);
    if (closestNote == null) {
      // Lane'de not yok
      return HitResult.miss(lane: lane, hitTime: _currentTime);
    }

    // 3. Timing evaluation
    final result = timingController.createHitResult(
      lane: lane,
      noteTime: closestNote.hitTime,
      tapTime: _currentTime,
    );

    // 4. Hit successful ise notayı kaldır
    if (result.isSuccessful) {
      _removeNote(lane, closestNote);
    }

    // 5. Skor güncelle
    scoreController.processHit(result);

    return result;
  }

  /// Spatial hit işlemi (geometriye göre quality belirlenmişse).
  ///
  /// [lane] hedef lane.
  /// [quality] spatial değerlendirme sonucu.
  ///
  /// Returns: HitResult (miss dahil).
  HitResult processSpatialHit({
    required int lane,
    required HitQuality quality,
  }) {
    final hitTime = _currentTime;

    if (quality == HitQuality.miss) {
      final missResult = HitResult.miss(lane: lane, hitTime: hitTime);
      scoreController.processHit(missResult);
      return missResult;
    }

    // Lane'deki en yakın notayı kaldır (varsa)
    final notes = _activeNotesByLane[lane];
    if (notes.isNotEmpty) {
      _removeNote(lane, notes.first);
    }

    final result = quality == HitQuality.perfect
        ? HitResult.perfect(lane: lane, timingOffset: 0, hitTime: hitTime)
        : HitResult.good(lane: lane, timingOffset: 0, hitTime: hitTime);

    scoreController.processHit(result);
    return result;
  }

  /// Miss kontrolü (geçen notalar).
  ///
  /// Returns: Miss olan notaların lane'leri.
  List<int> checkForMisses() {
    final missedLanes = <int>[];

    for (int lane = 0; lane < _activeNotesByLane.length; lane++) {
      final notes = _activeNotesByLane[lane];

      // İlk notayı kontrol et (en eskisi)
      if (notes.isNotEmpty) {
        final firstNote = notes.first;

        if (timingController.isMissed(firstNote.hitTime, _currentTime)) {
          // Miss!
          missedLanes.add(lane);
          notes.removeAt(0);

          // Miss'i skor sistemine bildir
          final missResult = HitResult.miss(lane: lane, hitTime: _currentTime);
          scoreController.processHit(missResult);
        }
      }
    }

    return missedLanes;
  }

  /// Belirtilen lane'deki en yakın notayı bulur.
  _ActiveNote? _findClosestNote(int lane) {
    final notes = _activeNotesByLane[lane];
    if (notes.isEmpty) return null;

    // Hit window içindeki ilk notayı döndür
    for (final note in notes) {
      if (timingController.isInHitWindow(note.hitTime, _currentTime)) {
        return note;
      }
    }

    return null;
  }

  /// Notayı aktif listeden kaldırır.
  void _removeNote(int lane, _ActiveNote note) {
    _activeNotesByLane[lane].remove(note);
  }

  /// Tüm aktif notaları temizler.
  void _clearAllNotes() {
    for (final lane in _activeNotesByLane) {
      lane.clear();
    }
  }

  /// Oyunu sıfırlar.
  void reset() {
    _scheduledNotes = [];
    _nextSpawnIndex = 0;
    _currentTime = 0;
    scoreController.reset();
    _clearAllNotes();
  }

  /// Oyun sonu istatistikleri.
  Map<String, dynamic> getGameStats() => scoreController.getStats();
}

/// Aktif nota (internal kullanım için).
class _ActiveNote {

  _ActiveNote({
    required this.hitTime,
    required this.spawnTime,
  });
  final double hitTime;
  final double spawnTime;
}
