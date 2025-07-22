import 'dart:convert';

import 'package:drumly/constants.dart';
import 'package:drumly/models/song_request_model.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:flutter/material.dart';

class SongRequestService {
  String getBaseUrl() => '${ApiServiceUrl.baseUrl}song-requests/';
  String getMyRequestsUrl() => '${ApiServiceUrl.baseUrl}song-requests/my';

  /// Debug URL'leri kontrol et
  void debugUrls() {
    debugPrint('🔗 Song Request URL: ${getBaseUrl()}');
    debugPrint('🔗 My Requests URL: ${getMyRequestsUrl()}');
  }

  /// Get available status filter options
  static List<String> getStatusOptions() =>
      ['pending', 'approved', 'rejected', 'completed'];

  /// Get available priority options
  static List<String> getPriorityOptions() => ['low', 'normal', 'high'];

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

      if (response != null && response.isNotEmpty) {
        try {
          final responseData = json.decode(response);
          if (responseData['success'] == true) {
            debugPrint('✅ Song request created successfully');
            return true;
          } else {
            debugPrint('❌ Song request failed: ${responseData['message']}');
            return false;
          }
        } catch (jsonError) {
          debugPrint('❌ JSON parsing error: $jsonError');
          debugPrint('❌ Raw response: $response');
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
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final String baseUrl = getMyRequestsUrl(); // Use /song-requests/my endpoint

    try {
      // Query parametrelerini URL'e ekle (API dokümantasyonuna göre)
      final Map<String, String> queryParams = {
        'limit': '$limit',
        'offset': '$offset',
        if (status != null && status.isNotEmpty) 'status': status,
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

      if (response != null && response.isNotEmpty) {
        final responseData = json.decode(response);
        debugPrint('🔍 Raw response data: $responseData');

        if (responseData['success'] == true) {
          // Handle different response formats
          final dynamic rawData = responseData['data'];
          debugPrint('🔍 Raw data type: ${rawData.runtimeType}');
          debugPrint('🔍 Raw data content: $rawData');

          List<dynamic> dataList;
          if (rawData is List) {
            // Direct list of requests
            dataList = rawData;
            debugPrint(
                '🔍 Processing as direct list with ${dataList.length} items');
          } else if (rawData is Map<String, dynamic>) {
            // Nested response with results/items field
            debugPrint('🔍 Processing as Map, keys: ${rawData.keys.toList()}');
            if (rawData.containsKey('data')) {
              // API returns nested structure: data.data
              dataList = rawData['data'] ?? [];
              debugPrint(
                  '🔍 Found nested data field with ${dataList.length} items');
            } else if (rawData.containsKey('results')) {
              dataList = rawData['results'] ?? [];
              debugPrint(
                  '🔍 Found results field with ${dataList.length} items');
            } else if (rawData.containsKey('items')) {
              dataList = rawData['items'] ?? [];
              debugPrint('🔍 Found items field with ${dataList.length} items');
            } else if (rawData.containsKey('song_requests')) {
              dataList = rawData['song_requests'] ?? [];
              debugPrint(
                  '🔍 Found song_requests field with ${dataList.length} items');
            } else {
              // Assume the map itself is a single request
              dataList = [rawData];
              debugPrint('🔍 Treating map as single request');
            }
          } else {
            debugPrint('❌ Unexpected data format: ${rawData.runtimeType}');
            return null;
          }

          // Debug: İlk item'ı detaylı incele
          if (dataList.isNotEmpty) {
            debugPrint('🔍 First item in dataList: ${dataList.first}');
            debugPrint('🔍 First item type: ${dataList.first.runtimeType}');
            if (dataList.first is Map<String, dynamic>) {
              final firstMap = dataList.first as Map<String, dynamic>;
              debugPrint('🔍 First item keys: ${firstMap.keys.toList()}');
              debugPrint('🔍 song_title value: "${firstMap['song_title']}"');
              debugPrint('🔍 artist_name value: "${firstMap['artist_name']}"');
              debugPrint('🔍 description value: "${firstMap['description']}"');
            }
          }

          final requests = dataList.map(
            (json) {
              debugPrint('🔍 Processing JSON item: $json');
              final request =
                  SongRequestModel.fromJson(json as Map<String, dynamic>);
              debugPrint(
                  '🔍 Created model - songTitle: "${request.songTitle}", artistName: "${request.artistName}"');
              return request;
            },
          ).toList();

          debugPrint('✅ Fetched ${requests.length} song requests');
          return requests;
        } else {
          debugPrint(
            '❌ Failed to fetch song requests: ${responseData['message']}',
          );
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
