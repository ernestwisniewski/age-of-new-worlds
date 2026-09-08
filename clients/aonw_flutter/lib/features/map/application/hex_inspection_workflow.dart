import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';
import 'game_session_state.dart';
import 'hex_inspection_session_port.dart';
import 'hex_inspection_state.dart';

typedef HexInspectionStateReader = GameSessionState Function();
typedef HexInspectionStatePublisher = void Function(GameSessionReady value);
typedef HexInspectionDisposed = bool Function();
typedef HexInspectionDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

final class HexInspectionWorkflow {
  HexInspectionWorkflow({
    required HexInspectionSessionPort session,
    required HexInspectionDiagnosticReporter diagnosticReporter,
  }) : _session = session,
       _diagnosticReporter = diagnosticReporter;
  final HexInspectionSessionPort _session;
  final HexInspectionDiagnosticReporter _diagnosticReporter;
  var _requestId = 0;

  Future<void> inspect({
    required MapHexCoordinate coordinate,
    required HexInspectionStateReader readState,
    required HexInspectionStatePublisher publish,
    required HexInspectionDisposed isDisposed,
  }) async {
    final initial = _loadable(readState(), coordinate, isDisposed());
    if (initial == null) return;
    final requestId = ++_requestId;
    final pending = HexInspectionLoading(coordinate);
    publish(initial.withInspection(pending));
    GameSessionReady? current() => _current(
      readState(),
      initial,
      pending,
      isDisposed() || requestId != _requestId,
    );
    try {
      final view = await _session.inspectHex(
        expectedRevision: initial.recipient.stamp.revision,
        coordinate: coordinate,
      );
      final ready = current();
      if (ready == null) return;
      if (view.coordinate != coordinate ||
          !_sameStamp(view.stamp, ready.recipient.stamp)) {
        throw const HexInspectionSessionException(
          code: 'invalid_session_protocol',
          message: 'The inspected coordinate or state is stale.',
        );
      }
      publish(ready.withInspection(HexInspectionReady(view)));
    } on HexInspectionSessionException catch (error, stackTrace) {
      final ready = current();
      if (ready == null) return;
      if (error.diagnosticCause != null) {
        _diagnosticReporter(
          error.code,
          error.diagnosticCause!,
          error.diagnosticStackTrace ?? stackTrace,
        );
      }
      publish(_sessionFailure(ready, coordinate, error));
    } on Object catch (error, stackTrace) {
      final ready = current();
      if (ready == null) return;
      _diagnosticReporter(
        'unexpected_hex_inspection_failure',
        error,
        stackTrace,
      );
      publish(
        ready.withInspection(
          HexInspectionFailure(
            coordinate,
            HexInspectionFailureCode.requestFailed,
          ),
        ),
      );
    }
  }

  void close({
    required HexInspectionStateReader readState,
    required HexInspectionStatePublisher publish,
  }) {
    _requestId += 1;
    final ready = readState();
    if (ready is GameSessionReady && ready.inspection != null) {
      publish(ready.withInspection(null));
    }
  }
}

GameSessionReady? _current(
  GameSessionState state,
  GameSessionReady initial,
  HexInspectionLoading pending,
  bool disposed,
) {
  if (disposed ||
      state is! GameSessionReady ||
      !identical(state.inspection, pending)) {
    return null;
  }
  if ((
            state.scene.map.mapId,
            state.scene.map.contentHash,
            state.recipient.actorPlayerId,
          ) !=
          (
            initial.scene.map.mapId,
            initial.scene.map.contentHash,
            initial.recipient.actorPlayerId,
          ) ||
      !_sameStamp(state.recipient.stamp, initial.recipient.stamp)) {
    return null;
  }
  return state;
}

bool _sameStamp(SessionStampView first, SessionStampView last) =>
    (first.revision, first.stateDigest, first.mapHash, first.rulesetHash) ==
    (last.revision, last.stateDigest, last.mapHash, last.rulesetHash);

GameSessionReady _sessionFailure(
  GameSessionReady ready,
  MapHexCoordinate coordinate,
  HexInspectionSessionException error,
) {
  final resynced = error.resyncedPlayer;
  if (resynced != null) {
    if ((
          resynced.actorPlayerId,
          resynced.stamp.mapHash,
          resynced.stamp.rulesetHash,
        ) !=
        (
          ready.recipient.actorPlayerId,
          ready.recipient.stamp.mapHash,
          ready.recipient.stamp.rulesetHash,
        )) {
      return ready.withInspection(
        HexInspectionFailure(
          coordinate,
          HexInspectionFailureCode.responseIncompatible,
        ),
      );
    }
    return ready.withRecipient(resynced).withInspection(null);
  }
  final code = switch (error.code) {
    'invalid_session_protocol' => HexInspectionFailureCode.responseIncompatible,
    'session_not_open' ||
    'session_superseded' => HexInspectionFailureCode.sessionUnavailable,
    _ => HexInspectionFailureCode.requestFailed,
  };
  return ready.withInspection(HexInspectionFailure(coordinate, code));
}

GameSessionReady? _loadable(
  GameSessionState state,
  MapHexCoordinate coordinate,
  bool disposed,
) {
  if (disposed ||
      state is! GameSessionReady ||
      !state.scene.map.contains(coordinate)) {
    return null;
  }
  return state;
}
