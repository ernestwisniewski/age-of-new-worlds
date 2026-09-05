import 'dart:async';
import 'dart:math' as math;

abstract interface class MapUnitIdleParticipant {
  double get idleFrameDelay;
  bool advanceIdle(double dt);
}

/// Requests a frame only when an idle pose changes; Flame can stay paused.
final class MapUnitIdleClock {
  MapUnitIdleClock({required this.onFrame, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final void Function() onFrame;
  final DateTime Function() _now;
  List<MapUnitIdleParticipant> _units = const [];
  Timer? _timer;
  DateTime? _started;
  int _ticks = 0;

  bool get scheduled => _timer?.isActive ?? false;
  int get ticks => _ticks;
  int get participantCount => _units.length;

  void synchronize(Iterable<MapUnitIdleParticipant> units) {
    flush();
    _units = units.toList(growable: false);
    _schedule();
  }

  void flush({double minimumElapsed = 0}) {
    _timer?.cancel();
    _timer = null;
    final started = _started;
    _started = null;
    if (started == null) return;
    final elapsed = math.max(
      minimumElapsed,
      _now().difference(started).inMicroseconds / 1000000,
    );
    var changed = false;
    for (final unit in _units) {
      if (unit.advanceIdle(elapsed)) changed = true;
    }
    if (changed) onFrame();
  }

  void _schedule() {
    if (_units.isEmpty) return;
    final next = _units.map((unit) => unit.idleFrameDelay).reduce(math.min);
    // Coalesce independently phased units into at most one request per 60 Hz frame.
    final delay = math.max(1 / 60, next);
    _started = _now();
    _timer = Timer(
      Duration(microseconds: math.max(1, (delay * 1000000).ceil())),
      () {
        _ticks++;
        flush(minimumElapsed: delay);
        _schedule();
      },
    );
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    _started = null;
    _units = const [];
  }
}
