import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../design_system/aonw_tokens.dart';

final class PerformanceCounter extends StatefulWidget {
  const PerformanceCounter({required this.showFps, this.zoom, super.key});

  final bool showFps;
  final double? zoom;

  @override
  State<PerformanceCounter> createState() => _PerformanceCounterState();
}

final class _PerformanceCounterState extends State<PerformanceCounter>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  var _lastSample = Duration.zero;
  var _frames = 0;
  var _fps = 0;
  var _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
    _ticker = createTicker(_sample);
    _synchronizeTicker();
  }

  @override
  void didUpdateWidget(PerformanceCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizeTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _synchronizeTicker();
  }

  void _synchronizeTicker() {
    final active = widget.showFps && _resumed;
    if (_ticker.isActive == active) return;
    _frames = 0;
    _lastSample = Duration.zero;
    _fps = 0;
    if (active) {
      unawaited(_ticker.start());
    } else {
      _ticker.stop();
    }
  }

  void _sample(Duration elapsed) {
    _frames++;
    final duration = elapsed - _lastSample;
    if (duration < const Duration(milliseconds: 500)) return;
    final fps =
        (_frames * Duration.microsecondsPerSecond / duration.inMicroseconds)
            .round()
            .clamp(0, 999);
    if (_fps != fps) setState(() => _fps = fps);
    _frames = 0;
    _lastSample = elapsed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      if (widget.showFps) '$_fps FPS',
      if (widget.zoom case final zoom?) '${zoom.toStringAsFixed(2)}Z',
    ];
    if (labels.isEmpty) return const SizedBox.shrink();
    return RepaintBoundary(
      child: DecoratedBox(
        key: const ValueKey('performance-counter'),
        decoration: BoxDecoration(
          color: AonwColorTokens.background.withAlpha(218),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AonwColorTokens.brand.withAlpha(130)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(
            labels.join(' · '),
            maxLines: 1,
            style: AonwTextStyles.labelSmall.copyWith(
              color: AonwColorTokens.brandLight,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
