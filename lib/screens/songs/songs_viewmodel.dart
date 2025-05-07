import 'package:flutter/material.dart';
import 'package:drumly/mock_service/api_service.dart';
import 'package:drumly/screens/songs/songs_model.dart';

/// ViewModel following MVVM, holds state and business logic
class SongViewModel extends ChangeNotifier {
  List<SongModel> songList = [];
  List<SongModel> songListNew = [];

  final MockApiService _apiService = MockApiService();

  Future<void> fetchSongs() async {
    try {
      songListNew = await _apiService.fetchSongData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching songs: $e');
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
