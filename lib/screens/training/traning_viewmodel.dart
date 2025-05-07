import 'package:drumly/mock_service/api_service.dart';
import 'package:drumly/screens/songs/songs_model.dart';
import 'package:flutter/material.dart';

class TrainingViewModel extends ChangeNotifier {
  final MockApiService _apiService = MockApiService();

  //–– State fields
  List<SongModel> beats = [];
  late final List<SongModel> beatsOriginal;
  List<String> genres = [];
  int selectedGenreIndex = 0;

  Future<void> fetchBeats() async {
    try {
      beats = (await _apiService.fetchAllBeats())!;
      beatsOriginal = beats;
      genres = (_apiService.fetchAllBeatGenres());
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching beats: $e');
    }
  }

  //–– Genre selection
  Future<void> selectGenre(int index) async {
    selectedGenreIndex = index;
    notifyListeners();

    if (index == 0) {
      beats = (await _apiService.fetchAllBeats())!;
    } else {
      // fetch by genre: assume API supports it
      beats = (await _apiService.fetchBeatsByGenre(genres[index - 1]))!;
    }
    notifyListeners();
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
