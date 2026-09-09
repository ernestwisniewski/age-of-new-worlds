import 'package:flutter/material.dart';

import '../../audio/presentation/game_audio_actions.dart';
import '../../map/read_model/player_map_view.dart';
import 'resource_overlay.dart';
import 'resource_strip.dart';

/// Read-only HUD owner for viewers without gameplay panel coordination.
final class ResourceHud extends StatefulWidget {
  const ResourceHud({
    required this.player,
    required this.sessionIdentity,
    this.blocked = false,
    super.key,
  });
  final PlayerMapView player;
  final Object sessionIdentity;
  final bool blocked;

  @override
  State<ResourceHud> createState() => _ResourceHudState();
}

final class _ResourceHudState extends State<ResourceHud> {
  ResourcePopup? _open;

  @override
  void didUpdateWidget(ResourceHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blocked ||
        widget.sessionIdentity != oldWidget.sessionIdentity ||
        widget.player.actorPlayerId != oldWidget.player.actorPlayerId ||
        widget.player.stamp.mapHash != oldWidget.player.stamp.mapHash) {
      _open = null;
    }
  }

  void _setOpen(ResourcePopup? value) {
    if (widget.blocked || value == _open) return;
    context.playGameSound(
      value == null ? GameSoundCue.uiPanelClose : GameSoundCue.uiPanelOpen,
    );
    setState(() => _open = value);
  }

  @override
  Widget build(BuildContext context) => ResourceOverlay(
    player: widget.player,
    open: _open,
    onOpen: widget.blocked
        ? null
        : (value) => _setOpen(_open == value ? null : value),
    onClose: () => _setOpen(null),
  );
}
