import 'drum_note.dart';

class SongChart {
  final String songName;
  final String artist;
  final int bpm;
  final int durationMs;
  final String difficulty;
  final String audioPath;
  final List<DrumNote> notes;

  SongChart({
    required this.songName,
    required this.artist,
    required this.bpm,
    required this.durationMs,
    required this.difficulty,
    required this.audioPath,
    required this.notes,
  });
}
