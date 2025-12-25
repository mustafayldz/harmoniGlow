import 'package:drumly/models/songv2_model.dart';
import 'package:drumly/services/songv2_service.dart';
import 'package:flutter/material.dart';

class SongV2ViewModel extends ChangeNotifier {
  final SongV2Service _songV2Service = SongV2Service();
  late BuildContext context;

  List<SongV2Model> _songs = [];
  int limit = 100;
  int _offset = 0;
  int? _total;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _activeQuery;

  List<SongV2Model> get songs => _songs;
  int? get total => _total;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  void init(BuildContext ctx) {
    context = ctx;
  }

  Future<void> fetchInitialSongs() async {
    _offset = 0;
    _hasMore = true;
    _songs = [];
    _activeQuery = null;
    _total = null;
    await _fetchSongs();
  }

  Future<void> fetchInitialSongsWithQuery({String? query}) async {
    _offset = 0;
    _hasMore = true;
    _songs = [];
    _activeQuery = query?.trim().isEmpty ?? true ? null : query!.trim();
    _total = null;
    await _fetchSongs(query: _activeQuery);
  }

  Future<void> fetchMoreSongs() async {
    if (_isLoading || !_hasMore) return;
    await _fetchSongs(query: _activeQuery);
  }

  Future<void> _fetchSongs({String? query}) async {
    debugPrint('🔄 Starting _fetchSongs - offset: $_offset, query: $query');
    _isLoading = true;
    notifyListeners();

    try {
      SongV2Response? response;

      if (query != null && query.trim().isNotEmpty) {
        debugPrint('🔍 Using search API');
        // Search API
        response = await _songV2Service.searchSongsV2(
          context,
          query: query,
          limit: limit,
          offset: _offset,
        );
      } else {
        debugPrint('📋 Using list API');
        // List API
        response = await _songV2Service.getSongsV2(
          context,
          limit: limit,
          offset: _offset,
        );
      }

      debugPrint('📦 Response received - success: ${response?.success}, data count: ${response?.data?.length}');

      if (response != null && response.success && response.data != null) {
        final newSongs = response.data!;
        debugPrint('✅ Adding ${newSongs.length} songs to list');
        _songs.addAll(newSongs);
        _offset += limit;
        _total = response.total;
        
        // Check if there are more songs
        if (newSongs.length < limit || (_total != null && _songs.length >= _total!)) {
          _hasMore = false;
          debugPrint('🏁 No more songs available');
        }
      } else {
        debugPrint('⚠️ Response is null or unsuccessful');
        _hasMore = false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching songs: $e');
      debugPrint('Stack trace: $stackTrace');
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ _fetchSongs completed - total songs: ${_songs.length}');
    }
  }

  Future<SongV2Model?> getSongById(String songv2Id) async {
    try {
      return await _songV2Service.getSongV2ById(context, songv2Id);
    } catch (e) {
      debugPrint('Error getting song by id: $e');
      return null;
    }
  }

  void clearSongs() {
    _songs = [];
    _offset = 0;
    _hasMore = true;
    _activeQuery = null;
    _total = null;
    notifyListeners();
  }
}
