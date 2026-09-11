import 'package:aonw_flutter/features/audio/presentation/game_audio_actions.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/players/presentation/player_overlay.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_overlay.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_strip.dart';
import 'package:flutter/material.dart';

/// Isolates resource and player widgets for their focused interaction goldens.
final class ResourceHudTestHost extends StatefulWidget {
  const ResourceHudTestHost({
    required this.player,
    required this.sessionIdentity,
    this.blocked = false,
    super.key,
  });
  final PlayerMapView player;
  final Object sessionIdentity;
  final bool blocked;

  @override
  State<ResourceHudTestHost> createState() => _ResourceHudTestHostState();
}

final class _ResourceHudTestHostState extends State<ResourceHudTestHost> {
  ResourcePopup? _open;
  String? _playerId;

  @override
  void didUpdateWidget(ResourceHudTestHost oldWidget) {
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
