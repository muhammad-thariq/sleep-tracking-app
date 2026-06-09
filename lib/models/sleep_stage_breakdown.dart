import 'package:hive/hive.dart';

/// Percentage split of a sleep session across the four stages.
///
/// NOTE: in Phase 2 these values are a documented *stub* — see
/// `ManualTrackingService` / `AutoTrackingService`. Real stage detection
/// (e.g. from heart-rate / sound classification) is out of scope.
class SleepStageBreakdown {
  final double awakePercent;
  final double lightPercent;
  final double remPercent;
  final double deepPercent;

  const SleepStageBreakdown({
    required this.awakePercent,
    required this.lightPercent,
    required this.remPercent,
    required this.deepPercent,
  });
}

/// Hand-written adapter (typeId 0). We register adapters manually rather than
/// using `hive_generator`, whose pinned `analyzer` dependency is incompatible
/// with the current Dart toolchain + Riverpod 3.
class SleepStageBreakdownAdapter extends TypeAdapter<SleepStageBreakdown> {
  @override
  final int typeId = 0;

  @override
  SleepStageBreakdown read(BinaryReader reader) {
    return SleepStageBreakdown(
      awakePercent: reader.readDouble(),
      lightPercent: reader.readDouble(),
      remPercent: reader.readDouble(),
      deepPercent: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SleepStageBreakdown obj) {
    writer
      ..writeDouble(obj.awakePercent)
      ..writeDouble(obj.lightPercent)
      ..writeDouble(obj.remPercent)
      ..writeDouble(obj.deepPercent);
  }
}
