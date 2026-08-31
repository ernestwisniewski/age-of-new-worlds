import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../local_game/application/local_game_catalog.dart';
import '../application/local_replay_store.dart';
import '../application/replay_capture.dart';
import '../application/replay_session_port.dart';
import '../application/replay_state.dart';

typedef ReplayDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class ReplayOpenResultView {
  const ReplayOpenResultView.started() : failure = null;

  const ReplayOpenResultView.failed(this.failure);

  final ReplayFailureViewCode? failure;

  bool get started => failure == null;
}

final class ReplayPresentationController extends ChangeNotifier
    implements ReplayCapture {
  ReplayPresentationController({
    required ReplaySessionPort? session,
    required LocalReplayStore? store,
    ReplayDiagnosticReporter diagnosticReporter = _reportReplayDiagnostic,
  }) : _session = session,
       _store = store,
       _diagnosticReporter = diagnosticReporter;

  final ReplaySessionPort? _session;
  final LocalReplayStore? _store;
  final ReplayDiagnosticReporter _diagnosticReporter;
  ReplayState _state = const ReplayIdle();
  Timer? _timer;
  var _generation = 0;
  var _disposed = false;

  ReplayState get state => _state;

  Future<bool> hasReplay() async {
    final store = _store;
    if (store == null) return false;
    try {
      for (final entry in LocalGameCatalog.entries) {
        if (await store.contains(entry.id)) return true;
      }
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('replay_lookup_failed', error, stackTrace);
    }
    return false;
  }

  @override
  Future<void> captureReplay(LocalGameCatalogEntryView entry) async {
    final session = _session;
    final store = _store;
    if (session == null || store == null) return;
    try {
      final document = await session.exportReplayDocument();
      await store.write(entry.id, document);
    } on ReplaySessionException catch (error, stackTrace) {
      _reportSession(error, stackTrace);
    } on LocalReplayStoreException catch (error, stackTrace) {
      _reportStore(error, stackTrace);
    } on Object catch (error, stackTrace) {
      _diagnosticReporter(
        'unexpected_replay_capture_failure',
        error,
        stackTrace,
      );
    }
  }

  Future<ReplayOpenResultView> openLatest() async {
    pause();
    final generation = ++_generation;
    _setState(const ReplayLoading());
    final session = _session;
    final store = _store;
    if (session == null || store == null) {
      return _failOpen(generation, ReplayFailureViewCode.unavailable);
    }
    var readFailed = false;
    var found = false;
    for (final entry in LocalGameCatalog.entries) {
      for (final copy in LocalReplayCopyView.values) {
        String? document;
        try {
          document = await store.read(entry.id, copy);
        } on LocalReplayStoreException catch (error, stackTrace) {
          readFailed = true;
          _reportStore(error, stackTrace);
          continue;
        } on Object catch (error, stackTrace) {
          readFailed = true;
          _diagnosticReporter(
            'unexpected_replay_read_failure',
            error,
            stackTrace,
          );
          continue;
        }
        if (document == null) continue;
        found = true;
        try {
          final frame = await session.openReplayDocument(
            assets: entry.assets,
            document: document,
          );
          if (!_isCurrent(generation)) {
            return const ReplayOpenResultView.failed(
              ReplayFailureViewCode.unavailable,
            );
          }
          _setState(
            ReplayReady(
              frame: frame,
              speed: ReplaySpeedView.normal,
              isPlaying: false,
              isSeeking: false,
            ),
          );
          return const ReplayOpenResultView.started();
        } on ReplaySessionException catch (error, stackTrace) {
          _reportSession(error, stackTrace);
        } on Object catch (error, stackTrace) {
          _diagnosticReporter(
            'unexpected_replay_open_failure',
            error,
            stackTrace,
          );
        }
      }
    }
    return _failOpen(
      generation,
      found
          ? ReplayFailureViewCode.incompatible
          : readFailed
          ? ReplayFailureViewCode.unreadable
          : ReplayFailureViewCode.missing,
    );
  }

  void play() {
    final ready = _state;
    if (ready is! ReplayReady || ready.isPlaying || ready.isSeeking) return;
    if (ready.frame.isComplete) {
      unawaited(_restartAndPlay());
      return;
    }
    _setState(ready.copyWith(isPlaying: true));
    _scheduleNext();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    final ready = _state;
    if (ready is ReplayReady && ready.isPlaying) {
      _setState(ready.copyWith(isPlaying: false));
    }
  }

  void cycleSpeed() {
    final ready = _state;
    if (ready is! ReplayReady) return;
    final next = ReplaySpeedView
        .values[(ready.speed.index + 1) % ReplaySpeedView.values.length];
    _timer?.cancel();
    _setState(ready.copyWith(speed: next));
    if (ready.isPlaying) _scheduleNext();
  }

  void seek(int position) {
    pause();
    unawaited(_seek(position, resumeAfter: false));
  }

  Future<void> _restartAndPlay() async {
    if (await _seek(0, resumeAfter: false)) play();
  }

  Future<bool> _seek(int position, {required bool resumeAfter}) async {
    final ready = _state;
    final session = _session;
    if (ready is! ReplayReady || ready.isSeeking || session == null) {
      return false;
    }
    final bounded = position.clamp(0, ready.frame.entryCount);
    final generation = _generation;
    _setState(ready.copyWith(isSeeking: true));
    try {
      final frame = await session.seekReplay(bounded);
      if (!_isCurrent(generation)) return false;
      final updated = ReplayReady(
        frame: frame,
        speed: ready.speed,
        isPlaying: resumeAfter && !frame.isComplete,
        isSeeking: false,
      );
      _setState(updated);
      if (updated.isPlaying) _scheduleNext();
      return true;
    } on ReplaySessionException catch (error, stackTrace) {
      _reportSession(error, stackTrace);
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('unexpected_replay_seek_failure', error, stackTrace);
    }
    if (_isCurrent(generation)) {
      _setState(const ReplayFailure(ReplayFailureViewCode.seekFailed));
    }
    return false;
  }

  void _scheduleNext() {
    _timer?.cancel();
    final ready = _state;
    if (ready is! ReplayReady || !ready.isPlaying || ready.frame.isComplete) {
      return;
    }
    _timer = Timer(
      ready.speed.frameDuration,
      () => _seek(ready.frame.position + 1, resumeAfter: true),
    );
  }

  ReplayOpenResultView _failOpen(
    int generation,
    ReplayFailureViewCode failure,
  ) {
    if (_isCurrent(generation)) _setState(ReplayFailure(failure));
    return ReplayOpenResultView.failed(failure);
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _setState(ReplayState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  void _reportSession(ReplaySessionException error, StackTrace stackTrace) {
    _diagnosticReporter(
      error.code,
      error.diagnosticCause ?? error,
      error.diagnosticStackTrace ?? stackTrace,
    );
  }

  void _reportStore(LocalReplayStoreException error, StackTrace stackTrace) {
    _diagnosticReporter(
      error.code,
      error.diagnosticCause ?? error,
      error.diagnosticStackTrace ?? stackTrace,
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation += 1;
    _timer?.cancel();
    super.dispose();
  }
}

void _reportReplayDiagnostic(String code, Object error, StackTrace stackTrace) {
  debugPrintStack(
    label: 'Replay diagnostic [$code]: $error',
    stackTrace: stackTrace,
  );
}
