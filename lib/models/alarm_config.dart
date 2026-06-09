import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AlarmType { smart, standard }

/// A configured alarm. [time] is stored as minutes-since-midnight; [activeDays]
/// is length 7 indexed Sun..Sat.
class AlarmConfig {
  final String id;
  final AlarmType type;
  final int time; // minutes since midnight
  final String label;
  final int? windowMinutes; // smart only — e.g. 30
  final List<bool> activeDays; // length 7, Sun..Sat
  final bool enabled;

  const AlarmConfig({
    required this.id,
    required this.type,
    required this.time,
    required this.label,
    required this.windowMinutes,
    required this.activeDays,
    required this.enabled,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: time ~/ 60, minute: time % 60);

  static int minutesFromTimeOfDay(TimeOfDay t) => t.hour * 60 + t.minute;

  AlarmConfig copyWith({
    AlarmType? type,
    int? time,
    String? label,
    int? windowMinutes,
    bool clearWindow = false,
    List<bool>? activeDays,
    bool? enabled,
  }) {
    return AlarmConfig(
      id: id,
      type: type ?? this.type,
      time: time ?? this.time,
      label: label ?? this.label,
      windowMinutes: clearWindow ? null : (windowMinutes ?? this.windowMinutes),
      activeDays: activeDays ?? this.activeDays,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// typeId 5
class AlarmConfigAdapter extends TypeAdapter<AlarmConfig> {
  @override
  final int typeId = 5;

  @override
  AlarmConfig read(BinaryReader reader) {
    final id = reader.readString();
    final type = AlarmType.values[reader.readByte()];
    final time = reader.readInt();
    final label = reader.readString();
    final hasWindow = reader.readBool();
    final windowMinutes = hasWindow ? reader.readInt() : null;
    final activeDays = reader.readBoolList();
    final enabled = reader.readBool();

    return AlarmConfig(
      id: id,
      type: type,
      time: time,
      label: label,
      windowMinutes: windowMinutes,
      activeDays: activeDays,
      enabled: enabled,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmConfig obj) {
    writer
      ..writeString(obj.id)
      ..writeByte(obj.type.index)
      ..writeInt(obj.time)
      ..writeString(obj.label)
      ..writeBool(obj.windowMinutes != null);
    if (obj.windowMinutes != null) {
      writer.writeInt(obj.windowMinutes!);
    }
    writer
      ..writeBoolList(obj.activeDays)
      ..writeBool(obj.enabled);
  }
}
