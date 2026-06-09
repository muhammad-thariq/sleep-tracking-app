import 'package:hive/hive.dart';

enum DisturbanceType { environmentalNoise, restlessMovement }

/// A single recorded disturbance during a tracked sleep session.
class Disturbance {
  final String id;
  final DisturbanceType type;
  final DateTime timestamp;
  final String description;
  final double intensity;

  const Disturbance({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.description,
    required this.intensity,
  });
}

/// typeId 1
class DisturbanceAdapter extends TypeAdapter<Disturbance> {
  @override
  final int typeId = 1;

  @override
  Disturbance read(BinaryReader reader) {
    return Disturbance(
      id: reader.readString(),
      type: DisturbanceType.values[reader.readByte()],
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      description: reader.readString(),
      intensity: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Disturbance obj) {
    writer
      ..writeString(obj.id)
      ..writeByte(obj.type.index)
      ..writeInt(obj.timestamp.millisecondsSinceEpoch)
      ..writeString(obj.description)
      ..writeDouble(obj.intensity);
  }
}
