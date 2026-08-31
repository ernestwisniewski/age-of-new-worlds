import 'package:flutter/material.dart';

import '../aonw_tokens.dart';

final class AonwPanel extends StatelessWidget {
  const AonwPanel({
    required this.child,
    this.semanticLabel,
    this.liveRegion = false,
    this.maxWidth,
    this.padding = const EdgeInsets.all(AonwSpacing.md),
    super.key,
  });

  final Widget child;
  final String? semanticLabel;
  final bool liveRegion;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);
    if (maxWidth case final width?) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: content,
      );
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      liveRegion: liveRegion,
      child: Card(child: content),
    );
  }
}

final class AonwMessagePanel extends StatelessWidget {
  const AonwMessagePanel({
    required this.semanticLabel,
    required this.title,
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
    this.maxWidth = 420,
    super.key,
  }) : assert((actionLabel == null) == (onAction == null));

  final String semanticLabel;
  final String title;
  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => AonwPanel(
    semanticLabel: semanticLabel,
    liveRegion: true,
    maxWidth: maxWidth,
    padding: const EdgeInsets.all(AonwSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AonwSpacing.sm),
        Text(message, textAlign: TextAlign.center),
        if (detail case final value?) ...[
          const SizedBox(height: AonwSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.labelSmall),
        ],
        if (actionLabel case final label?) ...[
          const SizedBox(height: AonwSpacing.lg),
          FilledButton(onPressed: onAction, child: Text(label)),
        ],
      ],
    ),
  );
}
