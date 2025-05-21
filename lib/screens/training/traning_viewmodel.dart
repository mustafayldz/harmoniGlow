import 'package:drumly/models/song_types_model.dart';
import 'package:drumly/screens/training/trraning_model.dart';
import 'package:drumly/services/song_service.dart';
import 'package:flutter/material.dart';

class TrainingViewModel extends ChangeNotifier {
  final SongService _songService = SongService();

  late BuildContext context;

  //–– UI State
  bool loading = false;
  List<TraningModel> beats = [];
  List<TraningModel> beatsOriginal = [];

  List<SongTypeModel> genres = [];
  int selectedGenreIndex = 0;

  /// ––– Fetch beats & genres
  Future<void> fetchBeats() async {
    loading = true;
    notifyListeners();

    try {
      final fetchedBeats = await _songService.getBeats(context);
      final fetchedGenres = await _songService.getSongTypes(context);

      beats = fetchedBeats ?? [];
      beatsOriginal = List.from(beats); // avoid reference link
      genres = fetchedGenres ?? [];

      // Add "All" genre at the start
      genres.insert(0, SongTypeModel(id: '0', name: 'All'));
    } catch (e, st) {
      debugPrint('⚠️ Error fetching beats: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// ––– Genre selection filter
  Future<void> selectGenre(int index) async {
    selectedGenreIndex = index;
    notifyListeners();

    if (index == 0) {
      // All genres
      beats = List.from(beatsOriginal);
    } else {
      final selectedGenreName = genres[index].name;
      beats = beatsOriginal
          .where(
            (beat) =>
                beat.genre?.toLowerCase().trim() ==
                selectedGenreName?.toLowerCase().trim(),
          )
          .toList();
    }

    notifyListeners();
  }

  /// ––– Format seconds to mm:ss
  String formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
