import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drumly/constants.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/enums.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RequestHelper {
  static Future<String?> requestAsync(
    BuildContext context,
    RequestType requestType,
    String url, [
    dynamic body,
    int timeout = Constants.timeOutInterval,
  ]) async {
    debugPrint('request started: $url');
    final AppProvider appProvider =
        Provider.of<AppProvider>(context, listen: false);

    appProvider.setLoading(true);

    final StorageService storageService = StorageService();
    String? token = await storageService.getFirebaseToken();

    if (token != null && token.isNotEmpty) {
      if (isJwtExpired(token)) {
        token = await getValidFirebaseToken();
      }
    }

    debugPrint('request token: $token');

    final HttpClient client = HttpClient()
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);

    HttpClientResponse? response;
    try {
      switch (requestType) {
        case RequestType.post:
          final request = await client.postUrl(Uri.parse(url));

          request.headers.set('content-type', 'application/json');
          request.headers.set('accept', 'application/json');

          if (token != null && token.isNotEmpty) {
            request.headers.set('authorization', 'Bearer $token');
          }
          final jsonBody = json.encode(body);

          request.add(utf8.encode(jsonBody));

          response = await request.close().timeout(Duration(seconds: timeout));

          break;
        case RequestType.put:
          final request = await client.putUrl(Uri.parse(url));

          request.headers.set('content-type', 'application/json');
          request.headers.set('accept', 'application/json');
          if (token != null && token.isNotEmpty) {
            request.headers.set('authorization', 'Bearer $token');
          }
          final jsonBody = json.encode(body);

          request.add(utf8.encode(jsonBody));

          response = await request.close().timeout(Duration(seconds: timeout));
          break;
        case RequestType.get:
          final request = await client.getUrl(Uri.parse(url));
          request.headers.set('content-type', 'application/json-patch+json');
          // request.headers.set('accept', 'application/json');
          if (token != null && token.isNotEmpty) {
            request.headers.set('authorization', 'Bearer $token');
          }
          response = await request.close().timeout(Duration(seconds: timeout));
          break;
        case RequestType.delete:
          final request = await client.deleteUrl(Uri.parse(url));
          request.headers.set('content-type', 'application/json-patch+json');
          request.headers.set('accept', 'application/json');
          if (token != null && token.isNotEmpty) {
            request.headers.set('authorization', 'Bearer $token');
          }
          response = await request.close().timeout(Duration(seconds: timeout));
          break;
      }

      final String result = await response.transform(utf8.decoder).join();

      debugPrint('📊 Response status: ${response.statusCode}');
      debugPrint('📦 Response body: $result');

      // API dökümanına göre: 200-201 success, 400-404 client errors, 500+ server errors
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Request successful');
        appProvider.setLoading(false);
        return result;
      }

      switch (response.statusCode) {
        case 401:
          debugPrint('🔒 Unauthorized - Token may be invalid');
          break;
        case 400:
          debugPrint('⚠️ Bad Request');
          break;
        case 403:
          debugPrint('🚫 Forbidden - Insufficient permissions');
          break;
        case 404:
          debugPrint('🔍 Not Found');
          break;
        case 405:
          debugPrint('🚫 Method Not Allowed');
          break;
        case 500:
          debugPrint('💥 Internal Server Error');
          break;
        case 502:
          debugPrint('🌐 Bad Gateway');
          break;
        default:
          debugPrint('❓ Unexpected status code: ${response.statusCode}');
      }
      
      debugPrint('Response details: $result');
      appProvider.setLoading(false);
      return null;
    } on FormatException catch (e) {
      appProvider.setLoading(false);
      debugPrint('FormatException: $e');
      return null;
    } on SocketException catch (e) {
      appProvider.setLoading(false);
      debugPrint('SocketException: $e');
      return null;
    } on HttpException catch (e) {
      appProvider.setLoading(false);
      debugPrint('HttpException: $e');
      return null;
    } on TimeoutException catch (e) {
      appProvider.setLoading(false);
      debugPrint('TimeoutException: $e');
      return null;
    } catch (e) {
      appProvider.setLoading(false);
      debugPrint('Error: $e');
      return null;
    } finally {
      client.close();
    }
  }
}
