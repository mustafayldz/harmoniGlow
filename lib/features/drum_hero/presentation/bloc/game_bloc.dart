import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drumly/features/drum_hero/data/models/drum_note.dart';
import 'package:drumly/features/drum_hero/core/enums/game_state.dart';
import 'package:drumly/features/drum_hero/core/enums/drum_type.dart';
import 'package:drumly/features/drum_hero/core/constants/game_constants.dart';
import 'package:drumly/features/drum_hero/services/drum_sound_service.dart';
import 'dart:math';

// Events
abstract class GameEvent {}

class StartGame extends GameEvent {
  final int level;
  final double screenWidth;
  final double screenHeight;

  StartGame({
    required this.level,
    this.screenWidth = 800.0,
    this.screenHeight = 600.0,
  });
}

class UpdateNotePositions extends GameEvent {
  final double deltaTime;
  UpdateNotePositions(this.deltaTime);
}

class HitNote extends GameEvent {
  final int lane;
  HitNote(this.lane);
}

class CompleteLevel extends GameEvent {}

class PauseGame extends GameEvent {}

class ResumeGame extends GameEvent {}

class ExitGame extends GameEvent {}

// State
class GameBlocState {
  final GameState gameState;
  final List<DrumNote> activeNotes;
  final int score;
  final int combo;
  final double songPosition; // milliseconds
  final int currentLevel;
  final double screenWidth;
  final double screenHeight;
  final int hitCount;
  final int totalNotes;
  final double accuracy;
  final bool levelCompleted;
  final bool levelFailed;
  final LevelConfig? levelConfig;

  const GameBlocState({
    this.gameState = GameState.menu,
    this.activeNotes = const [],
    this.score = 0,
    this.combo = 0,
    this.songPosition = 0.0,
    this.currentLevel = 0, // Changed from 1 to 0
    this.screenWidth = 800.0,
    this.screenHeight = 600.0,
    this.hitCount = 0,
    this.totalNotes = 0,
    this.accuracy = 0.0,
    this.levelCompleted = false,
    this.levelFailed = false,
    this.levelConfig,
  });

  GameBlocState copyWith({
    GameState? gameState,
    List<DrumNote>? activeNotes,
    int? score,
    int? combo,
    double? songPosition,
    int? currentLevel,
    double? screenWidth,
    double? screenHeight,
    int? hitCount,
    int? totalNotes,
    double? accuracy,
    bool? levelCompleted,
    bool? levelFailed,
    LevelConfig? levelConfig,
  }) {
    return GameBlocState(
      gameState: gameState ?? this.gameState,
      activeNotes: activeNotes ?? this.activeNotes,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      songPosition: songPosition ?? this.songPosition,
      currentLevel: currentLevel ?? this.currentLevel,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      hitCount: hitCount ?? this.hitCount,
      totalNotes: totalNotes ?? this.totalNotes,
      accuracy: accuracy ?? this.accuracy,
      levelCompleted: levelCompleted ?? this.levelCompleted,
      levelFailed: levelFailed ?? this.levelFailed,
      levelConfig: levelConfig ?? this.levelConfig,
    );
  }
}

// BLoC
class GameBloc extends Bloc<GameEvent, GameBlocState> {
  final DrumSoundService _soundService = DrumSoundService();
  List<DrumNote> _levelNotes = [];
  int _noteIdCounter = 0;

  GameBloc() : super(const GameBlocState()) {
    on<StartGame>(_onStartGame);
    on<UpdateNotePositions>(_onUpdateNotePositions);
    on<HitNote>(_onHitNote);
    on<CompleteLevel>(_onCompleteLevel);
    on<PauseGame>(_onPauseGame);
    on<ResumeGame>(_onResumeGame);
    on<ExitGame>(_onExitGame);

    // Initialize sound service
    _soundService.initialize();
  }

  void _onStartGame(StartGame event, Emitter<GameBlocState> emit) {
    final levelConfig = GameConstants.levels[event.level];
    if (levelConfig == null) return;

    // Generate notes for this level
    _levelNotes = _generateNotesForLevel(levelConfig);
    _noteIdCounter = 0;

    emit(state.copyWith(
      gameState: GameState.playing,
      currentLevel: event.level,
      songPosition: 0.0,
      score: 0,
      combo: 0,
      hitCount: 0,
      totalNotes: 0,
      accuracy: 0.0,
      activeNotes: [],
      screenWidth: event.screenWidth,
      screenHeight: event.screenHeight,
      levelConfig: levelConfig,
      levelCompleted: false,
      levelFailed: false,
    ));
  }

  List<DrumNote> _generateNotesForLevel(LevelConfig config) {
    final notes = <DrumNote>[];
    final random = Random();
    final drumTypes = DrumType.values;

    // Calculate timing between notes based on BPM
    final beatDuration = 60000 / config.bpm; // milliseconds per beat

    for (int i = 0; i < config.noteCount; i++) {
      final spawnTime =
          i * beatDuration + (random.nextDouble() * beatDuration * 0.5);
      final drumType = drumTypes[random.nextInt(drumTypes.length)];
      final lane = _getLaneForDrumType(drumType);

      notes.add(DrumNote(
        id: _noteIdCounter++, // Use and increment counter
        drumType: drumType,
        spawnTime: spawnTime,
        lane: lane,
        yPosition: -GameConstants.noteHeight, // Start above screen in landscape
      ));
    }

    // Sort by spawn time
    notes.sort((a, b) => a.spawnTime.compareTo(b.spawnTime));
    return notes;
  }

  int _getLaneForDrumType(DrumType drumType) {
    switch (drumType) {
      case DrumType.hihat:
        return 0;
      case DrumType.tom1:
        return 1;
      case DrumType.snare:
        return 2;
      case DrumType.tom2:
        return 3;
      case DrumType.kick:
        return 4;
    }
  }

  void _onUpdateNotePositions(
      UpdateNotePositions event, Emitter<GameBlocState> emit) {
    if (state.gameState != GameState.playing) return;

    final newActiveNotes = <DrumNote>[];
    final currentTime = state.songPosition +
        (event.deltaTime * 1000); // Convert to milliseconds

    // Check if we need to spawn new notes
    for (final note in _levelNotes) {
      if (note.spawnTime <= currentTime &&
          !state.activeNotes.any((n) => n.id == note.id)) {
        // Start notes from left side (spawn area)
        newActiveNotes
            .add(note.copyWith(yPosition: 50.0)); // Start at left spawn line
      }
    }

    // Update positions of existing notes (move horizontally in landscape)
    final updatedActiveNotes = state.activeNotes.map((note) {
      final newX = note.yPosition + (GameConstants.noteSpeed * event.deltaTime);
      return note.copyWith(yPosition: newX);
    }).toList();

    // Add new notes
    updatedActiveNotes.addAll(newActiveNotes);

    // Remove notes that are off screen (past hit zone in landscape)
    final hitZoneX = state.screenWidth - 100; // Hit zone position
    final visibleNotes = updatedActiveNotes
        .where((note) => note.yPosition < hitZoneX + 50) // Give some buffer
        .toList();

    // Check for missed notes (past hit zone)
    final missedNotes = updatedActiveNotes
        .where((note) => note.yPosition > hitZoneX + 30) // Past hit zone
        .toList();

    int newCombo = state.combo;
    int newTotalNotes = state.totalNotes;
    if (missedNotes.isNotEmpty) {
      newCombo = 0; // Reset combo on miss
      newTotalNotes += missedNotes.length;
    }

    // Check level completion
    final allNotesSpawned = _levelNotes.every((note) =>
        updatedActiveNotes.any((activeNote) => activeNote.id == note.id) ||
        note.spawnTime <= currentTime);
    final allNotesCleared = visibleNotes.isEmpty;
    final levelCompleted =
        allNotesSpawned && allNotesCleared && _levelNotes.isNotEmpty;

    // Calculate accuracy
    final accuracy =
        state.totalNotes > 0 ? (state.hitCount / state.totalNotes) * 100 : 0.0;

    emit(state.copyWith(
      songPosition: currentTime,
      activeNotes: visibleNotes,
      combo: newCombo,
      totalNotes: newTotalNotes,
      accuracy: accuracy,
      levelCompleted: levelCompleted,
    ));
  }

  void _onHitNote(HitNote event, Emitter<GameBlocState> emit) {
    // Find notes in the hit zone for the given lane
    final notesInLane =
        state.activeNotes.where((note) => note.lane == event.lane).toList();

    if (notesInLane.isEmpty) {
      // Miss - no notes in this lane, but don't play miss sound automatically
      emit(state.copyWith(
        combo: 0,
        totalNotes: state.totalNotes + 1,
      )); // Reset combo on miss
      return;
    }

    // Find the closest note to the hit zone (right side in landscape)
    DrumNote? closestNote;
    double closestDistance = double.infinity;
    final hitZoneX = state.screenWidth - 100; // Hit zone at right side

    for (final note in notesInLane) {
      final distance = (note.yPosition - hitZoneX).abs();

      if (distance < closestDistance) {
        closestDistance = distance;
        closestNote = note;
      }
    }

    if (closestNote != null) {
      // Check if hit is within acceptable timing window
      if (closestDistance <= GameConstants.goodHitThreshold) {
        // Successful hit!
        _soundService.playDrumSound(closestNote.drumType);

        // Determine hit accuracy
        int scoreGain;
        if (closestDistance <= GameConstants.perfectHitThreshold) {
          scoreGain = GameConstants.perfectScore;
        } else {
          scoreGain = GameConstants.goodScore;
        }

        // Remove the hit note and update score/combo
        final updatedNotes = List<DrumNote>.from(state.activeNotes);
        updatedNotes.remove(closestNote);

        final newHitCount = state.hitCount + 1;
        final newTotalNotes = state.totalNotes + 1;
        final newAccuracy = (newHitCount / newTotalNotes) * 100;

        emit(state.copyWith(
          activeNotes: updatedNotes,
          score:
              state.score + scoreGain + (state.combo * 10), // Combo multiplier
          combo: state.combo + 1,
          hitCount: newHitCount,
          totalNotes: newTotalNotes,
          accuracy: newAccuracy,
        ));
      } else {
        // Miss - too far from hit zone, but don't play miss sound automatically
        emit(state.copyWith(
          combo: 0,
          totalNotes: state.totalNotes + 1,
        )); // Reset combo on miss
      }
    }
  }

  void _onPauseGame(PauseGame event, Emitter<GameBlocState> emit) {
    emit(state.copyWith(gameState: GameState.paused));
  }

  void _onResumeGame(ResumeGame event, Emitter<GameBlocState> emit) {
    emit(state.copyWith(gameState: GameState.playing));
  }

  void _onCompleteLevel(CompleteLevel event, Emitter<GameBlocState> emit) {
    emit(state.copyWith(
      gameState: GameState.gameOver,
      levelCompleted: true,
    ));
  }

  void _onExitGame(ExitGame event, Emitter<GameBlocState> emit) {
    // Clean up and return to initial state
    _levelNotes.clear();
    _noteIdCounter = 0;
    emit(const GameBlocState());
  }

  @override
  Future<void> close() {
    _soundService.stopAllSounds();
    _soundService.dispose();
    return super.close();
  }
}
