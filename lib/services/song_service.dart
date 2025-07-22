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

  // YENİ: API'ya uygun endpoint'ler
  String getMyAssignedSongsUrl() => '${ApiServiceUrl.user}me/songs';

  // Debug metodu - URL'leri kontrol et
  void debugUrls() {
    debugPrint('🔗 Base Song URL: ${getBaseUrlSong()}');
    debugPrint('🔗 My Assigned Songs URL: ${getMyAssignedSongsUrl()}');
    debugPrint('🔗 Beat URL: ${getBaseUrlBeats()}');
  }

  /*----------------------------------------------------------------------
                  Get Songs - API dokümantasyonuna uygun
----------------------------------------------------------------------*/
  Future<List<SongModel>?> getSongs(
    BuildContext context, {
    int limit = 20,
    int offset = 0,
    String? userId,
    String? songTypeId,
    String? query,
    String? artist,
  }) async {
    final String baseUrl = getBaseUrlSong(); // "/api/songs/"
    final List<SongModel> songs = <SongModel>[];

    try {
      // API dokümantasyonuna göre query parametreleri
      final Map<String, String> queryParams = {
        'limit': '$limit',
        'page': '${(offset / limit).floor() + 1}', // offset'i page'e çevir
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
        if (songTypeId != null && songTypeId.isNotEmpty)
          'song_type_id': songTypeId,
        // Arama için query veya artist kullan
        if (query != null && query.isNotEmpty) 'q': query,
        if (artist != null && artist.isNotEmpty) 'artist': artist,
      };

      // Final URL oluştur
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      debugPrint('🔗 Songs URL: ${uri.toString()}');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        uri.toString(),
      );

      if (response == null || response.isEmpty) {
        debugPrint('❌ Songs: Empty or null response');
        return null;
      }

      final decoded = json.decode(response);
      if (decoded is Map && decoded.containsKey('data')) {
        for (var item in decoded['data']) {
          songs.add(SongModel.fromJson(item));
        }
        debugPrint('📦 Songs: Found ${songs.length} songs');
      }
      return songs;
    } catch (e) {
      debugPrint('❌ Error in getSongs: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Search Songs - API'daki /api/songs endpoint'ini kullan
----------------------------------------------------------------------*/
  Future<List<SongModel>?> searchSongs(
    BuildContext context, {
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    // API dokümantasyonuna göre /songs endpoint'ini query parametresi ile kullan
    return getSongs(
      context,
      limit: limit,
      offset: offset,
      query: query,
    );
  }

  /*----------------------------------------------------------------------
                  Get My Assigned Songs - YENİ /api/users/me/songs
----------------------------------------------------------------------*/
  Future<List<SongModel>?> getMyAssignedSongs(BuildContext context) async {
    final String url = getMyAssignedSongsUrl();
    final List<SongModel> songs = <SongModel>[];

    try {
      debugPrint('👤 Getting my assigned songs from: $url');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        url,
      );

      if (response == null || response.isEmpty) {
        debugPrint('❌ My songs: Empty or null response');
        return null;
      }

      debugPrint('✅ My songs: Response received (${response.length} chars)');
      final decoded = json.decode(response);

      if (decoded is Map && decoded.containsKey('data')) {
        for (var item in decoded['data']) {
          songs.add(SongModel.fromJson(item));
        }
        debugPrint('📦 My songs: Found ${songs.length} songs');
      }
      return songs;
    } catch (e) {
      debugPrint('❌ Error in getMyAssignedSongs: $e');
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
                  Get Beats - API dokümantasyonuna uygun
----------------------------------------------------------------------*/
  Future<List<TraningModel>?> getBeats(
    BuildContext context, {
    String? level,
    int limit = 20,
    int offset = 0,
  }) async {
    final String baseUrl = getBaseUrlBeats(); // "/api/beats/"

    try {
      // API dokümantasyonuna göre query parametreleri
      final Map<String, String> queryParams = {
        'limit': '$limit',
        'page': '${(offset / limit).floor() + 1}', // offset'i page'e çevir
        if (level != null && level.isNotEmpty) 'level': level,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      debugPrint('🔗 Beats URL: ${uri.toString()}');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        uri.toString(),
      );

      if (response != null && response.isNotEmpty) {
        final decoded = json.decode(response);
        if (decoded is Map && decoded.containsKey('data')) {
          return List<TraningModel>.from(
            decoded['data'].map((x) => TraningModel.fromJson(x)),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error in getBeats: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get Beat By ID - API dokümantasyonuna uygun
----------------------------------------------------------------------*/
  Future<TraningModel?> getBeatById(
    BuildContext context, {
    required String beatId,
  }) async {
    final String url = '${getBaseUrlBeats()}$beatId';

    try {
      debugPrint('🔗 Beat ID URL: $url');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        url,
      );

      if (response != null && response.isNotEmpty) {
        final decoded = json.decode(response);

        // API standardized response format'ını kontrol et
        if (decoded is Map) {
          if (decoded.containsKey('data')) {
            return TraningModel.fromJson(
              decoded['data'] as Map<String, dynamic>,
            );
          } else {
            // Direkt beat objesi dönmüş olabilir
            return TraningModel.fromJson(decoded as Map<String, dynamic>);
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error in getBeatById: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get Song By ID - API dokümantasyonuna uygun
----------------------------------------------------------------------*/
  Future<SongModel?> getSongById(
    BuildContext context, {
    required String songId,
  }) async {
    final String url = '${getBaseUrlSong()}$songId';

    try {
      debugPrint('🔗 Song ID URL: $url');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        url,
      );

      if (response != null && response.isNotEmpty) {
        final decoded = json.decode(response);

        // API standardized response format'ını kontrol et
        if (decoded is Map) {
          if (decoded.containsKey('data')) {
            return SongModel.fromJson(decoded['data'] as Map<String, dynamic>);
          } else {
            // Direkt song objesi dönmüş olabilir
            return SongModel.fromJson(decoded as Map<String, dynamic>);
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error in getSongById: $e');
      return null;
    }
  }
}
