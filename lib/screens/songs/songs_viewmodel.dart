// 📁 song_viewmodel.dart
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/services/song_service.dart';
import 'package:flutter/material.dart';
import 'package:drumly/screens/songs/songs_model.dart';
import 'package:provider/provider.dart';

class SongViewModel extends ChangeNotifier {
  final SongService _songService = SongService();
  late BuildContext context;

  List<SongModel> _songs = [];
  int limit = 20;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _activeQuery;

  List<SongModel> get songs => _songs;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  void init(BuildContext ctx) {
    context = ctx;
  }

  Future<void> fetchInitialSongsWithCache(BuildContext ctx) async {
    context = ctx;
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (appProvider.cachedSongs.isNotEmpty) {
      _songs = List.from(appProvider.cachedSongs);
      _offset = _songs.length;
      _hasMore = _songs.length >= limit; // ✅ sadece daha fazla varsa
      _activeQuery = null;
      notifyListeners();
      return;
    }

    await fetchInitialSongs();
    appProvider.cacheSongs(_songs);
  }

  Future<void> fetchInitialSongs() async {
    _offset = 0;
    _hasMore = true;
    _songs = [];
    _activeQuery = null;
    await _fetchSongs();
  }

  Future<void> fetchInitialSongsWithQuery({String? query}) async {
    _offset = 0;
    _hasMore = true;
    _songs = [];
    _activeQuery = query?.trim().isEmpty ?? true ? null : query!.trim();
    await _fetchSongs(query: _activeQuery);
  }

  Future<void> fetchMoreSongs() async {
    if (_isLoading || !_hasMore) return;
    await _fetchSongs(query: _activeQuery);
  }

  Future<void> _fetchSongs({String? query}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _songService.getSongs(
        context,
        limit: limit,
        offset: _offset,
        query: query,
      );
      if (result != null && result.isNotEmpty) {
        _songs.addAll(result);
        _offset += limit;
        if (result.length < limit) _hasMore = false;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('🎵 Song fetch error: \$e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearSongs() {
    _songs = [];
    _offset = 0;
    _hasMore = true;
    _activeQuery = null;
    notifyListeners();
  }

  Future<SongModel?> fetchSongDetail(String songId) async =>
      await _songService.getSongById(context, songId: songId);

  String formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = secs.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }
}
