import 'dart:convert';

import 'package:drumly/constants.dart';
import 'package:drumly/models/song_request_model.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:flutter/material.dart';

class SongRequestService {
  String getBaseUrl() => '${ApiServiceUrl.song}request';

  /// Debug URL'leri kontrol et
  void debugUrls() {
    debugPrint('🔗 Song Request URL: ${getBaseUrl()}');
  }

  /*----------------------------------------------------------------------
                          Create Song Request
  ----------------------------------------------------------------------*/
  Future<bool> createSongRequest(
    BuildContext context,
    SongRequestModel request,
  ) async {
    final String url = getBaseUrl();

    try {
      debugPrint('🎵 Creating song request to: $url');
      debugPrint('🎵 Request data: ${request.toJson()}');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.post,
        url,
        request.toJson(),
      );

      if (response != null) {
        final responseData = json.decode(response);
        if (responseData['success'] == true) {
          debugPrint('✅ Song request created successfully');
          return true;
        } else {
          debugPrint('❌ Song request failed: ${responseData['message']}');
          return false;
        }
      } else {
        debugPrint('❌ Song request failed: No response');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Song request error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  /*----------------------------------------------------------------------
                          Get User's Song Requests
  ----------------------------------------------------------------------*/
  Future<List<SongRequestModel>?> getUserSongRequests(
    BuildContext context, {
    String? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final String baseUrl = getBaseUrl();

    try {
      // Query parametrelerini URL'e ekle
      final Map<String, String> queryParams = {
        'limit': '$limit',
        'offset': '$offset',
        if (userId != null) 'user_id': userId,
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final String url = '$baseUrl?$queryString';

      debugPrint('🎵 Fetching user song requests from: $url');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.get,
        url,
      );

      if (response != null) {
        final responseData = json.decode(response);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] ?? [];
          final requests =
              data.map((json) => SongRequestModel.fromJson(json)).toList();

          debugPrint('✅ Fetched ${requests.length} song requests');
          return requests;
        } else {
          debugPrint(
              '❌ Failed to fetch song requests: ${responseData['message']}');
          return null;
        }
      } else {
        debugPrint('❌ Failed to fetch song requests: No response');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Fetch song requests error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                          Update Song Request Status
  ----------------------------------------------------------------------*/
  Future<bool> updateSongRequestStatus(
    BuildContext context, {
    required String requestId,
    required String status,
  }) async {
    final String url = '$getBaseUrl()/$requestId';

    try {
      debugPrint('🎵 Updating song request status: $url');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        {
          'status': status,
        },
      );

      if (response != null) {
        final responseData = json.decode(response);
        if (responseData['success'] == true) {
          debugPrint('✅ Song request status updated to: $status');
          return true;
        } else {
          debugPrint('❌ Failed to update status: ${responseData['message']}');
          return false;
        }
      } else {
        debugPrint('❌ Failed to update status: No response');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Update status error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }
}
