import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';

final class NewGameSection extends StatelessWidget {
  const NewGameSection({
    required this.title,
    required this.icon,
    required this.child,
    this.keyName,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? keyName;

  @override
  Widget build(BuildContext context) => AonwPanel(
    key: keyName == null ? null : ValueKey(keyName),
    semanticLabel: title,
    padding: const EdgeInsets.all(AonwSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: AonwColorTokens.brand),
            const SizedBox(width: AonwSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AonwSpacing.md),
        child,
      ],
    ),
  );
}

final class NewGameFact extends StatelessWidget {
  const NewGameFact({
    required this.title,
    required this.body,
    required this.icon,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AonwColorTokens.surfaceDeep.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(AonwRadii.panel),
      border: Border.all(
        color: AonwColorTokens.brandDark.withValues(alpha: 0.7),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AonwSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AonwColorTokens.brandLight),
          const SizedBox(width: AonwSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AonwSpacing.xs),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AonwColorTokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class NewGameSummaryRow extends StatelessWidget {
  const NewGameSummaryRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 170,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AonwColorTokens.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AonwSpacing.md),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
