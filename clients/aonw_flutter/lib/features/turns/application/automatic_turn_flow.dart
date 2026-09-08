import '../../map/application/game_session_state.dart';
import '../../map/read_model/pending_action_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../../settings/application/client_automation_settings.dart';
import '../read_model/pending_turn_actions_view.dart';
import 'automatic_turn_policy.dart';
import 'automatic_turn_target.dart';

/// Retains local interaction intent; pending work remains authoritative.
final class AutomaticTurnFlow {
  ClientAutomationSettings _settings = const ClientAutomationSettings(
    advanceActions: false,
  );
  Object? _context;
  AutomaticTurnTarget? _selected;
  AutomaticTurnTarget? _paused;
  PendingTurnActionsView? _work;
  SessionStampView? _stamp;
  String? _completedCityId;
  var _selectedNeededOrder = false;
  var _selectedDecisionOpen = false;
  var _researchFocused = false;
  var _researchSelectionRequired = false;
  var _researchDismissed = false;
  var _primed = false;

  ClientAutomationSettings get settings => _settings;

  bool get enabled => _settings.advanceActions || _settings.endTurn;

  bool configure(ClientAutomationSettings settings) {
    if (_settings == settings) return false;
    if (!_settings.advanceActions && settings.advanceActions) {
      _primed = true;
      _researchDismissed = false;
      _paused = null;
      _selectedNeededOrder = false;
      _work = null;
    }
    if (!_settings.endTurn && settings.endTurn) _paused = null;
    if (!settings.advanceActions) {
      _primed = false;
      _completedCityId = null;
    }
    _settings = settings;
    return true;
  }

  void observe(GameSessionState state, {required Object session}) {
    if (state is! GameSessionReady) {
      reset();
      return;
    }
    final context = (
      session,
      state.scene.map.mapId,
      state.scene.map.contentHash,
      state.recipient.actorPlayerId,
      state.recipient.turnView.number,
    );
    if (_context != context) {
      final firstContext = _context == null;
      reset();
      _context = context;
      _primed = firstContext && _settings.advanceActions;
    }
    _observeSelection(state);
    _observeResearch(state);
    _stamp = state.recipient.stamp;
  }

  void _observeResearch(GameSessionReady state) {
    final required =
        state.recipient.pendingAction is PendingResearchSelectionView;
    final focused = state.interaction.researchFocused || required;
    final cancelled =
        _researchSelectionRequired &&
        !required &&
        state.recipient.research.activeTechnologyId == null;
    if (_researchFocused &&
        !focused &&
        (_sameStamp(_stamp, state.recipient.stamp) || cancelled)) {
      _researchDismissed = true;
    }
    _researchFocused = focused;
    _researchSelectionRequired = required;
  }

  void _observeSelection(GameSessionReady state) {
    final target = AutomaticTurnTarget.resolve(state);
    if (_selected != target) {
      _paused = target == null ? _selected : null;
      _completedCityId = null;
      _selectedNeededOrder = false;
      _selectedDecisionOpen = false;
      _selected = target;
    }
    final decisionOpen = AutomaticTurnTarget.hasManualDraft(state);
    if (_selectedDecisionOpen && !decisionOpen) {
      _primed = true;
      _completedCityId = _settings.advanceActions ? target?.cityId : null;
    }
    _selectedDecisionOpen = decisionOpen;
    final work = _work;
    if (work != null && _sameStamp(work.stamp, state.recipient.stamp)) {
      _selectedNeededOrder = target?.needsOrder(work) ?? false;
    }
  }

  AutomaticTurnPolicy policyFor(
    PendingTurnActionsView work,
    GameSessionReady state,
  ) {
    final selected = _selected;
    final needsOrder = selected?.needsOrder(work) ?? false;
    if (_selectedNeededOrder && !needsOrder) {
      _primed = true;
      _completedCityId = _settings.advanceActions ? selected?.cityId : null;
    }
    _selectedNeededOrder = needsOrder;
    final paused = _paused;
    if (paused != null && !paused.needsOrder(work)) {
      _paused = null;
      _primed = true;
    }
    if (work.actions.length != 1 ||
        work.actions.single is! PendingResearchTurnActionView) {
      _researchDismissed = false;
    }
    _work = work;
    return AutomaticTurnPolicy(
      advanceActions: _settings.advanceActions,
      endTurn: _settings.endTurn,
      primed: _primed,
      manualTargetPaused: _paused != null,
      researchDismissed: _researchDismissed,
      resolvedCityCompleted:
          _completedCityId != null &&
          _completedCityId == state.interaction.city?.cityId,
    );
  }

  void reset() {
    _context = null;
    _selected = null;
    _paused = null;
    _work = null;
    _stamp = null;
    _completedCityId = null;
    _selectedNeededOrder = false;
    _selectedDecisionOpen = false;
    _researchFocused = false;
    _researchSelectionRequired = false;
    _researchDismissed = false;
    _primed = false;
  }
}

bool _sameStamp(SessionStampView? a, SessionStampView b) =>
    a != null &&
    (a.revision, a.stateDigest, a.mapHash, a.rulesetHash) ==
        (b.revision, b.stateDigest, b.mapHash, b.rulesetHash);
