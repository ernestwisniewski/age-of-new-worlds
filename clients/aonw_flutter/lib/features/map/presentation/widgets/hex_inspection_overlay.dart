import 'package:flutter/material.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../../l10n/l10n.dart';
import '../../application/hex_inspection_state.dart';
import '../../read_model/map_scene.dart';
import '../geometry/odd_q_flat_top_geometry.dart';
import '../input/map_gamepad_navigation.dart';
import 'hex_inspection_content.dart';
import 'hex_inspection_placement.dart';
import 'map_gamepad_region.dart';

final class HexInspectionOverlay extends StatelessWidget {
  const HexInspectionOverlay({
    required this.state,
    required this.scene,
    required this.anchor,
    required this.onClose,
    required this.onRetry,
    super.key,
  });

  final HexInspectionState state;
  final MapScene scene;
  final AonwPoint? anchor;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final point = anchor;
        final placement = HexInspectionPlacement.inViewport(
          viewport,
          point == null
              ? viewport.center(Offset.zero)
              : Offset(point.x, point.y),
        );
        return Stack(
          children: [
            Positioned(
              key: const ValueKey('hex-inspection-placement'),
              left: placement.bounds.left,
              top: placement.bounds.top,
              width: placement.bounds.width,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: placement.bounds.height),
                child: MapGamepadRegion(
                  section: MapHudSection.selectionActions,
                  priority: MapGamepadPriority.popup,
                  scrollBeforeFocus: true,
                  onCancel: onClose,
                  child: CustomPaint(
                    painter: _InspectionPointer(placement),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _Popover(
                        state: state,
                        scene: scene,
                        onClose: onClose,
                        onRetry: onRetry,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

final class _Popover extends StatelessWidget {
  const _Popover({
    required this.state,
    required this.scene,
    required this.onClose,
    required this.onRetry,
  });

  final HexInspectionState state;
  final MapScene scene;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return AonwHudSurface(
      key: const ValueKey('hex-inspection-popover'),
      elevation: AonwHudElevation.floating,
      padding: EdgeInsets.zero,
      semanticLabel: l10n.hexInspectionText('title'),
      child: SingleChildScrollView(
        key: ValueKey(('hex-inspection-scroll', state.coordinate)),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _title(l10n)),
                IconButton(
                  key: const ValueKey('close-hex-inspection'),
                  tooltip: l10n.hexInspectionText('close'),
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._body(l10n),
          ],
        ),
      ),
    );
  }

  Widget _title(AonwLocalizations l10n) => Text(
    state is HexInspectionReady
        ? l10n.hexInspectionKind((state as HexInspectionReady).view.kind.name)
        : l10n.hexInspectionText('title'),
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  );

  List<Widget> _body(AonwLocalizations l10n) => switch (state) {
    HexInspectionReady(:final view) => [
      HexInspectionContent(view: view, scene: scene),
    ],
    HexInspectionLoading() => [
      AonwProgressIndicator(
        compact: true,
        semanticLabel: l10n.hexInspectionText('loading'),
      ),
    ],
    HexInspectionFailure(:final code) => [
      Text(l10n.hexInspectionText(code.name)),
      TextButton(onPressed: onRetry, child: Text(l10n.retry)),
    ],
  };
}

final class _InspectionPointer extends CustomPainter {
  const _InspectionPointer(this.placement);
  final HexInspectionPlacement placement;

  @override
  void paint(Canvas canvas, Size size) {
    final y = placement.arrowTop.clamp(
      8.0,
      size.height < 16 ? 8.0 : size.height - 8,
    );
    final x = placement.arrowOnLeft ? 6.0 : size.width - 6;
    final tip = placement.arrowOnLeft ? 0.0 : size.width;
    final path = Path()
      ..moveTo(x, y - 6)
      ..lineTo(tip, y)
      ..lineTo(x, y + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = AonwColorTokens.brand);
  }

  @override
  bool shouldRepaint(_InspectionPointer oldDelegate) =>
      oldDelegate.placement != placement;
}
