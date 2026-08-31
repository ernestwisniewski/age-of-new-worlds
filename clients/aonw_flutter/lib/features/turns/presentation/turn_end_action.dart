part of 'turn_hud.dart';

enum _EndTurnMode { waiting, ready, action }

final class _EndTurnAction extends StatefulWidget {
  const _EndTurnAction({
    required this.turn,
    required this.action,
    required this.onPressed,
    required this.aiTurn,
  });

  final RecipientTurnView turn;
  final TurnActionState action;
  final VoidCallback onPressed;
  final LocalAiTurnState aiTurn;

  @override
  State<_EndTurnAction> createState() => _EndTurnActionState();
}

final class _EndTurnActionState extends State<_EndTurnAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _EndTurnAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _mode(oldWidget);
    final current = _mode(widget);
    if (previous != current &&
        current == _EndTurnMode.ready &&
        !MediaQuery.disableAnimationsOf(context)) {
      unawaited(HapticFeedback.mediumImpact());
    }
    _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  _EndTurnMode _mode(_EndTurnAction value) {
    if (value.action.inFlight ||
        value.aiTurn.blocksGameplay ||
        value.turn.ownSubmitted) {
      return _EndTurnMode.waiting;
    }
    if (value.turn.canEndTurn) return _EndTurnMode.ready;
    return _EndTurnMode.action;
  }

  void _syncPulse() {
    final shouldPulse =
        widget.turn.pendingAction != null &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (shouldPulse && !_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final mode = _mode(widget);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AonwMotion.scene;
    final visual = _EndTurnVisual.resolve(context, widget, mode);
    final button = _button(
      compact: compact,
      duration: duration,
      visual: visual,
      mode: mode,
    );
    return FocusTraversalOrder(
      order: const NumericFocusOrder(3),
      child: Tooltip(
        message: visual.tooltip,
        child: Semantics(
          button: true,
          enabled: mode == _EndTurnMode.ready,
          label: visual.tooltip,
          child: GestureDetector(
            key: const ValueKey('end-turn'),
            behavior: HitTestBehavior.opaque,
            onTap: mode == _EndTurnMode.ready ? widget.onPressed : null,
            child: AnimatedOpacity(
              duration: duration,
              opacity: mode == _EndTurnMode.waiting ? 0.62 : 1,
              child: widget.turn.pendingAction == null
                  ? button
                  : AnimatedBuilder(
                      animation: _pulse,
                      child: button,
                      builder: (context, child) => CustomPaint(
                        foregroundPainter: _PulsingBorderPainter(
                          progress: _pulse.value,
                          color: visual.glow,
                        ),
                        child: child,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button({
    required bool compact,
    required Duration duration,
    required _EndTurnVisual visual,
    required _EndTurnMode mode,
  }) => AnimatedContainer(
    duration: duration,
    curve: AonwMotion.stateChange,
    width: compact ? 96 : 136,
    height: 48,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: visual.gradient,
      ),
      borderRadius: BorderRadius.circular(AonwRadii.button),
      border: Border.all(color: visual.border, width: 1.4),
      boxShadow: mode == _EndTurnMode.waiting
          ? null
          : [
              BoxShadow(
                color: visual.glow.withAlpha(96),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(visual.icon, size: compact ? 12 : 14, color: visual.foreground),
        SizedBox(width: compact ? 4 : 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              visual.label,
              maxLines: 1,
              style: TextStyle(
                color: visual.foreground,
                fontFamily: AonwTypography.headingFamily,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _EndTurnVisual {
  const _EndTurnVisual({
    required this.gradient,
    required this.border,
    required this.glow,
    required this.foreground,
    required this.label,
    required this.tooltip,
    required this.icon,
  });

  final List<Color> gradient;
  final Color border;
  final Color glow;
  final Color foreground;
  final String label;
  final String tooltip;
  final IconData icon;

  factory _EndTurnVisual.resolve(
    BuildContext context,
    _EndTurnAction action,
    _EndTurnMode mode,
  ) => switch (mode) {
    _EndTurnMode.waiting => _EndTurnVisual(
      gradient: [
        Color.lerp(AonwColorTokens.surface.withAlpha(150), Colors.white, 0.08)!,
        AonwColorTokens.surface.withAlpha(150),
      ],
      border: const Color(0xFF555566).withAlpha(210),
      glow: const Color(0xFF555566),
      foreground: const Color(0xFF555566),
      label: action.action.inFlight || action.aiTurn.inFlight
          ? context.aonwL10n.turnText('actionEnding')
          : _turnStatus(context.aonwL10n, action.turn),
      tooltip: _turnStatus(context.aonwL10n, action.turn),
      icon: Icons.hourglass_empty,
    ),
    _EndTurnMode.ready => _EndTurnVisual(
      gradient: const [Color(0xFFD2A856), Color(0xFFB68838)],
      border: AonwColorTokens.copperDeep,
      glow: AonwColorTokens.copper,
      foreground: AonwColorTokens.background,
      label: context.aonwL10n.turnText('actionEnd'),
      tooltip: context.aonwL10n.turnText('actionEnd'),
      icon: Icons.check_circle_outline,
    ),
    _EndTurnMode.action => _EndTurnVisual(
      gradient: [
        Color.lerp(AonwColorTokens.surface.withAlpha(222), Colors.white, 0.08)!,
        AonwColorTokens.surface.withAlpha(222),
      ],
      border: AonwColorTokens.brandLight.withAlpha(210),
      glow: AonwColorTokens.brandLight,
      foreground: AonwColorTokens.brandLight,
      label: _turnStatus(context.aonwL10n, action.turn),
      tooltip: _turnStatus(context.aonwL10n, action.turn),
      icon: Icons.arrow_forward,
    ),
  };
}

final class _PulsingBorderPainter extends CustomPainter {
  const _PulsingBorderPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = Curves.easeInOut.transform(progress);
    final rect = BorderRadius.circular(
      AonwRadii.button,
    ).toRRect((Offset.zero & size).deflate(1.2 + pulse * 0.2));
    canvas
      ..drawRRect(
        rect,
        Paint()
          ..color = color.withAlpha((42 + pulse * 74).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 + pulse * 2.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRRect(
        rect,
        Paint()
          ..color = Color.lerp(
            color,
            Colors.white,
            0.16,
          )!.withAlpha((188 + pulse * 56).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7 + pulse,
      );
  }

  @override
  bool shouldRepaint(covariant _PulsingBorderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
