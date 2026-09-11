import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../local_game/application/local_game_catalog.dart';
import '../../map/application/city_planning_session_port.dart';
import '../../map/application/game_session_capabilities.dart';
import '../../map/application/map_session_port.dart';
import '../../map/presentation/map_presentation_controller.dart';
import '../../map/read_model/map_view_mode.dart';
import '../../multiplayer/application/match_history_port.dart';
import '../application/local_replay_store.dart';
import '../application/network_replay_session_port.dart';
import '../application/replay_capture.dart';
import '../application/replay_session_port.dart';
import '../application/replay_state.dart';
import '../read_model/replay_frame_view.dart';

part 'replay_online_opening.dart';
part 'replay_local_opening.dart';

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
    NetworkReplaySessionPort? networkSession,
    GameSessionCapabilities? viewerCapabilities,
    ReplayDiagnosticReporter diagnosticReporter = _reportReplayDiagnostic,
  }) : _session = session,
       _store = store,
       _networkSession = networkSession,
       _viewerCapabilities = viewerCapabilities,
       _diagnosticReporter = diagnosticReporter;

  CityPlanningSessionPort? get cityPlanningSession => _session;
  final GameSessionCapabilities? _viewerCapabilities;

  MapPresentationController? createMapViewer(
    ReplayFrameView frame, {
    MapViewMode? viewMode,
  }) {
    final capabilities = _viewerCapabilities;
    if (capabilities == null) return null;
    return MapPresentationController.viewer(
      capabilities: capabilities,
      scene: frame.scene,
      commandFrame: frame.command,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  final ReplaySessionPort? _session;
  final NetworkReplaySessionPort? _networkSession;
  String? _networkUserId;
  final LocalReplayStore? _store;
  final ReplayDiagnosticReporter _diagnosticReporter;
  ReplayState _state = const ReplayIdle();
  Timer? _timer;
  var _generation = 0;
  var _disposed = false;
  var _playbackGeneration = 0;
  var _waitingForEffects = false;
  Future<void> Function()? waitForCommandEffects;

  ReplayState get state => _state;
  MapViewModeReader? readInitialMapViewMode;
  MapViewMode _viewMode = MapViewMode.graphic;
  MapViewMode get viewMode => _viewMode;

  Future<MapViewMode> _initialMapViewMode() async {
    try {
      return await readInitialMapViewMode?.call() ?? MapViewMode.graphic;
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('replay_view_preference_failed', error, stackTrace);
      return MapViewMode.graphic;
    }
  }

  Future<bool> hasReplayFor(LocalGameScenarioView scenario) =>
      _containsReplay(scenario);

  Future<bool> hasReplay() async {
    for (final entry in LocalGameCatalog.entries) {
      if (await _containsReplay(entry.id)) return true;
    }
    return false;
  }

  Future<bool> _containsReplay(LocalGameScenarioView scenario) async {
    final store = _store;
    if (store == null) return false;
    try {
      return await store.contains(scenario);
    } on Object catch (error, stackTrace) {
      _diagnosticReporter('replay_lookup_failed', error, stackTrace);
      return false;
    }
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

  Future<ReplayOpenResultView> open(LocalGameScenarioView scenario) =>
      _openEntries([
        LocalGameCatalog.entries.singleWhere((entry) => entry.id == scenario),
      ]);

  Future<ReplayOpenResultView> openLatest() =>
      _openEntries(LocalGameCatalog.entries);

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
    _playbackGeneration++;
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
    final playbackGeneration = _playbackGeneration;
    _setState(ready.copyWith(isSeeking: true));
    try {
      final frame = await session.seekReplay(bounded);
      if (!_isCurrent(generation)) return false;
      await _presentFrame(frame, generation, playbackGeneration, resumeAfter);
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

  Future<void> _presentFrame(
    ReplayFrameView frame,
    int generation,
    int playbackGeneration,
    bool resumeAfter,
  ) async {
    final current = _state as ReplayReady;
    final updated = ReplayReady(
      frame: frame,
      speed: current.speed,
      isPlaying:
          resumeAfter &&
          playbackGeneration == _playbackGeneration &&
          !frame.isComplete,
      isSeeking: false,
    );
    _waitingForEffects = frame.command != null;
    _setState(updated);
    if (frame.command != null) await waitForCommandEffects?.call();
    if (_isCurrent(generation) &&
        _state is ReplayReady &&
        identical((_state as ReplayReady).frame, frame)) {
      _waitingForEffects = false;
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    final ready = _state;
    if (ready is! ReplayReady || !ready.isPlaying || ready.frame.isComplete) {
      return;
    }
    if (_waitingForEffects) return;
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
