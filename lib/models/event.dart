import 'package:hive/hive.dart';

// part 'event.g.dart'; // eliminado porque usamos el adapter manual

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String qrValue;

  @HiveField(2)
  String? name;

  @HiveField(3)
  DateTime createdAt;

  Event({
    required this.id,
    required this.qrValue,
    this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

// Manual TypeAdapter (si no quieres usar build_runner)
class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Event(
      id: fields[0] as String,
      qrValue: fields[1] as String,
      name: fields[2] as String?,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.qrValue)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}
