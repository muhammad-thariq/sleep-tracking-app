import 'package:hive/hive.dart';

import 'disturbance.dart';
import 'sleep_stage_breakdown.dart';

/// How a session was captured. `manual` is higher fidelity than `auto`.
enum SleepSource { manual, auto }

class SleepSession {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes; // derived from start/end
  final int qualityScore; // 0..100, computed
  final SleepStageBreakdown stageBreakdown;
  final List<Disturbance> disturbances;
  final bool audioTrackingEnabled;
  final bool motionTrackingEnabled;
  final SleepSource source;

  const SleepSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.qualityScore,
    required this.stageBreakdown,
    required this.disturbances,
    required this.audioTrackingEnabled,
    required this.motionTrackingEnabled,
    required this.source,
  });

  /// A session with no `endedAt` was interrupted (app killed mid-tracking).
  bool get isOrphaned => endedAt == null;

  SleepSession copyWith({
    DateTime? endedAt,
    int? durationMinutes,
    int? qualityScore,
    SleepStageBreakdown? stageBreakdown,
    List<Disturbance>? disturbances,
  }) {
    return SleepSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      qualityScore: qualityScore ?? this.qualityScore,
      stageBreakdown: stageBreakdown ?? this.stageBreakdown,
      disturbances: disturbances ?? this.disturbances,
      audioTrackingEnabled: audioTrackingEnabled,
      motionTrackingEnabled: motionTrackingEnabled,
      source: source,
    );
  }
}

/// typeId 3 (0 = stage breakdown, 1 = disturbance, 2 reserved for enums).
class SleepSessionAdapter extends TypeAdapter<SleepSession> {
  @override
  final int typeId = 3;

  @override
  SleepSession read(BinaryReader reader) {
    final id = reader.readString();
    final startedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasEnded = reader.readBool();
    final endedAt = hasEnded
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final durationMinutes = reader.readInt();
    final qualityScore = reader.readInt();
    final stageBreakdown = reader.read() as SleepStageBreakdown;
    final disturbances = reader.readList().cast<Disturbance>();
    final audioTrackingEnabled = reader.readBool();
    final motionTrackingEnabled = reader.readBool();
    final source = SleepSource.values[reader.readByte()];

    return SleepSession(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      durationMinutes: durationMinutes,
      qualityScore: qualityScore,
      stageBreakdown: stageBreakdown,
      disturbances: disturbances,
      audioTrackingEnabled: audioTrackingEnabled,
      motionTrackingEnabled: motionTrackingEnabled,
      source: source,
    );
  }

  @override
  void write(BinaryWriter writer, SleepSession obj) {
    writer
      ..writeString(obj.id)
      ..writeInt(obj.startedAt.millisecondsSinceEpoch)
      ..writeBool(obj.endedAt != null);
    if (obj.endedAt != null) {
      writer.writeInt(obj.endedAt!.millisecondsSinceEpoch);
    }
    writer
      ..writeInt(obj.durationMinutes)
      ..writeInt(obj.qualityScore)
      ..write(obj.stageBreakdown)
      ..writeList(obj.disturbances)
      ..writeBool(obj.audioTrackingEnabled)
      ..writeBool(obj.motionTrackingEnabled)
      ..writeByte(obj.source.index);
  }
}
