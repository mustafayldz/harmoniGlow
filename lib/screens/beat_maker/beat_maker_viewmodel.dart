import 'dart:async';

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/hive/db_service.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/hive/models/note_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class BeatMakerViewmodel {
  final StorageService storageService = StorageService();
  final Map<String, AudioPlayer> _players = {};
  final Map<String, String> drumSounds = {
    'Hi-Hat': 'assets/sounds/open_hihat.wav',
    'Hi-Hat Closed': 'assets/sounds/closed_hihat.wav',
    'Crash Cymbal': 'assets/sounds/crash_2.wav',
    'Ride Cymbal': 'assets/sounds/ride_1.wav',
    'Snare Drum': 'assets/sounds/snare_hard.wav',
    'Tom 1': 'assets/sounds/tom_1.wav',
    'Tom 2': 'assets/sounds/tom_2.wav',
    'Tom Floor': 'assets/sounds/tom_floor.wav',
    'Kick Drum': 'assets/sounds/kick.wav',
  };

  bool _isRecording = false;
  String? _recordingId;
  DateTime? _recordingStartTime;
  final List<NoteModel> _recordedNotes = [];

  final List<String> _pendingDrumParts = [];
  DateTime? _lastTapTime;
  Timer? _recordTimer;

  Future<void> playSound(BuildContext context, String drumPart) async {
    final path = drumSounds[drumPart];
    if (path == null) return;

    final player = _players.putIfAbsent(drumPart, () => AudioPlayer());

    try {
      await player.stop();
      await player.setAsset(path);
      await player.play();

      final now = DateTime.now();

      // Eğer 120ms içinde değilsek, önceki grup kapanır
      if (_lastTapTime == null ||
          now.difference(_lastTapTime!).inMilliseconds > 120) {
        _pendingDrumParts.clear();
      }

      _lastTapTime = now;
      _pendingDrumParts.add(drumPart);

      // Timer'ı her seferinde sıfırla, böylece en son vuruştan sonra 120ms bekler
      _recordTimer?.cancel();
      _recordTimer = Timer(const Duration(milliseconds: 120), () async {
        // Tüm toplanan drumPart'lar için LED ve RGB bilgilerini al
        final ledList = <int>[];
        final rgbList = <List<int>>[];

        for (final part in _pendingDrumParts.toSet()) {
          final model =
              await StorageService.getDrumPart(getDrumPartId(part).toString());
          if (model?.led != null && model?.rgb != null) {
            ledList.add(model!.led!);
            rgbList.add(model.rgb!);
          }
        }

        // 🔥 Işıkları aynı anda yak
        final flatData = <int>[];
        for (int i = 0; i < ledList.length; i++) {
          flatData.add(ledList[i]); // LED numarası
          flatData.addAll(rgbList[i]); // RGB (3 değer)
        }
        await SendData().sendHexData(context.read<BluetoothBloc>(), flatData);

        // 🎵 Eğer kayıt açıksa, NoteModel olarak kaydet
        if (_isRecording && _recordingStartTime != null) {
          final ms = now.difference(_recordingStartTime!).inMilliseconds;

          _recordedNotes.add(
            NoteModel(
              i: _recordedNotes.length + 1,
              sM: ms,
              eM: ms + 300,
              led: ledList,
            ),
          );
        }

        _pendingDrumParts.clear(); // işlem bitti, sıradaki grup için hazırlık
      });
    } catch (e) {
      debugPrint('Error playing $drumPart: $e');
    }
  }

  Future<void> disposeAll() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }

  Future<void> startRecording() async {
    _isRecording = true;
    _recordingId = DateTime.now().millisecondsSinceEpoch.toString();
    _recordingStartTime = DateTime.now();
    _recordedNotes.clear();
  }

  Future<void> stopRecording(BuildContext context) async {
    if (!_isRecording || _recordingStartTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_recordingStartTime!).inSeconds;

    final result = await _askForTitleAndGenre(context);
    if (result == null) return;

    // 🎵 BPM hesapla: (noteCount / duration) * 60
    final int noteCount = _recordedNotes.length;
    final int bpm = duration > 0 ? ((noteCount / duration) * 60).round() : 120;

    final beat = BeatMakerModel(
      beatId: _recordingId,
      title: result['title'],
      bpm: bpm,
      genre: result['genre'] ?? 'unknown'.tr(),
      rhythm: '4/4',
      durationSeconds: duration,
      fileUrl: '',
      createdAt: _recordingStartTime!,
      updatedAt: endTime,
      notes: _recordedNotes,
    );

    await saveBeatMakerModel(beat);
    _isRecording = false;

    showClassicSnackBar(
      context,
      '${'beatSavedAs'.tr()}${beat.title} ($bpm BPM)',
    );
  }

  Future<Map<String, String>?> _askForTitleAndGenre(
    BuildContext context,
  ) async {
    String title = '';
    String genre = '';
    String? titleError;
    String? genreError;

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
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
                    title = value;
                    if (titleError != null && value.isNotEmpty) {
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
                    genre = value;
                    if (genreError != null && value.isNotEmpty) {
                      setState(() => genreError = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                      context,
                      {'title'.tr(): title, 'genre'.tr(): genre},
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
  }
}
