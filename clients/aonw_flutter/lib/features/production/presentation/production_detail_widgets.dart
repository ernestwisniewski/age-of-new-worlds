import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import 'production_detail_copy.dart';

final class ProductionDetailSection extends StatelessWidget {
  const ProductionDetailSection({
    required this.title,
    required this.children,
    super.key,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AonwSpacing.md),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AonwColorTokens.surface,
        border: Border.all(color: AonwColorTokens.brand.withAlpha(48)),
        borderRadius: BorderRadius.circular(AonwRadii.panel),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AonwTextStyles.sectionHeader),
            const SizedBox(height: AonwSpacing.sm),
            ...children,
          ],
        ),
      ),
    ),
  );
}

final class ProductionDetailLine extends StatelessWidget {
  const ProductionDetailLine(this.text, {this.met, super.key});
  final String text;
  final bool? met;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: met,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            met == null
                ? Icons.circle
                : met!
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: met == null ? 6 : 18,
            color: met == false
                ? AonwColorTokens.danger
                : AonwColorTokens.brandLight,
          ),
          const SizedBox(width: AonwSpacing.sm),
          Expanded(child: Text(text, style: AonwTextStyles.body)),
        ],
      ),
    ),
  );
}

final class ProductionDetailComparison extends StatelessWidget {
  const ProductionDetailComparison({
    required this.label,
    required this.before,
    required this.after,
    required this.color,
    required this.beforeLabel,
    required this.afterLabel,
    super.key,
  });
  final String label;
  final int before;
  final int after;
  final Color color;
  final String beforeLabel;
  final String afterLabel;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionDetailCopy.of(context);
    final extent = math.max(1, math.max(before.abs(), after.abs()));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AonwSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AonwSpacing.sm,
            children: [
              Text(label, style: AonwTextStyles.bodyStrong),
              Text(
                '${copy.number(before)} → ${copy.number(after)} (${copy.signed(after - before)})',
                style: AonwTextStyles.bodyStrong.copyWith(color: color),
              ),
            ],
          ),
          Semantics(
            label:
                '$label, $beforeLabel: ${copy.number(before)}, $afterLabel: ${copy.number(after)}',
            child: ExcludeSemantics(
              child: Column(
                children: [
                  _bar(before.abs() / extent, color.withAlpha(80)),
                  _bar(after.abs() / extent, color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double fraction, Color color) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AonwColorTokens.background,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          child: ColoredBox(color: color, child: const SizedBox(height: 4)),
        ),
      ),
    ),
  );
}
