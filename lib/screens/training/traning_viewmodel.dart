import 'package:drumly/models/song_types_model.dart';
import 'package:drumly/screens/training/trraning_model.dart';
import 'package:drumly/services/song_service.dart';
import 'package:flutter/material.dart';

class TrainingViewModel extends ChangeNotifier {
  // final MockApiService _apiService = MockApiService();
  final SongService _songService = SongService();

  late BuildContext context;

  //–– State fields
  List<TraningModel> beats = [];
  late final List<TraningModel> beatsOriginal;

  List<SongTypeModel> genres = [];
  int selectedGenreIndex = 0;

  Future<void> fetchBeats() async {
    try {
      beats = (await _songService.getBeats(context))!;
      beatsOriginal = beats;
      genres = (await _songService.getSongTypes(context))!;
      genres.insert(0, SongTypeModel(id: '0', name: 'All'));
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
      beats = beatsOriginal;
    } else {
      // fetch by genre: assume API supports it
      beats = beatsOriginal
          .where((beat) => beat.genre == genres[index].name)
          .toList();
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
