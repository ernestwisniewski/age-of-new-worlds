import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../application/turn_presentation_queue.dart';

final class TurnBanner extends StatefulWidget {
  const TurnBanner({
    required this.presentation,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 1800),
    super.key,
  });

  final TurnPresentation? presentation;
  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<TurnBanner> createState() => _TurnBannerState();
}

final class _TurnBannerState extends State<TurnBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleCompletion();
  }

  @override
  void didUpdateWidget(TurnBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation?.turn != widget.presentation?.turn ||
        oldWidget.duration != widget.duration) {
      _scheduleCompletion();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleCompletion() {
    _timer?.cancel();
    if (widget.presentation == null) return;
    _timer = Timer(widget.duration, () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.presentation;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.82),
          child: AnimatedSwitcher(
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: presentation == null
                ? const SizedBox.shrink()
                : _TurnBannerContent(
                    key: ValueKey(presentation.turn),
                    turn: presentation.turn,
                  ),
          ),
        ),
      ),
    );
  }
}

final class _TurnBannerContent extends StatelessWidget {
  const _TurnBannerContent({required this.turn, super.key});

  final int turn;

  @override
  Widget build(BuildContext context) {
    final label = context.aonwL10n.turnSummary('label', turn, 0, 0);
    return AonwPanel(
      key: const ValueKey('turn-banner'),
      semanticLabel: label,
      liveRegion: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AonwSpacing.xl,
        vertical: AonwSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
