import '../../core/enums/drum_type.dart';

class DrumNote {
  final int id;
  final DrumType drumType;
  final double spawnTime; // milliseconds from song start
  final int lane; // 0-4 for staff lines
  final double yPosition; // current screen position

  DrumNote({
    required this.id,
    required this.drumType,
    required this.spawnTime,
    required this.lane,
    this.yPosition = 0.0,
  });

  DrumNote copyWith({double? yPosition}) {
    return DrumNote(
      id: id,
      drumType: drumType,
      spawnTime: spawnTime,
      lane: lane,
      yPosition: yPosition ?? this.yPosition,
    );
  }
}
