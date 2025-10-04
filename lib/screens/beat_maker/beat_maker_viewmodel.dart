import 'dart:async';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/hive/db_service.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/hive/models/note_model.dart';
import 'package:drumly/screens/beat_maker/just_audio_drum_manager.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BeatMakerViewmodel {
  final StorageService storageService = StorageService();
  final JustAudioDrumManager drumManager = JustAudioDrumManager(); // Singleton

  bool _isRecording = false;
  String? _recordingId;
  DateTime? _recordingStartTime;
  final List<NoteModel> _recordedNotes = [];

  final List<String> _pendingDrumParts = [];
  DateTime? _lastTapTime;
  Timer? _recordTimer;

  bool _disposed = false;

  Future<void> playSound(BuildContext context, String drumPart) async {
    if (_disposed || drumPart.trim().isEmpty) return;

    await drumManager.reinitialize();

    // ✅ Önce sesi çal - await olmadan hemen çal
    drumManager.play(drumPart); // await kaldırıldı
    debugPrint('▶️ Playing: $drumPart');

    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!).inMilliseconds > 50) {
      _pendingDrumParts.clear();
    }

    _lastTapTime = now;
    _pendingDrumParts.add(drumPart);

    _recordTimer?.cancel();
    _recordTimer = Timer(const Duration(milliseconds: 50), () async {
      if (_disposed) return; // ✅ Dispose kontrolü eklendi

      final ledList = <int>[];
      final rgbList = <List<int>>[];

      for (final part in _pendingDrumParts.toSet()) {
        try {
          final model =
              await StorageService.getDrumPart(getDrumPartId(part).toString());
          if (model?.led != null && model?.rgb != null) {
            ledList.add(model!.led!);
            rgbList.add(model.rgb!);
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching drum part model for $part: $e');
        }
      }

      final flatData = <int>[];
      for (int i = 0; i < ledList.length; i++) {
        flatData.add(ledList[i]);
        flatData.addAll(rgbList[i]);
      }

      if (_disposed) return; // ✅ Dispose kontrolü eklendi

      try {
        // ✅ Context'in hala geçerli olup olmadığını kontrol et
        if (!context.mounted) {
          debugPrint(
            '⚠️ Context is no longer mounted, skipping bluetooth send',
          );
          return;
        }

        final bloc = context.read<BluetoothBloc>();
        if (bloc.characteristic == null) {
          debugPrint('❌ Error: No connected device or characteristic.');
        } else {
          await SendData().sendHexData(bloc, flatData);
        }
      } catch (e) {
        debugPrint('❌ Bluetooth send error: $e');
      }

      if (_isRecording && _recordingStartTime != null && !_disposed) {
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

      _pendingDrumParts.clear();
    });
  }

  Future<void> disposeAll() async {
    _disposed = true;
    _recordTimer?.cancel();
    _recordTimer = null;

    await drumManager.dispose(); // 🎯 Yeni eklenen: tüm player'ları temizle
  }

  Future<void> startRecording() async {
    if (_disposed) return; // ✅ Dispose kontrolü eklendi

    try {
      _isRecording = true;
      _recordingId = DateTime.now().millisecondsSinceEpoch.toString();
      _recordingStartTime = DateTime.now();
      _recordedNotes.clear();
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      _isRecording = false;
    }
  }

  Future<void> stopRecording(BuildContext context) async {
    if (!_isRecording || _recordingStartTime == null || _disposed) return;

    // ✅ Context mounted kontrolü
    if (!context.mounted) {
      debugPrint(
        '⚠️ Context is no longer mounted, stopping recording silently',
      );
      _isRecording = false;
      return;
    }

    try {
      if (_recordedNotes.isEmpty) {
        showClassicSnackBar(context, 'noNotesRecorded'.tr());
        _isRecording = false;
        return;
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(_recordingStartTime!).inSeconds;

      final result = await _askForTitleAndGenre(context);
      if (result == null) {
        _isRecording = false;
        return;
      }

      final int noteCount = _recordedNotes.length;
      final int bpm =
          duration > 0 ? ((noteCount / duration) * 60).round() : 120;

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

      await saveBeatMakerModel(beat);

      _isRecording = false;

      if (context.mounted) {
        showClassicSnackBar(
          context,
          '${'beatSavedAs'.tr()}${beat.title} ($bpm BPM)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      _isRecording = false;
      if (context.mounted) {
        showClassicSnackBar(context, 'Error saving beat: $e');
      }
    }
  }

  Future<Map<String, String>?> _askForTitleAndGenre(
    BuildContext context,
  ) async {
    // ✅ Context mounted kontrolü
    if (!context.mounted) {
      debugPrint('⚠️ Context is no longer mounted, cannot show dialog');
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
      debugPrint('❌ Error showing dialog: $e');
      return null;
    }
  }
}
