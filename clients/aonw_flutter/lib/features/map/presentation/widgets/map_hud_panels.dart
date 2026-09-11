import 'package:flutter/material.dart';

import '../../../audio/presentation/game_audio_actions.dart';
import '../../../diplomacy/application/diplomacy_state.dart';
import '../../../diplomacy/presentation/diplomacy_overlay.dart';
import '../../../objectives/presentation/objective_overlay.dart';
import '../../../players/presentation/player_overlay.dart';
import '../../../players/presentation/player_rail.dart';
import '../../../research/application/research_state.dart';
import '../../../research/presentation/research_discovery_overlay.dart';
import '../../../research/presentation/research_overlay.dart';
import '../../../resources/presentation/resource_overlay.dart';
import '../../../resources/presentation/resource_strip.dart';
import '../../application/game_session_state.dart';
import '../../application/network_game_session_port.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/pending_action_view.dart';
import '../map_presentation_controller.dart';

enum _MapHudPanel {
  players,
  objectives,
  research,
  diplomacy,
  gold,
  science,
  stability,
  resources,
  turn,
  victory,
}

final class MapHudPanels extends StatefulWidget {
  const MapHudPanels({
    required this.scene,
    required this.research,
    required this.diplomacy,
    required this.controller,
    this.blocked = false,
    super.key,
  });

  final MapScene scene;
  final ResearchState research;
  final DiplomacyState diplomacy;
  final MapPresentationController controller;
  final bool blocked;

  @override
  State<MapHudPanels> createState() => _MapHudPanelsState();
}

final class _MapHudPanelsState extends State<MapHudPanels> {
  _MapHudPanel? _openPanel;
  String? _selectedPlayerId;
  String? _diplomacyTargetId;
  var _workerActionsWereOpen = false;
  var _researchWasFocused = false;

  bool get _researchFocused => switch (widget.controller.state) {
    GameSessionReady(:final interaction) => interaction.researchFocused,
    _ => false,
  };

  bool get _workerActionsOpen => switch (widget.controller.state) {
    GameSessionReady(:final interaction) =>
      interaction.worker?.actionsOpen ?? false,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    _workerActionsWereOpen = _workerActionsOpen;
    _researchWasFocused = _researchFocused;
    widget.controller.addListener(_observeWorkerActions);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_observeWorkerActions);
    super.dispose();
  }

  bool get _researchSelectionRequired =>
      !widget.controller.readOnly &&
      widget.scene.player.pendingAction is PendingResearchSelectionView;

  bool get _panelsLocked =>
      widget.blocked || _terminal || widget.research.commandPending;

  bool get _terminal =>
      !widget.controller.readOnly &&
      widget.scene.player.turnView.outcome.isTerminal;

  @override
  void didUpdateWidget(covariant MapHudPanels oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizeController(oldWidget.controller);
    final sceneChanged =
        oldWidget.scene.map.mapId != widget.scene.map.mapId ||
        oldWidget.scene.map.contentHash != widget.scene.map.contentHash ||
        oldWidget.scene.player.actorPlayerId !=
            widget.scene.player.actorPlayerId;
    final selectionBecameRequired =
        oldWidget.scene.player.pendingAction is! PendingResearchSelectionView &&
        _researchSelectionRequired;
    final matchBecameTerminal =
        !oldWidget.scene.player.turnView.outcome.isTerminal && _terminal;
    if (_completedResearchCancellation(oldWidget, sceneChanged)) {
      context.playGameSound(GameSoundCue.uiPanelClose);
    }
    if (widget.blocked ||
        sceneChanged ||
        selectionBecameRequired ||
        matchBecameTerminal) {
      _openPanel = null;
    }
  }

  bool _completedResearchCancellation(
    MapHudPanels previous,
    bool sceneChanged,
  ) =>
      !sceneChanged &&
      !_terminal &&
      previous.research.cancellingSelection &&
      !widget.research.commandPending &&
      !_researchSelectionRequired;

  void _synchronizeController(MapPresentationController previous) {
    if (identical(previous, widget.controller)) return;
    previous.removeListener(_observeWorkerActions);
    widget.controller.addListener(_observeWorkerActions);
    _workerActionsWereOpen = _workerActionsOpen;
    _researchWasFocused = _researchFocused;
    _openPanel = null;
  }

  void _observeWorkerActions() {
    if (_researchWasFocused != _researchFocused) {
      _researchWasFocused = _researchFocused;
      if (_researchFocused || !_researchSelectionRequired) {
        setState(() => _openPanel = null);
      }
      if (_researchFocused) context.playGameSound(GameSoundCue.technology);
    }
    final becameOpen = !_workerActionsWereOpen && _workerActionsOpen;
    _workerActionsWereOpen = _workerActionsOpen;
    if (!becameOpen || _openPanel == null) return;
    setState(() => _openPanel = null);
    context.playGameSound(GameSoundCue.uiPanelClose);
  }

  @override
  Widget build(BuildContext context) {
    final locked = _panelsLocked;
    final effectivePanel = _effectivePanel;
    return Stack(
      children: [
        ResearchOverlay(
          readOnly: widget.controller.readOnly,
          state: widget.research,
          trailingReserve:
              playerRailWidth(
                MediaQuery.sizeOf(context),
                online:
                    widget.controller.networkConnection.phase !=
                    NetworkGameConnectionPhase.inactive,
              ) +
              12,
          selectionRequired: _researchSelectionRequired,
          open: effectivePanel == _MapHudPanel.research,
          onOpenChanged: locked
              ? null
              : (open) => _setOpen(_MapHudPanel.research, open),
          onSelect: widget.controller.selectTechnology,
          onRetry: widget.controller.refreshResearch,
        ),
        DiplomacyOverlay(
          readOnly: widget.controller.readOnly,
          actorPlayerId: widget.scene.player.actorPlayerId,
          view: widget.scene.player.diplomacy,
          state: widget.diplomacy,
          open: effectivePanel == _MapHudPanel.diplomacy,
          onOpenChanged: locked ? null : _setGeneralDiplomacy,
          onAction: widget.controller.executeDiplomacyAction,
          initialTargetPlayerId: _diplomacyTargetId,
        ),
        ObjectiveOverlay(
          showOutcome: !widget.controller.readOnly,
          objectives: widget.scene.map.objectives,
          outcome: widget.scene.player.turnView.outcome,
          open: effectivePanel == _MapHudPanel.objectives,
          onOpenChanged: locked
              ? null
              : (open) => _setOpen(_MapHudPanel.objectives, open),
        ),
        if (!ResourcePopup.values.any(
          (kind) => kind.name == effectivePanel?.name,
        ))
          PlayerOverlay(
            online:
                widget.controller.networkConnection.phase !=
                NetworkGameConnectionPhase.inactive,
            player: widget.scene.player,
            selectedId: effectivePanel == _MapHudPanel.players
                ? _selectedPlayerId
                : null,
            onSelect: locked ? null : _setPlayer,
            onClose: () => _setPlayer(null),
            onDiplomacy: locked ? null : _openPlayerDiplomacy,
          ),
        _resources(effectivePanel, locked),
        _discoveries(),
      ],
    );
  }

  Widget _discoveries() => ResearchDiscoveryOverlay(
    player: widget.scene.player,
    session: widget.controller,
    options: widget.research.options,
    blocked:
        _panelsLocked || widget.controller.networkConnection.blocksGameplay,
  );

  _MapHudPanel? get _effectivePanel {
    if (widget.blocked || _terminal) return null;
    if (_openPanel == _MapHudPanel.players) return _openPanel;
    if (ResourcePopup.values.any((kind) => kind.name == _openPanel?.name)) {
      return _openPanel;
    }
    return _researchSelectionRequired || _researchFocused
        ? _MapHudPanel.research
        : _openPanel;
  }

  void _setGeneralDiplomacy(bool open) {
    _diplomacyTargetId = null;
    _setOpen(_MapHudPanel.diplomacy, open);
  }

  void _openPlayerDiplomacy(String id) {
    _diplomacyTargetId = id;
    _setOpen(_MapHudPanel.diplomacy, true);
  }

  void _setPlayer(String? id) {
    if (_panelsLocked) return;
    final next = _openPanel == _MapHudPanel.players && _selectedPlayerId == id
        ? null
        : id;
    setState(() {
      _selectedPlayerId = next;
      _openPanel = next == null ? null : _MapHudPanel.players;
    });
    context.playGameSound(
      next == null ? GameSoundCue.uiPanelClose : GameSoundCue.uiPanelOpen,
    );
  }

  void _setResource(ResourcePopup? value) {
    if (_panelsLocked) return;
    final next = value == null ? null : _MapHudPanel.values.byName(value.name);
    if (next == _openPanel) return;
    setState(() => _openPanel = next);
    context.playGameSound(
      value == null ? GameSoundCue.uiPanelClose : GameSoundCue.uiPanelOpen,
    );
  }

  Widget _resources(_MapHudPanel? effectivePanel, bool locked) {
    final open = ResourcePopup.values
        .where((kind) => kind.name == effectivePanel?.name)
        .firstOrNull;
    return ResourceOverlay(
      player: widget.scene.player,
      open: open,
      onOpen: locked
          ? null
          : (kind) => _setResource(open == kind ? null : kind),
      onClose: () => _setResource(null),
    );
  }

  void _cancelResearchFor(_MapHudPanel panel, bool open) {
    setState(() => _openPanel = open ? panel : null);
    widget.controller.cancelResearchSelection();
  }

  void _setOpen(_MapHudPanel panel, bool open) {
    if (_panelsLocked) return;
    if (_researchSelectionRequired) {
      _cancelResearchFor(panel, open);
      return;
    }
    if (_researchFocused) {
      widget.controller.closeTurnResearch();
      if (!open) {
        context.playGameSound(GameSoundCue.uiPanelClose);
        return;
      }
    }
    final next = open ? panel : (_openPanel == panel ? null : _openPanel);
    if (next == _openPanel) return;
    final cue = next == _MapHudPanel.research
        ? GameSoundCue.technology
        : _openPanel == null
        ? GameSoundCue.uiPanelOpen
        : GameSoundCue.uiPanelClose;
    setState(() => _openPanel = next);
    context.playGameSound(cue);
  }
}
