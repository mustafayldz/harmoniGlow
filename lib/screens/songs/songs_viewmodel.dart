import 'package:drumly/services/song_service.dart';
import 'package:flutter/material.dart';
import 'package:drumly/screens/songs/songs_model.dart';

/// ViewModel following MVVM, holds state and business logic
class SongViewModel extends ChangeNotifier {
  final SongService _songService = SongService();

  late BuildContext context;

  List<SongModel> songList = [];
  List<SongModel> songListNew = [];

  Future<void> fetchSongs(BuildContext context) async {
    try {
      context = context;
      await _songService.getSongs(context).then((songs) {
        if (songs != null) {
          songList = songs;
          songListNew = songs; // Keep a copy for filtering
        } else {
          songList = [];
          songListNew = [];
        }
      });
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
