import '../../map/application/game_session_state.dart';
import '../../map/read_model/pending_action_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/pending_turn_actions_view.dart';
import 'turn_session_port.dart';

/// Serializes navigation intents while allowing each successful focus to advance its scope.
final class PendingTurnNavigation {
  PendingTurnNavigation({
    required this.session,
    required this.readState,
    required this.readScope,
    required this.focus,
    required this.endTurn,
    required this.onFailure,
  });

  final TurnSessionPort session;
  final GameSessionReady? Function() readState;
  final Object? Function() readScope;
  final Future<bool> Function(PendingTurnActionView) focus;
  final void Function() endTurn;
  final void Function(TurnSessionException) onFailure;
  Future<void> _tail = Future.value();
  _NavigationBatch? _batch;

  Future<void> navigate({
    required int step,
    bool endWhenEmpty = false,
    required bool Function() inputAvailable,
    void Function(PendingTurnActionView)? onFocused,
  }) {
    if (!inputAvailable()) return Future.value();
    final batch = _batch ??= _NavigationBatch(readScope());
    batch.pending += 1;
    final result = _tail.then(
      (_) => _execute(batch, step, endWhenEmpty, inputAvailable, onFocused),
    );
    _tail = result.whenComplete(() {
      batch.pending -= 1;
      if (batch.pending == 0 && identical(_batch, batch)) _batch = null;
    });
    return _tail;
  }

  Future<void> _execute(
    _NavigationBatch batch,
    int step,
    bool endWhenEmpty,
    bool Function() inputAvailable,
    void Function(PendingTurnActionView)? onFocused,
  ) async {
    bool current() =>
        !batch.cancelled &&
        batch.scope != null &&
        batch.scope == readScope() &&
        inputAvailable();
    final initial = readState();
    if (!current() || initial == null) {
      batch.cancelled = true;
      return;
    }
    try {
      final work = await session.pendingTurnActions(
        expectedRevision: initial.recipient.stamp.revision,
      );
      if (!current() || readState() == null) {
        batch.cancelled = true;
        return;
      }
      _validate(work, initial);
      await _activate(
        batch,
        work,
        initial,
        step,
        endWhenEmpty,
        inputAvailable,
        onFocused,
      );
    } on TurnSessionException catch (error) {
      if (current()) onFailure(error);
      batch.cancelled = true;
    } on Object catch (error, stack) {
      if (current()) {
        onFailure(
          TurnSessionException(
            code: 'unexpected_turn_navigation_failure',
            message: 'Pending turn work could not be loaded.',
            diagnosticCause: error,
            diagnosticStackTrace: stack,
          ),
        );
      }
      batch.cancelled = true;
    }
  }

  Future<void> _activate(
    _NavigationBatch batch,
    PendingTurnActionsView work,
    GameSessionReady initial,
    int step,
    bool endWhenEmpty,
    bool Function() inputAvailable,
    void Function(PendingTurnActionView)? onFocused,
  ) async {
    if (!work.canActivate) {
      batch.cancelled = true;
      return;
    }
    if (work.actions.isEmpty) {
      if (endWhenEmpty) {
        batch.cancelled = true;
        endTurn();
      }
      return;
    }
    final action = _next(work.actions, initial, step);
    if (!await focus(action)) {
      batch.cancelled = true;
      return;
    }
    batch.scope = readScope();
    if (inputAvailable()) onFocused?.call(action);
  }
}

final class _NavigationBatch {
  _NavigationBatch(this.scope);
  Object? scope;
  var pending = 0;
  var cancelled = false;
}

PendingTurnActionView _next(
  List<PendingTurnActionView> actions,
  GameSessionReady state,
  int step,
) {
  final interaction = state.interaction;
  final research =
      interaction.researchFocused ||
      state.recipient.pendingAction is PendingResearchSelectionView;
  var index = research
      ? actions.indexWhere((value) => value is PendingResearchTurnActionView)
      : -1;
  if (index == -1) {
    index = actions.indexWhere(
      (value) =>
          value is PendingUnitTurnActionView &&
          value.unitId == interaction.selectedUnitId,
    );
  }
  if (index == -1) {
    index = actions.indexWhere(
      (value) =>
          value is PendingCityProductionTurnActionView &&
          value.cityId == interaction.city?.cityId,
    );
  }
  final direction = step < 0 ? -1 : 1;
  return actions[index < 0
      ? (direction > 0 ? 0 : actions.length - 1)
      : (index + direction) % actions.length];
}

bool _sameStamp(SessionStampView a, SessionStampView b) =>
    (a.revision, a.stateDigest, a.mapHash, a.rulesetHash) ==
    (b.revision, b.stateDigest, b.mapHash, b.rulesetHash);

void _validate(PendingTurnActionsView work, GameSessionReady initial) {
  if (work.actorPlayerId != initial.recipient.actorPlayerId ||
      !_sameStamp(work.stamp, initial.recipient.stamp)) {
    throw const TurnSessionException(
      code: 'invalid_session_protocol',
      message: 'Pending turn work is stale.',
    );
  }
}
