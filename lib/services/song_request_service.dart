import 'dart:convert';

import 'package:drumly/constants.dart';
import 'package:drumly/models/song_request_model.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:flutter/material.dart';

class SongRequestService {
  String get _baseUrl => ApiServiceUrl.endpoint('users/me/song-requests');

  Future<SongRequestModel?> createSongRequest(
    BuildContext context,
    SongRequestModel request,
  ) async {
    final response = await RequestHelper.requestAsync(
      context,
      RequestType.post,
      _baseUrl,
      request.toCreateJson(),
    );
    if (response == null || response.isEmpty) return null;

    try {
      final decoded = json.decode(response);
      if (decoded is Map<String, dynamic> &&
          decoded['success'] == true &&
          decoded['data'] is Map<String, dynamic>) {
        return SongRequestModel.fromJson(
          decoded['data'] as Map<String, dynamic>,
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
