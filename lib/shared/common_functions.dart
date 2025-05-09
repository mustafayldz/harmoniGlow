import 'package:drumly/adMob/ad_service_reward.dart';
import 'package:drumly/hive/db_service.dart';
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
void showAdConsentSnackBar(BuildContext context, int songId) {
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
                    await addRecord(songId.toString()); // kayıt ekle
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Başarılı! 2 saatlik erişim açıldı.'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reklam izlenmedi veya hata oluştu.'),
                      ),
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
