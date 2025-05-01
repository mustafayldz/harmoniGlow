import 'package:flutter/material.dart';
import 'package:harmoniglow/blocs/device/device_bloc.dart';
import 'package:harmoniglow/blocs/device/device_event.dart';
import 'package:harmoniglow/mock_service/api_service.dart';
import 'package:harmoniglow/screens/songs/songs_model.dart';

/// ViewModel following MVVM, holds state and business logic
class SongViewModel extends ChangeNotifier {
  List<SongModel> songList = [];

  final MockApiService _apiService = MockApiService();

  Future<void> fetchSongs() async {
    try {
      songList = await _apiService.fetchSongData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching songs: $e');
    }
  }

  Future<void> selectBeat(DeviceBloc deviceBloc, int index) async {
    if (songList.isNotEmpty) {
      try {
        deviceBloc.add(UpdateBeatDataEvent(songList[index]));
        notifyListeners();
      } catch (e, stack) {
        debugPrint('Error fetching beat: $e');
        debugPrint('$stack');
      }
    } else {
      debugPrint('No songs available to select.');
    }
  }

  /// Utility to format seconds into mm:ss
  String formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = secs.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }
}
