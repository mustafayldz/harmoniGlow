import 'package:drumly/constants.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:hive/hive.dart';

/// Box adıyla bir Hive kutusuna kayıt edilecek.
Future<void> addRecord(String songId) async {
  final box = Hive.box(Constants.lockSongBox);

  // Şarkı ID'si anahtar olarak kullanılıyor, değer olarak oynatma zamanı kaydediliyor
  final timestamp = DateTime.now().toIso8601String();
  await box.put(songId, timestamp);
}

/// Süresi geçen kayıtları siler (2 saatten eski kayıtlar)
Future<void> cleanExpiredRecords() async {
  final box = Hive.box(Constants.lockSongBox);
  final now = DateTime.now();
  final keysToRemove = <dynamic>[];

  for (final key in box.keys) {
    final stored = box.get(key) as String;
    final createdAt = DateTime.parse(stored);

    if (now.difference(createdAt) > const Duration(hours: 2)) {
      keysToRemove.add(key);
    }
  }

  for (final key in keysToRemove) {
    await box.delete(key);
  }
}

/// Belirli bir şarkının tutup tutulmadığını kontrol etmek için örnek yardımcı
bool hasRecord(String songId) {
  final box = Hive.box(Constants.lockSongBox);
  return box.containsKey(songId);
}

///------------------------------------------------------

/// Beat maker için kayıt ekler
Future<void> saveBeatMakerModel(BeatMakerModel beat) async {
  final box = Hive.box<BeatMakerModel>(Constants.beatRecordsBox);
  await box.put(beat.beatId, beat);
}

/// Beat maker için kayıt var mı kontrol eder
List<BeatMakerModel> getAllBeatMakerRecords() {
  final box = Hive.box<BeatMakerModel>(Constants.beatRecordsBox);
  return box.values.toList();
}

/// Beat maker için kayıt siler
Future<void> deleteBeatMakerRecord(String beatId) async {
  final box = Hive.box<BeatMakerModel>(Constants.beatRecordsBox);
  await box.delete(beatId);
}

/// belirli bir beat id'ye göre kayıt getirir
BeatMakerModel? getBeatById(String beatId) {
  final box = Hive.box<BeatMakerModel>(Constants.beatRecordsBox);
  return box.get(beatId);
}
