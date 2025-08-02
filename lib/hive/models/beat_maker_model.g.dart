
part of 'beat_maker_model.dart';


class BeatMakerModelAdapter extends TypeAdapter<BeatMakerModel> {
  @override
  final int typeId = 1;

  @override
  BeatMakerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BeatMakerModel(
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      id: fields[0] as String?,
      beatId: fields[1] as String?,
      bpm: fields[2] as int?,
      durationSeconds: fields[3] as int?,
      fileUrl: fields[4] as String?,
      genre: fields[5] as String?,
      notes: (fields[6] as List?)?.cast<NoteModel>(),
      rhythm: fields[7] as String?,
      title: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BeatMakerModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.beatId)
      ..writeByte(2)
      ..write(obj.bpm)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.fileUrl)
      ..writeByte(5)
      ..write(obj.genre)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.rhythm)
      ..writeByte(8)
      ..write(obj.title)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeatMakerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
