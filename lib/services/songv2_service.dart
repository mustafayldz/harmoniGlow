import 'dart:convert';
import 'package:drumly/constants.dart';
import 'package:drumly/models/songv2_model.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Map<String, dynamic>? _decodeSongDetail(String response) {
  final decoded = json.decode(response);
  if (decoded is! Map ||
      decoded['success'] != true ||
      decoded['data'] is! Map) {
    return null;
  }

  final data = Map<String, dynamic>.from(decoded['data'] as Map);
  final rawDt = data['dt'];
  if (rawDt is List) {
    final absoluteTimes = List<int>.filled(rawDt.length, 0);
    var time = 0;
    for (var index = 0; index < rawDt.length; index++) {
      time += (rawDt[index] as num).toInt();
      absoluteTimes[index] = time;
    }
    data['_abs_t'] = absoluteTimes;
  }
  return data;
}

class SongV2Service {
  String getBaseUrlSongV2() => ApiServiceUrl.endpoint('songs');

  /*----------------------------------------------------------------------
                  Get SongsV2 - Paginated list
----------------------------------------------------------------------*/
  Future<SongV2Response?> getSongsV2(
    BuildContext context, {
    int limit = 20,
    int offset = 0,
    String? artist,
    String? query,
  }) async {
    final String baseUrl = getBaseUrlSongV2();
    debugPrint('🎵 Fetching SongsV2 from: $baseUrl');

    try {
      final Map<String, String> queryParams = {
        'limit': '$limit',
        'offset': '$offset',
        if (artist != null && artist.isNotEmpty) 'artist': artist,
        if (query != null && query.isNotEmpty) 'q': query,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      debugPrint('🔗 Full URL: ${uri.toString()}');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        uri.toString(),
      );

      debugPrint(
        '📥 Response received: ${response?.substring(0, response.length > 200 ? 200 : response.length)}...',
      );

      if (response == null || response.isEmpty) {
        debugPrint('❌ Empty response from server');
        return null;
      }

      final decoded = json.decode(response);
      debugPrint('✅ Successfully decoded response');
      return SongV2Response.fromJson(decoded);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getSongsV2: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Get SongV2 by ID - Full details with chart
----------------------------------------------------------------------*/
  Future<SongV2Model?> getSongV2ById(
    BuildContext context,
    String songv2Id,
  ) async {
    final String url = '${getBaseUrlSongV2()}/$songv2Id';
    debugPrint('🎵 Fetching song by ID: $url');

    try {
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        url,
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      final data = response.length >= 75000
          ? await compute(_decodeSongDetail, response)
          : _decodeSongDetail(response);
      return data == null ? null : SongV2Model.fromJson(data);
    } catch (e) {
      debugPrint('Error in getSongV2ById: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Search SongsV2 - with relevance scoring
----------------------------------------------------------------------*/
  Future<SongV2Response?> searchSongsV2(
    BuildContext context, {
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final String url = getBaseUrlSongV2();
    debugPrint('🔍 Searching songs: $url with query: $query');

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
      return SongV2Response.fromJson(decoded);
    } catch (e) {
      debugPrint('Error in searchSongsV2: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Create SongV2 (Admin only)
----------------------------------------------------------------------*/
  Future<SongV2Model?> createSongV2(
    BuildContext context,
    Map<String, dynamic> songData,
  ) async {
    final String url = getBaseUrlSongV2();

    try {
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.post,
        url,
        songData,
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      final decoded = json.decode(response);
      if (decoded is Map &&
          decoded['success'] == true &&
          decoded['data'] != null) {
        return SongV2Model.fromJson(decoded['data']);
      }

      return null;
    } catch (e) {
      debugPrint('Error in createSongV2: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Update SongV2 (Admin only)
----------------------------------------------------------------------*/
  Future<SongV2Model?> updateSongV2(
    BuildContext context,
    String songv2Id,
    Map<String, dynamic> updateData,
  ) async {
    final String url = '${getBaseUrlSongV2()}/$songv2Id';

    try {
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        updateData,
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      final decoded = json.decode(response);
      if (decoded is Map &&
          decoded['success'] == true &&
          decoded['data'] != null) {
        return SongV2Model.fromJson(decoded['data']);
      }

      return null;
    } catch (e) {
      debugPrint('Error in updateSongV2: $e');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Delete SongV2 (Admin only)
----------------------------------------------------------------------*/
  Future<bool> deleteSongV2(
    BuildContext context,
    String songv2Id,
  ) async {
    final String url = '${getBaseUrlSongV2()}/$songv2Id';

    try {
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.delete,
        url,
      );

      if (response == null || response.isEmpty) {
        return false;
      }

      final decoded = json.decode(response);
      return decoded is Map && decoded['success'] == true;
    } catch (e) {
      debugPrint('Error in deleteSongV2: $e');
      return false;
    }
  }
}
