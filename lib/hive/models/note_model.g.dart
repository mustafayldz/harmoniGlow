
part of 'note_model.dart';


class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 2;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      i: fields[0] as int,
      sM: fields[1] as int,
      eM: fields[2] as int,
      led: (fields[3] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.i)
      ..writeByte(1)
      ..write(obj.sM)
      ..writeByte(2)
      ..write(obj.eM)
      ..writeByte(3)
      ..write(obj.led);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
