import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/hive/db_service.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/hive/models/note_model.dart';
import 'package:drumly/shared/common_functions.dart';

class DrumPadModel {
  // Size multiplier (1.0 = base size)

  DrumPadModel({
    required this.name,
    required this.soundFile,
    required this.color,
    required this.key,
    required this.imagePath,
    required this.size,
  });
  final String name;
  final String soundFile;
  final Color color;
  final String key;
  final String imagePath;
  final double size;
}

class VirtualDrumViewModel extends ChangeNotifier {
  // Player pool: 3 players per pad for polyphonic playback
  late List<List<AudioPlayer>> _playerPool; // 9 pads x 3 players each
  late List<int> _playerPoolIndex; // Track which player to use next
  late List<String> _soundFiles;
  late List<DrumPadModel> _drumPads;

  bool _isInitialized = false;
  List<int> _recordedSequence = [];
  List<NoteModel> _recordedNotes = [];
  bool _isRecording = false;
  bool _isPlayingRecording = false;
  DateTime? _recordingStartTime;
  String? _recordingId;

  final ValueNotifier<double> masterVolumeNotifier = ValueNotifier(0.8);
  final ValueNotifier<double> reverbNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> echoNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> bassBoostNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> pitchShiftNotifier = ValueNotifier(0.0);
  final ValueNotifier<Set<int>> activePadsNotifier = ValueNotifier({});
  final ValueNotifier<List<double>> waveformNotifier = ValueNotifier([]);
  final ValueNotifier<int> visualizationTypeNotifier = ValueNotifier(0);

  bool get isInitialized => _isInitialized;
  List<DrumPadModel> get drumPads => _drumPads;
  bool get isRecording => _isRecording;
  bool get isPlayingRecording => _isPlayingRecording;

  Future<void> initialize() async {
    try {
      print('🎵 Starting Virtual Drum initialization...');
      _initializeDrumPads();

      print('🔧 Initializing audio player pool...');

      _soundFiles = [
        'assets/sounds/kick.ogg',
        'assets/sounds/snare_hard.ogg',
        'assets/sounds/close_hihat.ogg',
        'assets/sounds/open_hihat.ogg',
        'assets/sounds/tom_1.ogg',
        'assets/sounds/tom_2.ogg',
        'assets/sounds/tom_floor.ogg',
        'assets/sounds/crash_2.ogg',
        'assets/sounds/ride_1.ogg',
      ];

      // Create player pool: 3 players per pad
      _playerPool = List.generate(
        9,
        (padIndex) => List.generate(
          3,
          (poolIndex) => AudioPlayer(),
        ),
      );

      _playerPoolIndex = List.filled(9, 0);

      print('📀 Loading drum sounds...');
      await _loadDrumSounds();
      _startWaveformUpdates();

      _isInitialized = true;
      notifyListeners();
      print('✅ Virtual Drum initialized successfully');
    } catch (e, stacktrace) {
      print('❌ Error initializing: $e\n$stacktrace');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadDrumSounds() async {
    try {
      for (int padIndex = 0; padIndex < _soundFiles.length; padIndex++) {
        final soundFile = _soundFiles[padIndex];
        final fileName = soundFile.split('/').last;
        print('  Loading $fileName...');

        try {
          // Load the same sound into all 3 players for this pad
          for (int poolIndex = 0; poolIndex < 3; poolIndex++) {
            final player = _playerPool[padIndex][poolIndex];
            await player.setAsset(soundFile);
            await player.setLoopMode(LoopMode.off);

            // Pre-configure player
            try {
              // Seek to start to pre-buffer
              await player.seek(Duration.zero);
              // Set default volume
              await player.setVolume(masterVolumeNotifier.value);
              print('    ✓ Player $poolIndex configured');
            } catch (e) {
              print('    ⚠️ Config error: $e');
            }
          }
          print('  ✓ $fileName loaded (3x player pool)');
        } catch (e) {
          print('  ✗ Failed to load $fileName: $e');
        }
      }
    } catch (e) {
      print('Error in _loadDrumSounds: $e');
    }
  }

  void _initializeDrumPads() {
    _drumPads = [
      // 0: Kick - Drum (scale: 0.3 in beat maker = 2.5x here)
      DrumPadModel(
        name: 'Kick',
        soundFile: 'assets/sounds/kick.ogg',
        color: const Color(0xFF1E3A8A),
        key: 'Q',
        imagePath: 'assets/images/classicDrum/c_kick.png',
        size: 3.5,
      ),

      // 1: Snare - Drum (scale: 0.13 in beat maker = 1.08x here)
      DrumPadModel(
        name: 'Snare',
        soundFile: 'assets/sounds/snare_hard.ogg',
        color: const Color(0xFF7C3AED),
        key: 'W',
        imagePath: 'assets/images/classicDrum/c_snare.png',
        size: 1.75,
      ),

      // 2: HiHat Close - Cymbal (scale: 0.12 in beat maker = 1.0x here)
      DrumPadModel(
        name: 'Hi-Hat\nClose',
        soundFile: 'assets/sounds/close_hihat.ogg',
        color: const Color(0xFFDC2626),
        key: 'E',
        imagePath: 'assets/images/classicDrum/c_hihat.png',
        size: 1,
      ),

      // 3: HiHat Open - Cymbal (scale: 0.12 in beat maker = 1.0x here)
      DrumPadModel(
        name: 'Hi-Hat\nOpen',
        soundFile: 'assets/sounds/open_hihat.ogg',
        color: const Color(0xFFEA580C),
        key: 'A',
        imagePath: 'assets/images/classicDrum/c_hihat.png',
        size: 1.75,
      ),

      // 4: Tom1 - Drum (scale: 0.13 in beat maker = 1.08x here)
      DrumPadModel(
        name: 'Tom 1',
        soundFile: 'assets/sounds/tom_1.ogg',
        color: const Color(0xFF0891B2),
        key: 'S',
        imagePath: 'assets/images/classicDrum/c_tom1.png',
        size: 1.75,
      ),

      // 5: Tom2 - Drum (scale: 0.15 in beat maker = 1.25x here)
      DrumPadModel(
        name: 'Tom 2',
        soundFile: 'assets/sounds/tom_2.ogg',
        color: const Color(0xFF059669),
        key: 'D',
        imagePath: 'assets/images/classicDrum/c_tom2.png',
        size: 1.75,
      ),

      // 6: Floor Tom - Drum (scale: 0.2 in beat maker = 1.67x here)
      DrumPadModel(
        name: 'Floor Tom',
        soundFile: 'assets/sounds/tom_floor.ogg',
        color: const Color(0xFF7C2D12),
        key: 'F',
        imagePath: 'assets/images/classicDrum/c_tom_floor.png',
        size: 2.25,
      ),

      // 7: Crash - Cymbal (scale: 0.17 in beat maker = 1.42x here)
      DrumPadModel(
        name: 'Crash',
        soundFile: 'assets/sounds/crash_2.ogg',
        color: const Color(0xFFCA8A04),
        key: 'Z',
        imagePath: 'assets/images/classicDrum/c_crash.png',
        size: 2.25,
      ),

      // 8: Ride - Cymbal (scale: 0.17 in beat maker = 1.42x here)
      DrumPadModel(
        name: 'Ride',
        soundFile: 'assets/sounds/ride_1.ogg',
        color: const Color(0xFF0F766E),
        key: 'X',
        imagePath: 'assets/images/classicDrum/c_ride.png',
        size: 2.25,
      ),
    ];
  }

  Future<void> playDrumSound(int padIndex) async {
    if (padIndex < 0 || padIndex >= _playerPool.length) return;

    // Mark pad as active (visual feedback)
    final newActivePads = Set<int>.from(activePadsNotifier.value);
    newActivePads.add(padIndex);
    activePadsNotifier.value = newActivePads;

    // Get current player and rotate to next
    final int playerIndex = _playerPoolIndex[padIndex];
    final player = _playerPool[padIndex][playerIndex];
    _playerPoolIndex[padIndex] = (playerIndex + 1) % 3;

    try {
      // Stop cleanly - wait for it
      await player.stop();

      // Set speed back to normal first
      await player.setSpeed(1.0);

      // Set volume
      await player.setVolume(masterVolumeNotifier.value);

      // Apply pitch shift if needed
      if (pitchShiftNotifier.value != 0) {
        final speed = 1.0 + (pitchShiftNotifier.value * 0.1);
        await player.setSpeed(speed);
      }

      // Seek to start
      await player.seek(Duration.zero);

      // Now play
      await player.play();

      // ✅ Record note if recording is active (Beat Maker pattern)
      if (_isRecording && _recordingStartTime != null) {
        final now = DateTime.now();
        final ms = now.difference(_recordingStartTime!).inMilliseconds;
        _recordedNotes.add(
          NoteModel(
            i: _recordedNotes.length + 1,
            sM: ms,
            eM: ms + 300,
            led: [padIndex],
          ),
        );
        print(
            '📝 Note recorded: pad $padIndex at ${ms}ms (total: ${_recordedNotes.length})');
      }

      // Apply effects if enabled
      _applyEffects(padIndex, _playerPool[padIndex]);
    } catch (e) {
      print('Error playing sound on pad $padIndex: $e');
    } finally {
      // Remove from active after playing
      final newActivePads = Set<int>.from(activePadsNotifier.value);
      newActivePads.remove(padIndex);
      activePadsNotifier.value = newActivePads;
    }
  }

  void _applyEffects(int padIndex, List<AudioPlayer> padPlayers) {
    // Echo effect
    if (echoNotifier.value > 0) {
      final delayMs = (echoNotifier.value * 400).toInt();
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (echoNotifier.value > 0) {
          try {
            // Rotate through the pad's player pool for echo
            final int playerIdx = _playerPoolIndex[padIndex];
            final echoPlayer = padPlayers[playerIdx];
            _playerPoolIndex[padIndex] = (playerIdx + 1) % 3;

            final echoVol =
                masterVolumeNotifier.value * (1.0 - echoNotifier.value);

            // Use fire-and-forget for effects (non-critical)
            echoPlayer.setVolume(echoVol).ignore();
            echoPlayer.play().ignore();
          } catch (e) {
            print('Echo err: $e');
          }
        }
      });
    }

    // Reverb effect
    if (reverbNotifier.value > 0) {
      for (int i = 1; i <= 2; i++) {
        final delayMs = (reverbNotifier.value * 120 * i).toInt();
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (reverbNotifier.value > 0) {
            try {
              // Rotate through the pad's player pool for reverb
              final int playerIdx = _playerPoolIndex[padIndex];
              final revPlayer = padPlayers[playerIdx];
              _playerPoolIndex[padIndex] = (playerIdx + 1) % 3;

              final revVol = masterVolumeNotifier.value *
                  (1.0 - (reverbNotifier.value * 0.3 * i));
              if (revVol > 0.05) {
                revPlayer.setVolume(revVol).ignore();
                revPlayer.play().ignore();
              }
            } catch (e) {
              print('Reverb err: $e');
            }
          }
        });
      }
    }
  }

  Future<void> stopDrumSound(int padIndex) async {
    if (padIndex < 0 || padIndex >= 9) return;
    try {
      // Stop all players in pool for this pad
      for (var player in _playerPool[padIndex]) {
        await player.stop();
      }
    } catch (e) {
      print('Error stopping: $e');
    }
  }

  Future<void> setMasterVolume(double value) async {
    masterVolumeNotifier.value = value;
    for (var padPlayers in _playerPool) {
      for (var player in padPlayers) {
        await player.setVolume(value);
      }
    }
  }

  void setReverb(double value) {
    reverbNotifier.value = value;
    print('🌊 Reverb set to: ${(value * 100).toStringAsFixed(0)}%');
  }

  void setEcho(double value) {
    echoNotifier.value = value;
    print('📢 Echo set to: ${(value * 100).toStringAsFixed(0)}%');
  }

  void setBassBoost(double value) {
    bassBoostNotifier.value = value;
    print('🔊 Bass Boost set to: ${(value * 100).toStringAsFixed(0)}%');
  }

  Future<void> setPitchShift(double value) async {
    pitchShiftNotifier.value = value;
    print('Pitch Shift set to: ${(value * 100).toStringAsFixed(0)}%');
    // Note: Pitch shift will be applied to newly played sounds only
    // It won't affect currently playing sounds
  }

  void setVisualizationType(int type) {
    visualizationTypeNotifier.value = type;
    print('Visualization type set to: $type');
    notifyListeners();
  }

  void recordStart() {
    startRecording();
  }

  void recordStop() {
    stopRecording();
  }

  void recordStopWithDialog(BuildContext context) {
    stopRecordingWithDialog(context);
  }

  void pauseRecording() {
    if (_isRecording) {
      _isRecording = false;
      print('⏸ Recording paused');
      notifyListeners();
    }
  }

  void startRecording() {
    _recordedSequence.clear();
    _recordedNotes.clear();
    _isRecording = true;
    _recordingStartTime = DateTime.now();
    _recordingId = DateTime.now().millisecondsSinceEpoch.toString();
    print('🔴 Recording started');
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    print('⏹ Recording stopped - ${_recordedSequence.length} pads');
    notifyListeners();
  }

  Future<void> stopRecordingWithDialog(BuildContext context) async {
    if (!_isRecording || _recordingStartTime == null) return;

    // Check context mounted
    if (!context.mounted) {
      print('⚠️ Context is no longer mounted');
      _isRecording = false;
      return;
    }

    try {
      if (_recordedNotes.isEmpty) {
        showClassicSnackBar(context, 'noNotesRecorded'.tr());
        _isRecording = false;
        return;
      }

      // Ask for title and genre
      final result = await _askForTitleAndGenre(context);
      if (result == null) {
        _isRecording = false;
        return;
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(_recordingStartTime!).inSeconds;
      final int noteCount = _recordedNotes.length;
      final int bpm =
          duration > 0 ? ((noteCount / duration) * 60).round() : 120;

      // Create beat model
      final beat = BeatMakerModel(
        beatId: _recordingId,
        title: result['title'],
        bpm: bpm,
        genre: result['genre'],
        rhythm: '4/4',
        durationSeconds: duration,
        fileUrl: '',
        createdAt: _recordingStartTime!,
        updatedAt: endTime,
        notes: _recordedNotes,
      );

      // Save to DB
      await saveBeatMakerModel(beat);

      _isRecording = false;
      _recordedNotes.clear();
      _recordedSequence.clear();

      if (context.mounted) {
        showClassicSnackBar(
          context,
          '${'beatSavedAs'.tr()}${beat.title} ($bpm BPM)',
        );
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      _isRecording = false;
    }
  }

  Future<Map<String, String>?> _askForTitleAndGenre(
    BuildContext context,
  ) async {
    if (!context.mounted) {
      print('⚠️ Context is no longer mounted, cannot show dialog');
      return null;
    }

    String title = '';
    String genre = '';
    String? titleError;
    String? genreError;

    try {
      return await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => MediaQuery.removeViewInsets(
          removeBottom: true,
          context: dialogContext,
          child: StatefulBuilder(
            builder: (builderContext, setState) => AlertDialog(
              title: Text('saveBeat'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'title'.tr(),
                      errorText: titleError,
                    ),
                    onChanged: (value) {
                      title = value.trim();
                      if (titleError != null && title.isNotEmpty) {
                        setState(() => titleError = null);
                      }
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'genre'.tr(),
                      errorText: genreError,
                    ),
                    onChanged: (value) {
                      genre = value.trim();
                      if (genreError != null && genre.isNotEmpty) {
                        setState(() => genreError = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    bool hasError = false;
                    if (title.isEmpty) {
                      setState(() => titleError = 'titleCantbeEmpty'.tr());
                      hasError = true;
                    }
                    if (genre.isEmpty) {
                      setState(() => genreError = 'genreCantbeEmpty'.tr());
                      hasError = true;
                    }
                    if (!hasError) {
                      Navigator.pop(
                        dialogContext,
                        {
                          'title': title,
                          'genre': genre,
                        },
                      );
                    }
                  },
                  child: Text('save'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error showing dialog: $e');
      return null;
    }
  }

  Future<void> playRecording() async {
    if (_recordedSequence.isEmpty) {
      print('No recording to play');
      return;
    }
    _isPlayingRecording = true;
    notifyListeners();
    print('Playing recording');

    try {
      for (int padIndex in _recordedSequence) {
        await playDrumSound(padIndex);
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      print('Error playing: $e');
    }
    _isPlayingRecording = false;
    notifyListeners();
  }

  void clearAll() {
    _recordedSequence.clear();
    _isRecording = false;
    _isPlayingRecording = false;
    activePadsNotifier.value = {};
    print('Cleared all');
    notifyListeners();
  }

  void _startWaveformUpdates() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final waveform = _generateWaveform();
      waveformNotifier.value = waveform;
    });
  }

  List<double> _generateWaveform() {
    const int points = 100;
    final List<double> data = [];
    const double pi = 3.14159265358979323846;

    for (int i = 0; i < points; i++) {
      final double phase = (i / points) * (2 * pi);
      final double value = _sin(phase).abs();
      data.add(value);
    }
    return data;
  }

  static double _sin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  Future<void> dispose() async {
    try {
      for (var padPlayers in _playerPool) {
        for (var player in padPlayers) {
          await player.dispose();
        }
      }
    } catch (e) {
      print('Error disposing: $e');
    }
    super.dispose();
  }
}
