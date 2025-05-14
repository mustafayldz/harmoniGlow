import 'dart:convert';

import 'package:drumly/adMob/ad_service_reward.dart';
import 'package:drumly/hive/db_service.dart';
import 'package:drumly/services/local_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Capitalizes the first letter of a given string.
String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

/// Checks if a given string is a valid email address.
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  return emailRegex.hasMatch(email);
}

/// Formats a number with commas as thousand separators.
String formatWithCommas(int number) => number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );

/// Delays execution for a given number of milliseconds.
Future<void> delay(int milliseconds) async {
  await Future.delayed(Duration(milliseconds: milliseconds));
}

/// Splits an integer into two bytes (8 bits each).
List<int> splitToBytes(int value) {
  final low = value & 0xFF; // Alt 8 bit
  final high = (value >> 8) & 0xFF; // Üst 8 bit
  return [252, low, high];
}

/// sneakbar
void showAdConsentSnackBar(BuildContext context, String songId) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
      duration: const Duration(seconds: 10), // gösterim süresi
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To play this song for three hours, you first need to watch a support ad.',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Reddetme davranışı: SnackBar’ı kapat
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                style: TextButton.styleFrom(),
                child: const Text('Decline'),
              ),
              TextButton(
                onPressed: () async {
                  // Kabul etme davranışı: reklam göster
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  // Reklam gösterme fonksiyonunu çağır
                  final bool earned = await AdServiceReward().showRewardedAd();

                  if (earned) {
                    // Ödülü ver: 2 saatlik kilidi aç
                    await addRecord(songId); // kayıt ekle
                    showClassicSnackBar(context, 'Access opened for 2 hours.');
                  } else {
                    showClassicSnackBar(
                      context,
                      'Ad was not watched or an error occurred.',
                    );
                  }
                },
                style: TextButton.styleFrom(),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Decode the payload (middle segment) of a JWT into a Map.
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw const FormatException('Invalid JWT: must have 3 parts');
  }

  final normalized = base64Url.normalize(parts[1]);
  final payload = utf8.decode(base64Url.decode(normalized));
  return json.decode(payload) as Map<String, dynamic>;
}

/// Returns true if the token’s `exp` time (in seconds since epoch) is in the past.
bool isJwtExpired(String token) {
  try {
    final payload = decodeJwtPayload(token);
    final exp = payload['exp'];
    if (exp is! int) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    return DateTime.now().toUtc().isAfter(expiry);
  } catch (_) {
    // If decoding/parsing fails, treat it as expired
    return true;
  }
}

/// Gets a valid Firebase ID token, forcing a refresh if it’s expired.
Future<String> getValidFirebaseToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Not signed in');
  }
  final freshToken = await user.getIdToken(true);
  debugPrint('fresh token: $freshToken');
  await StorageService.saveFirebaseToken(freshToken!);

  return freshToken;
}

/// classic snackbar
void showClassicSnackBar(BuildContext context, String message) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
      duration: const Duration(seconds: 3), // gösterim süresi
      content: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    ),
  );
}

/// Return drum part id with drum part name

int getDrumPartId(String drumPartName) {
  switch (drumPartName) {
    case 'Hi-Hat':
      return 1;
    case 'Crash Cymbal':
      return 2;
    case 'Ride Cymbal':
      return 3;
    case 'Snare Drum':
      return 4;
    case 'Tom 1':
      return 5;
    case 'Tom 2':
      return 6;
    case 'Tom Floor':
      return 7;
    case 'Kick Drum':
      return 8;
    default:
      return 0;
  }
}
