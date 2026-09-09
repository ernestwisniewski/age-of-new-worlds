import 'package:flutter/material.dart';

import '../../../audio/presentation/game_audio_actions.dart';
import '../../../players/presentation/player_overlay.dart';
import '../../../resources/presentation/resource_overlay.dart';
import '../../../resources/presentation/resource_strip.dart';
import '../../read_model/player_map_view.dart';

/// Read-only HUD owner for viewers without gameplay panel coordination.
final class ViewerHud extends StatefulWidget {
  const ViewerHud({
    required this.player,
    required this.sessionIdentity,
    this.blocked = false,
    super.key,
  });
  final PlayerMapView player;
  final Object sessionIdentity;
  final bool blocked;

  @override
  State<ViewerHud> createState() => _ViewerHudState();
}

final class _ViewerHudState extends State<ViewerHud> {
  ResourcePopup? _open;
  String? _playerId;

  @override
  void didUpdateWidget(ViewerHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blocked ||
        widget.sessionIdentity != oldWidget.sessionIdentity ||
        widget.player.actorPlayerId != oldWidget.player.actorPlayerId ||
        widget.player.stamp.mapHash != oldWidget.player.stamp.mapHash) {
      _open = null;
      _playerId = null;
    }
  }

  void _setOpen(ResourcePopup? value) {
    if (widget.blocked || value == _open) return;
    context.playGameSound(
      value == null ? GameSoundCue.uiPanelClose : GameSoundCue.uiPanelOpen,
    );
    setState(() {
      _open = value;
      _playerId = null;
    });
  }

  void _setPlayer(String? id) {
    if (widget.blocked) return;
    final next = id == _playerId ? null : id;
    context.playGameSound(
      next == null ? GameSoundCue.uiPanelClose : GameSoundCue.uiPanelOpen,
    );
    setState(() {
      _playerId = next;
      _open = null;
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (_open == null)
        PlayerOverlay(
          player: widget.player,
          selectedId: _playerId,
          onSelect: widget.blocked ? null : _setPlayer,
          onClose: () => _setPlayer(null),
        ),
      ResourceOverlay(
        player: widget.player,
        open: _open,
        onOpen: widget.blocked
            ? null
            : (value) => _setOpen(_open == value ? null : value),
        onClose: () => _setOpen(null),
      ),
    ],
  );
}
