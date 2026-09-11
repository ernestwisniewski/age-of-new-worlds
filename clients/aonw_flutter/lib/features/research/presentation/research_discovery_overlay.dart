import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/assets/sprite_frame_id.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../design_system/widgets/aonw_sprite_thumbnail.dart';
import '../../../l10n/l10n.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../../map/read_model/player_map_view.dart';
import '../../settings/presentation/client_settings_scope.dart';
import '../application/research_discovery_inbox.dart';
import '../read_model/research_view.dart';
import 'research_copy.dart';

part 'research_discovery_panel.dart';

final class ResearchDiscoveryOverlay extends StatefulWidget {
  const ResearchDiscoveryOverlay({
    required this.player,
    required this.session,
    this.options,
    this.blocked = false,
    super.key,
  });

  final PlayerMapView player;
  final Object session;
  final ResearchOptionsView? options;
  final bool blocked;

  @override
  State<ResearchDiscoveryOverlay> createState() =>
      _ResearchDiscoveryOverlayState();
}

final class _ResearchDiscoveryOverlayState
    extends State<ResearchDiscoveryOverlay> {
  final _inbox = ResearchDiscoveryInbox();
  var _suppress = false;

  @override
  Widget build(BuildContext context) {
    final settings = ClientSettingsScope.settingsOf(context);
    final previous = _inbox.current;
    _inbox.observe(
      widget.player,
      session: widget.session,
      enabled: settings.showResearchDiscoveries,
    );
    final current = _inbox.current;
    if (!identical(previous, current)) _suppress = false;
    if (current == null || widget.blocked) return const SizedBox.shrink();
    if (_inbox.minimized) return _restoreButton(context);
    return _popup(current.technology);
  }

  Widget _restoreButton(BuildContext context) => Positioned(
    left: AonwSpacing.md,
    right: AonwSpacing.md,
    bottom: 100,
    child: Align(
      alignment: Alignment.centerRight,
      child: MapGamepadRegion(
        section: MapHudSection.globalActions,
        child: FilledButton.icon(
          key: const ValueKey('restore-research-discovery'),
          onPressed: () => setState(() => _inbox.minimized = false),
          icon: const Icon(Icons.science_outlined),
          label: Text(context.aonwL10n.researchDiscoveryRestore),
        ),
      ),
    ),
  );

  Widget _popup(TechnologyIdView technology) {
    return Positioned.fill(
      child: Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Color(0x99000000)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AonwSpacing.md),
              child: Center(
                child: MapGamepadRegion(
                  section: MapHudSection.globalActions,
                  priority: MapGamepadPriority.popup,
                  onCancel: _dismiss,
                  child: Focus(
                    autofocus: true,
                    onKeyEvent: _onKey,
                    child: _DiscoveryPanel(
                      technology: technology,
                      playerName:
                          widget.player.participants
                              .where(
                                (player) =>
                                    player.id == widget.player.actorPlayerId,
                              )
                              .firstOrNull
                              ?.name ??
                          widget.player.actorPlayerId,
                      option: _option(technology),
                      suppress: _suppress,
                      onSuppress: (value) => setState(() => _suppress = value),
                      onDismiss: _dismiss,
                      onMinimize: () => setState(() => _inbox.minimized = true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ResearchOptionView? _option(TechnologyIdView technology) {
    final options = widget.options;
    if (options == null ||
        options.playerId != widget.player.actorPlayerId ||
        options.stamp.revision != widget.player.stamp.revision ||
        options.stamp.stateDigest != widget.player.stamp.stateDigest ||
        options.stamp.mapHash != widget.player.stamp.mapHash ||
        options.stamp.rulesetHash != widget.player.stamp.rulesetHash) {
      return null;
    }
    return options.options
        .where(
          (option) =>
              option.technology == technology &&
              option.availability == TechnologyAvailabilityView.unlocked,
        )
        .firstOrNull;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _dismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _dismiss() {
    if (_suppress) {
      final controller = context
          .getInheritedWidgetOfExactType<ClientSettingsScope>()
          ?.notifier;
      if (controller != null) {
        unawaited(
          controller.update(
            controller.settings.copyWith(showResearchDiscoveries: false),
          ),
        );
      }
    }
    setState(() {
      _inbox.dismiss();
      _suppress = false;
    });
  }
}
