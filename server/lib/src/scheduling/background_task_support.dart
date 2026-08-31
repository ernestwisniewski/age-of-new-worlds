import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

enum BackgroundTaskErrorKind {
  database,
  network,
  timeout,
  invalidState,
  invalidArgument,
  unexpected,
}

BackgroundTaskErrorKind backgroundTaskErrorKind(Object error) {
  return switch (error) {
    DatabaseException() => BackgroundTaskErrorKind.database,
    SocketException() => BackgroundTaskErrorKind.network,
    TimeoutException() => BackgroundTaskErrorKind.timeout,
    StateError() => BackgroundTaskErrorKind.invalidState,
    ArgumentError() => BackgroundTaskErrorKind.invalidArgument,
    _ => BackgroundTaskErrorKind.unexpected,
  };
}

typedef FutureCallScheduleEnsurer =
    Future<bool> Function({
      required Duration delay,
      required bool accelerateExisting,
    });

/// Keeps a reconciled FutureCall schedule alive without overlapping recovery
/// attempts during slow database or shutdown paths.
final class FutureCallScheduleReconciler {
  FutureCallScheduleReconciler({
    required this.reconcileInterval,
    required this.initialDelay,
    required this.recoveryDelay,
    required FutureCallScheduleEnsurer ensureScheduled,
  }) : _ensureScheduled = ensureScheduled;

  final Duration reconcileInterval;
  final Duration initialDelay;
  final Duration recoveryDelay;
  final FutureCallScheduleEnsurer _ensureScheduled;
  Timer? _timer;
  Future<void>? _startInFlight;
  Future<void>? _activeReconciliation;
  bool _closed = false;

  Future<void> start() {
    if (_closed || _timer != null) return Future.value();
    final startInFlight = _startInFlight;
    if (startInFlight != null) return startInFlight;

    late final Future<void> start;
    start = _start().whenComplete(() {
      if (identical(_startInFlight, start)) _startInFlight = null;
    });
    _startInFlight = start;
    return start;
  }

  Future<void> _start() async {
    await _runReconciliation(delay: initialDelay);
    if (_closed) return;
    _timer ??= Timer.periodic(
      reconcileInterval,
      (_) => _triggerReconciliation(),
    );
  }

  Future<void> close() async {
    _closed = true;
    _timer?.cancel();
    _timer = null;
    await _startInFlight;
    await _activeReconciliation;
  }

  void _triggerReconciliation() {
    if (_closed || _activeReconciliation != null) return;
    unawaited(_runReconciliation(delay: recoveryDelay));
  }

  Future<void> _runReconciliation({required Duration delay}) async {
    final active = _activeReconciliation;
    if (active != null) return active;
    final reconciliation = _reconcileOnce(delay: delay);
    _activeReconciliation = reconciliation;
    try {
      await reconciliation;
    } finally {
      if (identical(_activeReconciliation, reconciliation)) {
        _activeReconciliation = null;
      }
    }
  }

  Future<void> _reconcileOnce({required Duration delay}) async {
    try {
      await _ensureScheduled(delay: delay, accelerateExisting: false);
    } catch (_) {
      // The schedule-specific callback owns logging. Session lifecycle errors
      // must not terminate the periodic recovery loop.
    }
  }
}
