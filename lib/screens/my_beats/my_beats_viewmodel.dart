import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';

class MyBeatsViewModel extends ChangeNotifier {
  List<BeatMakerModel> beats = [];
  List<dynamic> beatKeys = [];

  Future<void> loadBeats() async {
    final lazyBox = Hive.lazyBox<BeatMakerModel>(Constants.beatRecordsBox);
    final keys = lazyBox.keys.toList();
    final loadedBeats = <BeatMakerModel>[];

    for (var key in keys) {
      final beat = await lazyBox.get(key);
      if (beat != null) loadedBeats.add(beat);
    }

    beats = loadedBeats;
    beatKeys = keys;
    notifyListeners();
  }

  Future<void> deleteBeatAt(int index) async {
    final lazyBox = Hive.lazyBox<BeatMakerModel>(Constants.beatRecordsBox);
    final key = beatKeys[index];
    await lazyBox.delete(key);

    beats.removeAt(index);
    beatKeys.removeAt(index);
    notifyListeners();
  }
}
