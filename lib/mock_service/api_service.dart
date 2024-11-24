import 'package:harmoniglow/models/shuffle_model.dart';
import 'package:harmoniglow/models/traning_model.dart';

class MockApiService {
  /// Fetches beat data based on the beat index or retrieves a default generated notes set.
  Future<TraningModel> fetchBeatData({int? beatIndex}) async {
    // Decide which notes to fetch: parametric beats or default generated notes

    // Get beat info if not using default notes
    Map<String, dynamic> beatInfo = _getBeatInfo(beatIndex ?? 0);

    return TraningModel.fromJson(beatInfo);
  }

  Future<TraningModel> fetchSongData({int? songIndex}) async {
    // Decide which notes to fetch: parametric beats or default generated notes

    // Get beat info if not using default notes
    Map<String, dynamic> songInfo = _getSongInfo(songIndex ?? 0);

    return TraningModel.fromJson(songInfo);
  }

  /// Retrieves beat metadata based on the index
  Map<String, dynamic> _getBeatInfo(int index) {
    List<Map<String, dynamic>> beatInfoList = [
      {
        "name": "Basic Rock Beat",
        "rhythm": "4:4",
        "bpm": 100,
        "totalTime": 10,
        "notes": [
          [1],
          [2],
          [1, 2],
          [2],
          [1],
          [1, 2],
          [1],
          [2],
          [1],
          [99]
        ]
      },
      {
        "name": "Basic Pop Beat",
        "rhythm": "4:4",
        "bpm": 50,
        "totalTime": 10,
        "notes": [
          [1, 3],
          [-1],
          [3],
          [-1],
          [1, 2, 3],
          [-1],
          [1, 3],
          [-1],
          [2, 3],
          [-1],
          [99]
        ]
      },
      {
        "name": "Disco Beat",
        "rhythm": "4:4",
        "bpm": 130,
        "totalTime": 25,
        "notes": [
          [1],
          [2],
          [3],
          [4],
          [1],
          [2],
          [3],
          [4],
          [1],
          [99],
          [1],
          [2],
          [3],
          [4],
          [1],
          [6],
          [1, 2],
          [2],
          [1, 2],
          [99],
          [1],
          [3, 4],
          [2],
          [1, 4],
          [1],
          [6],
          [1, 2],
          [2, 3],
          [1, 2],
          [99],
          [1],
          [2],
          [2],
          [1],
          [1],
          [6],
          [1, 2],
          [2],
          [1, 2],
          [99],
        ]
      },
      {
        "name": "Funk Beat",
        "rhythm": "4:4",
        "bpm": 110,
        "totalTime": 10,
        "notes": [
          [1, 3],
          [-1],
          [3],
          [-1],
          [1, 2, 3],
          [-1],
          [3],
          [1, 3],
          [2, 3],
          [99]
        ]
      },
      {
        "name": "Shuffle Beat",
        "rhythm": "4:4",
        "bpm": 90,
        "totalTime": 10,
        "notes": [
          [1, 3],
          [-1],
          [2, 3],
          [-1],
          [1, 3],
          [-1],
          [2, 3],
          [-1],
          [99]
        ]
      },
      {
        "name": "16th Note Groove",
        "rhythm": "4:4",
        "bpm": 140,
        "totalTime": 10,
        "notes": [
          [1, 3],
          [3],
          [3],
          [2, 3],
          [3],
          [1, 3],
          [3],
          [2, 3],
          [99]
        ]
      },
      {
        "name": "Half-Time Groove",
        "rhythm": "4:4",
        "bpm": 80,
        "totalTime": 30,
        "notes": [
          [1, 3],
          [-1],
          [9],
          [-1],
          [2, 3],
          [-9],
          [3],
          [-1],
          [1, 8],
          [-1],
          [3],
          [-7],
          [2, 3],
          [-1],
          [3],
          [-1],
          [1, 3],
          [-1],
          [3],
          [-1],
          [2, 3],
          [-1],
          [3],
          [-1],
          [1, 3],
          [-1],
          [3],
          [-1],
          [2, 3],
          [-1],
          [3],
          [-1],
          [1, 3],
          [-1],
          [3],
          [-1],
          [2, 3],
          [-1],
          [3],
          [-1],
          [1, 3],
          [-1],
          [3],
          [-1],
          [2, 3],
          [-1],
          [3],
          [-1],
          [99]
        ]
      },
      {
        "name": "Reggae Beat",
        "rhythm": "4:4",
        "bpm": 70,
        "totalTime": 10,
        "notes": [
          [1],
          [-4],
          [-1],
          [4],
          [2],
          [-4],
          [-1],
          [4],
          [99]
        ]
      },
      {
        "name": "Jazz Swing Beat",
        "rhythm": "4:4",
        "bpm": 110,
        "totalTime": 10,
        "notes": [
          [1, 5],
          [-1],
          [2, 5],
          [-1],
          [1, 5],
          [-1],
          [2, 5],
          [-1],
          [99]
        ]
      },
      {
        "name": "Bossa Nova Beat",
        "rhythm": "4:4",
        "bpm": 120,
        "totalTime": 40,
        "notes": [
          [1],
          [2],
          [3],
          [4],
          [5],
          [6],
          [7],
          [8],
          [99],
          [1, 2],
          [2, 3],
          [3, 4],
          [4, 5],
          [5, 6],
          [6, 7],
          [7, 8],
          [8, 1],
          [99],
          [1, 2, 3],
          [2, 3, 4],
          [3, 4, 5],
          [4, 5, 6],
          [5, 6, 7],
          [6, 7, 8],
          [7, 8, 1],
          [8, 1, 2],
          [99],
        ]
      }
    ];

    return beatInfoList[index];
  }

  /// Fetches all beat names
  List<String> fetchAllBeatNames() {
    return [
      "Basic Rock Beat",
      "Basic Pop Beat",
      "Disco Beat",
      "Funk Beat",
      "Shuffle Beat",
      "16th Note Groove",
      "Half-Time Groove",
      "Reggae Beat",
      "Jazz Swing Beat",
      "Bossa Nova Beat"
    ];
  }

  List<String> fetchAllSongNames() {
    return ["Duman - Öyle dertli", "Duman - Senden Daha Güzel"];
  }

  /// Retrieves beat metadata based on the index
  Map<String, dynamic> _getSongInfo(int index) {
    List<Map<String, dynamic>> beatSongList = [
      {
        "name": "Öyle dertli",
        "rhythm": "4:4",
        "bpm": 95,
        "totalTime": 300,
        "notes": [
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [2, 3],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [1, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [4, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9],
          [2],
          [3],
          [2, 3, 9]
        ]
      },
      {
        "name": "Senden Daha Güzel",
        "rhythm": "4:4",
        "bpm": 50,
        "totalTime": 10,
        "notes": [
          [1, 3],
          [-1],
          [3],
          [-1],
          [1, 2, 3],
          [-1],
          [1, 3],
          [-1],
          [2, 3],
          [-1],
          [99]
        ]
      },
    ];

    return beatSongList[index];
  }

  /*----------------------------------------------------------------------
                  Shuffle List
----------------------------------------------------------------------*/
  Future<List<ShuffleModel>?> getShuffleList() async {
    List<ShuffleModel> shuffleList = [
      ShuffleModel(
        name: "Basic Rock Beat",
        color: "0xFFB71C1C", // Dark Red
        bpm: 100,
      ),
      ShuffleModel(
        name: "Basic Pop Beat",
        color: "0xFF4CAF50", // Green
        bpm: 50,
      ),
      ShuffleModel(
        name: "Disco Beat",
        color: "0xFFFFC107", // Amber
        bpm: 130,
      ),
      ShuffleModel(
        name: "Funk Beat",
        color: "0xFF9C27B0", // Purple
        bpm: 110,
      ),
      ShuffleModel(
        name: "Shuffle Beat",
        color: "0xFF2196F3", // Blue
        bpm: 90,
      ),
      ShuffleModel(
        name: "16th Note Groove",
        color: "0xFFFF5722", // Deep Orange
        bpm: 140,
      ),
      ShuffleModel(
        name: "Half-Time Groove",
        color: "0xFF795548", // Brown
        bpm: 80,
      ),
      ShuffleModel(
        name: "Reggae Beat",
        color: "0xFF8BC34A", // Light Green
        bpm: 70,
      ),
      ShuffleModel(
        name: "Jazz Swing Beat",
        color: "0xFF3F51B5", // Indigo
        bpm: 110,
      ),
      ShuffleModel(
        name: "Bossa Nova Beat",
        color: "0xFFFF9800", // Orange
        bpm: 120,
      ),
    ];

    return shuffleList;
  }
}
