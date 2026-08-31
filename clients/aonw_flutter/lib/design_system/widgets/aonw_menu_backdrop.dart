import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../aonw_tokens.dart';

const aonwMenuBackgroundAsset = 'assets/main_menu/background.jpg';
const aonwLogoAsset = 'assets/runtime/ui/logo.webp';

final class AonwMenuBackdrop extends StatefulWidget {
  const AonwMenuBackdrop({required this.child, super.key});

  final Widget child;

  @override
  State<AonwMenuBackdrop> createState() => _AonwMenuBackdropState();
}

final class _AonwMenuBackdropState extends State<AonwMenuBackdrop>
    with SingleTickerProviderStateMixin {
  static const _sourceAspectRatio = 1536 / 1024;
  static const _desktopBaseScale = 1.08;
  static const _desktopPulseScale = 0.012;
  static const _compactBaseScale = 1.04;
  static const _duration = Duration(seconds: 56);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AonwMenuBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    if (_motionEnabled) {
      if (!_controller.isAnimating) unawaited(_controller.repeat());
      return;
    }
    if (_controller.isAnimating) _controller.stop();
  }

  bool get _motionEnabled {
    final mediaQuery = MediaQuery.maybeOf(context);
    return TickerMode.valuesOf(context).enabled &&
        !(mediaQuery?.disableAnimations ?? false) &&
        !_isRunningWidgetTest;
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AonwColorTokens.background,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ClipRect(child: LayoutBuilder(builder: _buildImageLayers)),
        ),
        Positioned.fill(child: widget.child),
      ],
    ),
  );

  Widget _buildImageLayers(BuildContext context, BoxConstraints constraints) {
    final width = math.max(1, constraints.maxWidth);
    final height = math.max(1, constraints.maxHeight);
    final viewportAspect = width / height;
    final coverWidth = viewportAspect > _sourceAspectRatio
        ? width
        : height * _sourceAspectRatio;
    final coverHeight = viewportAspect > _sourceAspectRatio
        ? width / _sourceAspectRatio
        : height;
    final travelX = (width * 0.028).clamp(12.0, 42.0).toDouble();
    final travelY = (height * 0.026).clamp(10.0, 36.0).toDouble();
    final horizontalOverhang = (travelX + width * 0.035)
        .clamp(56.0, 160.0)
        .toDouble();
    final verticalOverhang = (travelY + height * 0.04)
        .clamp(64.0, 180.0)
        .toDouble();
    final desktopMotion = width >= 900 && height >= 620;
    final image = Image.asset(
      aonwMenuBackgroundAsset,
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
      filterQuality: FilterQuality.high,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          aonwMenuBackgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          filterQuality: FilterQuality.high,
        ),
        AnimatedBuilder(
          animation: _controller,
          child: SizedBox(
            width: coverWidth + horizontalOverhang * 2,
            height: coverHeight + verticalOverhang * 2,
            child: image,
          ),
          builder: (context, child) {
            final phase = _controller.value * math.pi * 2;
            final offset = _motionEnabled
                ? Offset(
                    math.sin(phase) * travelX,
                    math.sin(phase * 0.82) * travelY,
                  )
                : Offset.zero;
            final baseScale = desktopMotion
                ? _desktopBaseScale
                : _compactBaseScale;
            final scale =
                baseScale +
                (_motionEnabled && desktopMotion
                    ? math.sin(phase * 0.5) * _desktopPulseScale
                    : 0);
            return Center(
              child: Transform.translate(
                offset: offset,
                child: Transform.scale(scale: scale, child: child),
              ),
            );
          },
        ),
      ],
    );
  }
}

bool get _isRunningWidgetTest {
  var result = false;
  assert(() {
    result = WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
    return true;
  }());
  return result;
}
