import 'package:drumly/screens/training/trraning_model.dart';
import 'package:drumly/services/song_service.dart';
import 'package:flutter/material.dart';

class TrainingViewModel extends ChangeNotifier {
  final SongService _songService = SongService();
  late BuildContext context;

  bool loading = false;
  final Map<String, List<TraningModel>> _levelBeats = {};
  final Map<String, int> _levelPages = {};
  final Set<String> _loadedLevels = {};
  final Map<String, bool> _hasMoreData = {}; // Track if level has more data

  static const int _pageSize = 20;

  List<TraningModel> getBeatsForLevel(String level) =>
      _levelBeats[level.toLowerCase()] ?? [];

  int getPage(String level) => _levelPages[level.toLowerCase()] ?? 0;

  bool isLevelLoaded(String level) =>
      _loadedLevels.contains(level.toLowerCase());

  bool hasMoreData(String level) => _hasMoreData[level.toLowerCase()] ?? true;

  Future<void> initBeginnerLevel() async {
    await fetchBeats(level: 'beginner', reset: true);
  }

  Future<void> fetchBeats({required String level, bool reset = false}) async {
    final key = level.toLowerCase();

    // Check if we already know there's no more data
    if (!reset && !hasMoreData(key)) {
      debugPrint('🛑 No more data available for level: $level');
      return;
    }

    // Prevent multiple simultaneous requests for the same level
    if (loading) {
      debugPrint('🚫 Already loading, skipping request for level: $level');
      return;
    }

    loading = true;
    notifyListeners();

    final currentPage = reset ? 0 : (_levelPages[key] ?? 0);

    try {
      final fetched = await _songService.getBeats(
        context,
        level: key,
        offset: currentPage * _pageSize,
      );

      // If no new data received, mark as no more data available
      if (fetched == null || fetched.isEmpty) {
        debugPrint(
            '📝 No more beats available for level: $level (empty response)');
        _hasMoreData[key] = false;
        return;
      }

      // If we got less than pageSize, probably no more data available
      if (fetched.length < _pageSize) {
        debugPrint(
            '📝 Received ${fetched.length} beats (less than $_pageSize), marking as complete for level: $level');
        _hasMoreData[key] = false;
      } else {
        _hasMoreData[key] = true;
      }

      if (reset) {
        _levelBeats[key] = fetched;
        _hasMoreData[key] = fetched.length >= _pageSize; // Reset the flag
      } else {
        if (!_levelBeats.containsKey(key)) {
          _levelBeats[key] = [];
        }
        _levelBeats[key]!.addAll(fetched);
      }

      _levelPages[key] = currentPage + 1;
      _loadedLevels.add(key);
      notifyListeners();
    } catch (e, st) {
      debugPrint('⚠️ fetchBeats($level) error: $e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<TraningModel> getBeatById(String beatId) async {
    if (beatId.isEmpty) {
      throw ArgumentError('Beat ID cannot be empty');
    }

    for (final entry in _levelBeats.entries) {
      final index = entry.value.indexWhere((beat) => beat.beatId == beatId);
      if (index != -1) {
        final existing = entry.value[index];
        if (existing.notes != null && existing.notes!.isNotEmpty) {
          debugPrint('✅ Beat already loaded with notes: $beatId');
          return existing;
        }

        // Notes eksik, yeniden yükle
        debugPrint('🔁 Beat loaded but missing notes. Reloading: $beatId');
        final updated = await _songService.getBeatById(context, beatId: beatId);
        if (updated == null) {
          throw Exception('Beat with ID $beatId not found');
        }

        _levelBeats[entry.key]![index] = updated;
        notifyListeners();
        return updated;
      }
    }

    // Hiç yüklü değilse
    debugPrint('🔄 Loading beat by ID for the first time: $beatId');
    final beat = await _songService.getBeatById(context, beatId: beatId);
    if (beat == null) {
      throw Exception('Beat with ID $beatId not found');
    }

    final level = beat.level!.toLowerCase();
    if (!_levelBeats.containsKey(level)) {
      _levelBeats[level] = [];
    }
    _levelBeats[level]!.add(beat);
    _loadedLevels.add(level);

    notifyListeners();
    return beat;
  }

  String formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
