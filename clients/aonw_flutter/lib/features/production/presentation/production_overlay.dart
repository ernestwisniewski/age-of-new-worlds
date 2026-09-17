import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_hud_surface.dart';
import '../../audio/presentation/game_audio_actions.dart';
import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../application/production_state.dart';
import '../read_model/production_view.dart';
import 'production_panel.dart';

final class ProductionOverlay extends StatelessWidget {
  const ProductionOverlay({
    required this.state,
    required this.cityName,
    required this.treasury,
    required this.enabled,
    required this.onAction,
    required this.onClose,
    super.key,
  });

  final ProductionState state;
  final String cityName;
  final int treasury;
  final bool enabled;
  final ValueChanged<ProductionActionView> onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    void close() {
      if (state.commandPending) return;
      context.playGameSound(GameSoundCue.uiPanelClose);
      onClose();
    }

    return MapGamepadRegion(
      section: MapHudSection.selectionActions,
      priority: MapGamepadPriority.modal,
      onCancel: close,
      child: Stack(
        children: [
          ModalBarrier(
            color: Colors.black54,
            dismissible: !state.commandPending,
            onDismiss: close,
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AonwSpacing.md),
                child: SizedBox(
                  width: 760,
                  height: MediaQuery.sizeOf(context).height * 0.82,
                  child: AonwHudSurface(
                    key: const ValueKey('production-modal'),
                    elevation: AonwHudElevation.modal,
                    background: AonwColorTokens.background,
                    padding: const EdgeInsets.all(AonwSpacing.md),
                    child: ProductionPanel(
                      state: state,
                      cityName: cityName,
                      treasury: treasury,
                      enabled: enabled,
                      onAction: onAction,
                      onClose: close,
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
}
