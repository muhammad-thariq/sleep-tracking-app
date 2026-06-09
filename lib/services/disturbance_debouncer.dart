import '../models/disturbance.dart';

class _Pending {
  Disturbance disturbance;
  final DateTime windowStart;
  _Pending(this.disturbance, this.windowStart);
}

/// Debounces raw sensor disturbances into at most one event per type per
/// [window]. Within a window the highest-intensity candidate wins (see edge
/// cases). Pure / time-injectable so it can be unit-tested without real timers
/// or sensors.
class DisturbanceDebouncer {
  final Duration window;
  final Map<DisturbanceType, _Pending> _pending = {};

  DisturbanceDebouncer({this.window = const Duration(seconds: 30)});

  /// Buffer a candidate disturbance. The window is anchored at the first
  /// candidate of its type; later candidates only update the kept event if
  /// they are more intense.
  void submit(Disturbance candidate) {
    final existing = _pending[candidate.type];
    if (existing == null) {
      _pending[candidate.type] = _Pending(candidate, candidate.timestamp);
      return;
    }
    final withinWindow =
        candidate.timestamp.difference(existing.windowStart) <= window;
    if (withinWindow) {
      if (candidate.intensity > existing.disturbance.intensity) {
        existing.disturbance = candidate;
      }
    } else {
      // Window elapsed but wasn't flushed yet — start a fresh one.
      _pending[candidate.type] = _Pending(candidate, candidate.timestamp);
    }
  }

  /// Emit any buffered disturbances whose window has fully elapsed as of [now].
  List<Disturbance> flushDue(DateTime now) {
    final out = <Disturbance>[];
    _pending.removeWhere((_, p) {
      if (now.difference(p.windowStart) >= window) {
        out.add(p.disturbance);
        return true;
      }
      return false;
    });
    return out;
  }

  /// Emit everything still buffered (called when tracking stops).
  List<Disturbance> flushAll() {
    final out = _pending.values.map((p) => p.disturbance).toList();
    _pending.clear();
    return out;
  }
}
