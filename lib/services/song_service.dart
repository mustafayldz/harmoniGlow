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
  Future<List<SongModel>?> getSongs(BuildContext context) async {
    final String url = getBaseUrlSong();

    final List<SongModel> songs = <SongModel>[];

    try {
      final response =
          await RequestHelper.requestAsync(context, RequestType.get, url);

      if (response == null || response == '' || response.isEmpty) {
        return null;
      } else if (response.isNotEmpty && response != '') {
        json.decode(response)['data'].forEach((item) {
          songs.add(SongModel.fromJson(item));
        });
      }
      return songs;
    } catch (e) {
      debugPrint(e.toString());
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

  Future<List<TraningModel>?> getBeats(BuildContext context) async {
    final String url = getBaseUrlBeats();

    final List<TraningModel> beats = <TraningModel>[];

    try {
      final response =
          await RequestHelper.requestAsync(context, RequestType.get, url);

      if (response == null || response == '' || response.isEmpty) {
        return null;
      } else if (response.isNotEmpty && response != '') {
        json.decode(response)['data'].forEach((item) {
          beats.add(TraningModel.fromJson(item));
        });
      }
      return beats;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
