import 'package:drumly/constants.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:hive/hive.dart';

/// 🔒 Kullanıcının eriştiği şarkıların kilit kayıtları (LazyBox)

Future<void> addRecord(String songId) async {
  final lazyBox = Hive.lazyBox(Constants.lockSongBox);
  final timestamp = DateTime.now().toIso8601String();
  await lazyBox.put(songId, timestamp);
}

Future<void> cleanExpiredRecords() async {
  final lazyBox = Hive.lazyBox(Constants.lockSongBox);
  final now = DateTime.now();
  final keysToRemove = <dynamic>[];

  for (final key in lazyBox.keys) {
    final stored = await lazyBox.get(key);
    if (stored is String) {
      final createdAt = DateTime.tryParse(stored);
      if (createdAt != null &&
          now.difference(createdAt) > const Duration(minutes: 1)) {
        // now.difference(createdAt) > const Duration(hours: 2)) {
        keysToRemove.add(key);
      }
    }
  }

  for (final key in keysToRemove) {
    await lazyBox.delete(key);
  }
}

bool hasRecord(String songId) {
  final lazyBox = Hive.lazyBox(Constants.lockSongBox);
  return lazyBox.containsKey(songId);
}

/// 🥁 BeatMaker kayıt işlemleri (LazyBox ile)

Future<void> saveBeatMakerModel(BeatMakerModel beat) async {
  final lazyBox = Hive.lazyBox<BeatMakerModel>(Constants.beatRecordsBox);
  await lazyBox.put(beat.beatId, beat);
}

Future<List<BeatMakerModel>> getAllBeatMakerRecords() async {
  final lazyBox = Hive.lazyBox<BeatMakerModel>(Constants.beatRecordsBox);
  final keys = lazyBox.keys;
  final List<BeatMakerModel> beats = [];

  for (final key in keys) {
    final beat = await lazyBox.get(key);
    if (beat != null) beats.add(beat);
  }

  return beats;
}

Future<void> deleteBeatMakerRecord(String beatId) async {
  final lazyBox = Hive.lazyBox<BeatMakerModel>(Constants.beatRecordsBox);
  await lazyBox.delete(beatId);
}

Future<BeatMakerModel?> getBeatById(String beatId) async {
  final lazyBox = Hive.lazyBox<BeatMakerModel>(Constants.beatRecordsBox);
  return await lazyBox.get(beatId);
}
