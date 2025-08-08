import 'package:drumly/constants.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 SharedPreferences tabanlı unlock sistemi
Future<void> addRecord(String songId) async {
  final prefs = await SharedPreferences.getInstance();
  final unlockTimeKey = 'unlock_time_$songId';
  final currentTime = DateTime.now().millisecondsSinceEpoch;

  await prefs.setInt(unlockTimeKey, currentTime);
}

/// 🥁 BeatMaker kayıt işlemleri (LazyBox ile)

bool hasRecord(String songId) {
  final lazyBox = Hive.lazyBox(Constants.lockSongBox);
  return lazyBox.containsKey(songId);
}

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
