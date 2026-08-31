import 'package:flutter/material.dart';

import '../aonw_tokens.dart';

final class AonwProgressIndicator extends StatelessWidget {
  const AonwProgressIndicator({
    required this.semanticLabel,
    this.compact = false,
    super.key,
  });

  final String semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final indicator = reducedMotion
        ? Icon(
            Icons.hourglass_top,
            size: compact ? AonwSizes.compactProgress : null,
          )
        : CircularProgressIndicator(strokeWidth: compact ? 2 : 4);
    return Semantics(
      container: true,
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: compact
            ? SizedBox.square(
                dimension: AonwSizes.compactProgress,
                child: indicator,
              )
            : indicator,
      ),
    );
  }
}
