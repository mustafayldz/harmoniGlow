import 'package:hive/hive.dart';

/// Box adıyla bir Hive kutusuna kayıt edilecek.
Future<void> addRecord(String songId) async {
  final box = Hive.box('recordsBox');

  // Şarkı ID'si anahtar olarak kullanılıyor, değer olarak oynatma zamanı kaydediliyor
  final timestamp = DateTime.now().toIso8601String();
  await box.put(songId, timestamp);
}

/// Süresi geçen kayıtları siler (3 saatten eski kayıtlar)
Future<void> cleanExpiredRecords() async {
  final box = Hive.box('recordsBox');
  final now = DateTime.now();
  final keysToRemove = <dynamic>[];

  for (final key in box.keys) {
    final stored = box.get(key) as String;
    final createdAt = DateTime.parse(stored);

    if (now.difference(createdAt) > const Duration(hours: 3)) {
      keysToRemove.add(key);
    }
  }

  for (final key in keysToRemove) {
    await box.delete(key);
  }
}

/// Belirli bir şarkının tutup tutulmadığını kontrol etmek için örnek yardımcı
bool hasRecord(String songId) {
  final box = Hive.box('recordsBox');
  return box.containsKey(songId);
}
