import 'dart:convert';

import 'package:drumly/constants.dart';
import 'package:drumly/screens/training/trraning_model.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:flutter/material.dart';

class BeatService {
  String getBaseUrlBeats() => ApiServiceUrl.beat;

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
      return null;
    }
  }

}
