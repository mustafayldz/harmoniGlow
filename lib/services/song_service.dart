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

  /*----------------------------------------------------------------------
                  Get Songs
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
      };

      // Final URL oluştur
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await RequestHelper.requestAsync(
          context, RequestType.get, uri.toString());

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
