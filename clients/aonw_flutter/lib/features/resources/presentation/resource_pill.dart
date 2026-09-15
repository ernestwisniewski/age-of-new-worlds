import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import 'resource_icon.dart';
import 'resource_popup.dart';

final class ResourcePill extends StatelessWidget {
  const ResourcePill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.active,
    required this.onPressed,
    this.delta,
    this.warning,
    super.key,
  });

  final String label;
  final String value;
  final String? delta;
  final String? warning;
  final ResourcePopup icon;
  final Color color;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AonwColorTokens.background : color;
    final compact = MediaQuery.sizeOf(context).width < 520;
    final description =
        '$label: $value${delta == null ? '' : ' ($delta)'}'
        '${warning == null ? '' : '\n$warning'}';
    return Semantics(
      button: true,
      selected: active,
      label: description,
      child: Tooltip(
        message: description,
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onPressed,
            onLongPress: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: _surface(compact, foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _surface(bool compact, Color foreground) => Container(
    constraints: const BoxConstraints(minHeight: 34),
    padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: 7),
    decoration: BoxDecoration(
      color: active
          ? color.withAlpha(230)
          : AonwColorTokens.surface.withAlpha(235),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: active ? AonwColorTokens.brandLight : color.withAlpha(170),
      ),
    ),
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warning != null) ...[
            Icon(Icons.warning_amber_rounded, size: 16, color: foreground),
            const SizedBox(width: 4),
          ],
          ResourceIcon(kind: icon, size: compact ? 12 : 16, color: foreground),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontFeatures: AonwTypography.tabularFigures,
            ),
          ),
          if (delta case final change?) ...[
            const SizedBox(width: 5),
            Text(change, style: TextStyle(color: foreground, fontSize: 11)),
          ],
        ],
      ),
    ),
  );
}
