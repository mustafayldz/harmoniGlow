import 'dart:convert';

import 'package:drumly/constants.dart';
import 'package:drumly/models/song_types_model.dart';
import 'package:drumly/screens/songs/songs_model.dart';
import 'package:drumly/screens/training/trraning_model.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:flutter/material.dart';

class SongService {
  String getBaseUrlSong() => ApiServiceUrl.song;
  String getBaseUrlSongTypes() => ApiServiceUrl.songTypes;
  String getBaseUrlBeats() => ApiServiceUrl.beat;

  // Yeni endpoint'ler için base URL'ler
  String getSearchUrl() => '${ApiServiceUrl.song}search';
  String getSuggestionsUrl() => '${ApiServiceUrl.song}suggestions';
  String getPopularUrl() => '${ApiServiceUrl.song}popular';

  // Debug metodu - URL'leri kontrol et
  void debugUrls() {
    debugPrint('🔗 Search URL: ${getSearchUrl()}');
    debugPrint('🔗 Suggestions URL: ${getSuggestionsUrl()}');
    debugPrint('🔗 Popular URL: ${getPopularUrl()}');
    debugPrint('🔗 Base Song URL: ${getBaseUrlSong()}');
  }

  /*----------------------------------------------------------------------
                  Get Songs (Eski method - backward compatibility)
----------------------------------------------------------------------*/
  Future<List<SongModel>?> getSongs(
    BuildContext context, {
    int limit = 20,
    int offset = 0,
    int? songtypeId,
    String? artist,
    String? query,
  }) async {
    final String baseUrl = getBaseUrlSong(); // e.g., "/api/songs"
    final List<SongModel> songs = <SongModel>[];

    try {
      // Query parametrelerini dinamik olarak oluştur
      final Map<String, String> queryParams = {
        'limit': '$limit',
        'offset': '$offset',
        if (songtypeId != null) 'songtype_id': '$songtypeId',
        if (artist != null && artist.isNotEmpty) 'artist': artist,
        if (query != null && query.isNotEmpty) 'q': query,
        // Arama terimini sanatçı parametresi olarak da gönder
        if (query != null && query.isNotEmpty) 'artist': query,
      };

      // Final URL oluştur
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        uri.toString(),
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      final decoded = json.decode(response);
      if (decoded is Map && decoded.containsKey('data')) {
        for (var item in decoded['data']) {
          songs.add(SongModel.fromJson(item));
        }
      }
      return songs;
    } catch (e) {
      debugPrint('❌ Error in getSongs: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Search Songs - YENİ /api/songs/search
----------------------------------------------------------------------*/
  Future<List<SongModel>?> searchSongs(
    BuildContext context, {
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final String url = getSearchUrl();
    final List<SongModel> songs = <SongModel>[];

    try {
      debugPrint('🔍 Searching for: "$query" (limit: $limit, offset: $offset)');

      final Map<String, String> queryParams = {
        'q': query,
        'limit': '$limit',
        'offset': '$offset',
      };

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      debugPrint('🔗 Full URL: ${uri.toString()}');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        uri.toString(),
      );

      if (response == null || response.isEmpty) {
        debugPrint('❌ Search: Empty or null response');
        return null;
      }

      debugPrint('✅ Search: Response received (${response.length} chars)');
      final decoded = json.decode(response);
      if (decoded is Map && decoded.containsKey('data')) {
        for (var item in decoded['data']) {
          songs.add(SongModel.fromJson(item));
        }
        debugPrint('📦 Search: Found ${songs.length} songs');
      }
      return songs;
    } catch (e) {
      debugPrint('❌ Error in searchSongs: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get Search Suggestions - YENİ /api/songs/suggestions
----------------------------------------------------------------------*/
  Future<List<String>?> getSearchSuggestions(
    BuildContext context, {
    required String query,
    int limit = 10,
    int offset = 0,
  }) async {
    final String url = getSuggestionsUrl();

    try {
      final Map<String, String> queryParams = {
        'q': query,
        'limit': '$limit',
        'offset': '$offset',
      };

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        uri.toString(),
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      final decoded = json.decode(response);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      } else if (decoded is Map && decoded.containsKey('data')) {
        return (decoded['data'] as List)
            .map((item) => item.toString())
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error in getSearchSuggestions: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get Popular Songs - YENİ /api/songs/popular
----------------------------------------------------------------------*/
  Future<List<SongModel>?> getPopularSongs(
    BuildContext context, {
    int limit = 20,
    int offset = 0,
  }) async {
    final String url = getPopularUrl();
    final List<SongModel> songs = <SongModel>[];

    try {
      debugPrint('🔥 Getting popular songs (limit: $limit, offset: $offset)');

      final Map<String, String> queryParams = {
        'limit': '$limit',
        'offset': '$offset',
      };

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      debugPrint('🔗 Popular URL: ${uri.toString()}');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        uri.toString(),
      );

      if (response == null || response.isEmpty) {
        debugPrint('❌ Popular: Empty or null response');
        return null;
      }

      debugPrint('✅ Popular: Response received (${response.length} chars)');
      final decoded = json.decode(response);
      if (decoded is Map && decoded.containsKey('data')) {
        for (var item in decoded['data']) {
          songs.add(SongModel.fromJson(item));
        }
        debugPrint('📦 Popular: Found ${songs.length} songs');
      }
      return songs;
    } catch (e) {
      debugPrint('❌ Error in getPopularSongs: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get Songs Types
----------------------------------------------------------------------*/

  Future<List<SongTypeModel>?> getSongTypes(BuildContext context) async {
    final String url = getBaseUrlSongTypes();

    final List<SongTypeModel> songTypes = <SongTypeModel>[];

    try {
      final response =
          await RequestHelper.requestAsync(context, RequestType.get, url);

      if (response == null || response == '' || response.isEmpty) {
        return null;
      } else if (response.isNotEmpty && response != '') {
        json.decode(response).forEach((item) {
          songTypes.add(SongTypeModel.fromJson(item));
        });
      }
      return songTypes;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get Beats
----------------------------------------------------------------------*/

  Future<List<TraningModel>?> getBeats(
    BuildContext context, {
    String? level,
    int limit = 20,
    int offset = 0,
  }) async {
    final String url =
        '${getBaseUrlBeats()}?level=$level&limit=$limit&offset=$offset';

    try {
      final response =
          await RequestHelper.requestAsync(context, RequestType.get, url);

      if (response != null && response.isNotEmpty) {
        return List<TraningModel>.from(
          json.decode(response)['data'].map((x) => TraningModel.fromJson(x)),
        );
      }
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get Beat By ID
----------------------------------------------------------------------*/
  Future<TraningModel?> getBeatById(
    BuildContext context, {
    required String beatId,
  }) async {
    final String url = '${getBaseUrlBeats()}$beatId';

    try {
      final response =
          await RequestHelper.requestAsync(context, RequestType.get, url);

      if (response != null && response.isNotEmpty) {
        return TraningModel.fromJson(json.decode(response));
      }
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get Song By ID
----------------------------------------------------------------------*/

  Future<SongModel?> getSongById(
    BuildContext context, {
    required String songId,
  }) async {
    final String url = '${getBaseUrlSong()}$songId';

    try {
      final response =
          await RequestHelper.requestAsync(context, RequestType.get, url);

      if (response != null && response.isNotEmpty) {
        return SongModel.fromJson(json.decode(response));
      }
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
