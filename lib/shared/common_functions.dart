import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drumly/adMob/ad_service_reward.dart';
import 'package:drumly/services/local_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

String formatWithCommas(int number) => number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );

Future<void> delay(int milliseconds) async {
  await Future.delayed(Duration(milliseconds: milliseconds));
}

List<int> splitToBytes(int value) {
  final low = value & 0xFF; // Alt 8 bit
  final high = (value >> 8) & 0xFF; // Üst 8 bit
  return [252, low, high];
}

Future<bool> showAdConsentSnackBar(BuildContext context, String songId) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final completer = Completer<bool>();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
      duration: const Duration(seconds: 10),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'toPlayThisSong'.tr(),
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
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  completer.complete(false); // ❌ Kullanıcı reddetti
                },
                child: const Text('decline').tr(),
              ),
              TextButton(
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  final adService = AdServiceReward();
                  final bool earned =
                      await adService.showRewardedAdWithConfetti(context);

                  if (earned) {
                    // 🎁 SharedPreferences'e unlock zamanını kaydet
                    final prefs = await SharedPreferences.getInstance();
                    final unlockTimeKey = 'unlock_time_$songId';
                    final currentTime = DateTime.now().millisecondsSinceEpoch;
                    await prefs.setInt(unlockTimeKey, currentTime);

                    showClassicSnackBar(context, 'accessOpenedFor'.tr());
                    completer.complete(true); // ✅ Kullanıcı izledi
                  } else {
                    showClassicSnackBar(
                      context,
                      'adNotWatchedOrErrorOccurred'.tr(),
                    );
                    completer
                        .complete(false); // ❌ Kullanıcı izlemeyi tamamlamadı
                  }
                },
                child: const Text('accept').tr(),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  return completer.future; // Burada sonucu döndürür
}

Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw const FormatException('Invalid JWT: must have 3 parts');
  }

  final normalized = base64Url.normalize(parts[1]);
  final payload = utf8.decode(base64Url.decode(normalized));
  return json.decode(payload) as Map<String, dynamic>;
}

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

void showTopSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // Ekle
  overlay.insert(entry);

  // 3 saniye sonra kaldır
  Future.delayed(const Duration(seconds: 3), () {
    entry.remove();
  });
}

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

Color getRandomColor(bool isDark) {
  final double threshold = isDark ? 0.7 : 0.3;

  Color color;
  do {
    color = Color.fromARGB(
      255,
      Random().nextInt(256),
      Random().nextInt(256),
      Random().nextInt(256),
    );
  } while (isDark
          ? color.computeLuminance() < threshold // want bright colors
          : color.computeLuminance() > threshold // want dark colors
      );

  return color;
}

String capitalizeFirst(String text) {
  if (text.isEmpty) return '';
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
