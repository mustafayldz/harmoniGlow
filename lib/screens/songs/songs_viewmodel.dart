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
  List<SongModel> _popularSongs = [];
  List<String> _suggestions = [];
  int limit = 20;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingPopular = false;
  bool _isLoadingSuggestions = false;
  String? _activeQuery;

  List<SongModel> get songs => _songs;
  List<SongModel> get popularSongs => _popularSongs;
  List<String> get suggestions => _suggestions;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  void init(BuildContext ctx) {
    context = ctx;
    // Debug URL'leri kontrol et
    _songService.debugUrls();
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
      List<SongModel>? result;

      if (query != null && query.trim().isNotEmpty) {
        // Yeni search API'sini kullan
        result = await _songService.searchSongs(
          context,
          query: query,
          limit: limit,
          offset: _offset,
        );
      } else {
        // Popüler şarkıları getir
        result = await _songService.getPopularSongs(
          context,
          limit: limit,
          offset: _offset,
        );
      }

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

  /// 🔥 Popüler şarkıları getir
  Future<void> fetchPopularSongs() async {
    _isLoadingPopular = true;
    notifyListeners();

    try {
      final result = await _songService.getPopularSongs(
        context,
        limit: 10,
        offset: 0,
      );
      if (result != null) {
        _popularSongs = result;
      }
    } catch (e) {
      debugPrint('🔥 Popular songs fetch error: \$e');
    }

    _isLoadingPopular = false;
    notifyListeners();
  }

  /// 💡 Arama önerileri getir
  Future<void> fetchSuggestions(String query) async {
    if (query.trim().length < 2) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      final result = await _songService.getSearchSuggestions(
        context,
        query: query.trim(),
        limit: 10,
      );
      if (result != null) {
        _suggestions = result;
      }
    } catch (e) {
      debugPrint('💡 Suggestions fetch error: \$e');
    }

    _isLoadingSuggestions = false;
    notifyListeners();
  }

  void clearSongs() {
    _songs = [];
    _offset = 0;
    _hasMore = true;
    _activeQuery = null;
    _suggestions = [];
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestions = [];
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

  /*----------------------------------------------------------------------
                          Assigned Songs Management
  ----------------------------------------------------------------------*/

  /// User'ın assigned song ID'leri ile şarkıları filtrele
  List<SongModel> getAssignedSongs(List<dynamic> assignedSongIds) {
    if (assignedSongIds.isEmpty) return [];

    return _songs
        .where((song) => assignedSongIds.contains(song.songId))
        .toList();
  }

  /// Assigned songs için özel data fetch
  Future<void> fetchAssignedSongs(List<dynamic> assignedSongIds) async {
    if (assignedSongIds.isEmpty) return;

    debugPrint('🎵 Fetching assigned songs: ${assignedSongIds.length} IDs');

    // Tüm şarkılar yüklenmemişse önce onları yükle
    if (_songs.isEmpty) {
      await fetchInitialSongs();
    }

    notifyListeners();
  }

  /// Assigned songs ile ilgili debug bilgisi
  void debugAssignedSongs(List<dynamic> assignedSongIds) {
    debugPrint('🔍 Assigned Song IDs: $assignedSongIds');
    debugPrint('🔍 Total Songs Loaded: ${_songs.length}');

    final foundSongs = getAssignedSongs(assignedSongIds);
    debugPrint('🔍 Found Assigned Songs: ${foundSongs.length}');

    for (final song in foundSongs) {
      debugPrint('   ✅ ${song.title} (${song.songId})');
    }
  }
}
