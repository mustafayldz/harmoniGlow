import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drumly/constants.dart';
import 'package:drumly/models/announcement_model.dart';
import 'package:flutter/foundation.dart';

class AnnouncementService {
  Future<List<AnnouncementModel>?> getAnnouncements({
    required String language,
  }) async {
    final uri = Uri.parse(ApiServiceUrl.endpoint('announcements')).replace(
      queryParameters: {'language': language},
    );
    final client = HttpClient();

    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: Constants.timeOutInterval));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request
          .close()
          .timeout(const Duration(seconds: Constants.timeOutInterval));
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: Constants.timeOutInterval));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Announcement request failed (${response.statusCode}): $body',
        );
        return null;
      }

      final decoded = json.decode(body);
      if (decoded is! Map<String, dynamic> ||
          decoded['success'] != true ||
          decoded['data'] is! List) {
        return null;
      }

      final announcements = (decoded['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(AnnouncementModel.fromJson)
          .where((announcement) => announcement.isActive)
          .toList();
      announcements.sort((a, b) => b.priority.compareTo(a.priority));
      return announcements;
    } on TimeoutException catch (error) {
      debugPrint('Announcement request timed out: $error');
      return null;
    } on SocketException catch (error) {
      debugPrint('Announcement network error: $error');
      return null;
    } on FormatException catch (error) {
      debugPrint('Announcement response parse error: $error');
      return null;
    } catch (error, stackTrace) {
      debugPrint('Announcement request error: $error\n$stackTrace');
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
