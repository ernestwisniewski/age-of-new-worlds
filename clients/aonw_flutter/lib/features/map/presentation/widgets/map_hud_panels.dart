import 'package:flutter/material.dart';

import '../../../diplomacy/application/diplomacy_state.dart';
import '../../../diplomacy/presentation/diplomacy_overlay.dart';
import '../../../objectives/presentation/objective_overlay.dart';
import '../../../research/application/research_state.dart';
import '../../../research/presentation/research_overlay.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/pending_action_view.dart';
import '../map_presentation_controller.dart';

enum _MapHudPanel { objectives, research, diplomacy }

final class MapHudPanels extends StatefulWidget {
  const MapHudPanels({
    required this.scene,
    required this.research,
    required this.diplomacy,
    required this.controller,
    super.key,
  });

  final MapScene scene;
  final ResearchState research;
  final DiplomacyState diplomacy;
  final MapPresentationController controller;

  @override
  State<MapHudPanels> createState() => _MapHudPanelsState();
}

final class _MapHudPanelsState extends State<MapHudPanels> {
  _MapHudPanel? _openPanel;

  bool get _researchSelectionRequired =>
      widget.scene.player.pendingAction is PendingResearchSelectionView;

  bool get _terminal => widget.scene.player.turnView.outcome.isTerminal;

  @override
  void didUpdateWidget(covariant MapHudPanels oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    if (sceneChanged || selectionBecameRequired || matchBecameTerminal) {
      _openPanel = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = _researchSelectionRequired || _terminal;
    final effectivePanel = _researchSelectionRequired
        ? _MapHudPanel.research
        : _terminal
        ? null
        : _openPanel;
    return Stack(
      children: [
        ResearchOverlay(
          state: widget.research,
          selectionRequired: _researchSelectionRequired,
          open: effectivePanel == _MapHudPanel.research,
          onOpenChanged: locked
              ? null
              : (open) => _setOpen(_MapHudPanel.research, open),
          onSelect: widget.controller.selectTechnology,
          onRetry: widget.controller.refreshResearch,
        ),
        DiplomacyOverlay(
          actorPlayerId: widget.scene.player.actorPlayerId,
          view: widget.scene.player.diplomacy,
          state: widget.diplomacy,
          open: effectivePanel == _MapHudPanel.diplomacy,
          onOpenChanged: locked
              ? null
              : (open) => _setOpen(_MapHudPanel.diplomacy, open),
          onAction: widget.controller.executeDiplomacyAction,
        ),
        ObjectiveOverlay(
          objectives: widget.scene.map.objectives,
          outcome: widget.scene.player.turnView.outcome,
          open: effectivePanel == _MapHudPanel.objectives,
          onOpenChanged: locked
              ? null
              : (open) => _setOpen(_MapHudPanel.objectives, open),
        ),
      ],
    );
  }

  void _setOpen(_MapHudPanel panel, bool open) {
    setState(() => _openPanel = open ? panel : null);
  }
}
