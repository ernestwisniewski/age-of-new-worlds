import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../input/map_gamepad_navigation.dart';
import '../input/map_input.dart';

part 'map_gamepad_panel_scroll.dart';

final class MapGamepadNavigationScope extends InheritedWidget {
  const MapGamepadNavigationScope({
    required this.navigation,
    required super.child,
    super.key,
  });

  final MapGamepadNavigation navigation;

  static MapGamepadNavigation? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MapGamepadNavigationScope>()
      ?.navigation;

  @override
  bool updateShouldNotify(MapGamepadNavigationScope oldWidget) =>
      !identical(navigation, oldWidget.navigation);
}

final class MapGamepadRegion extends StatefulWidget {
  const MapGamepadRegion({
    required this.section,
    required this.child,
    this.priority = MapGamepadPriority.hud,
    this.onCancel,
    this.bottomCommand = false,
    super.key,
  });

  final bool bottomCommand;
  final MapHudSection section;
  final MapGamepadPriority priority;
  final VoidCallback? onCancel;
  final Widget child;

  @override
  State<MapGamepadRegion> createState() => _MapGamepadRegionState();
}

final class _MapGamepadRegionState extends State<MapGamepadRegion> {
  final _scope = FocusScopeNode(debugLabel: 'AoNW gamepad region');
  MapGamepadNavigation? _navigation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = MapGamepadNavigationScope.maybeOf(context);
    if (!identical(next, _navigation)) {
      _navigation?.unregister(this);
      _navigation = next;
    }
    _register();
  }

  @override
  void didUpdateWidget(MapGamepadRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _register();
  }

  void _register() => _navigation?.register(
    this,
    MapGamepadRegionEntry(
      scope: _scope,
      bottomCommand: widget.bottomCommand,
      section: widget.section,
      priority: widget.priority,
      onCancel: widget.onCancel,
      onScroll: _scrollPanel,
    ),
  );

  @override
  void dispose() {
    _navigation?.unregister(this);
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FocusScope(node: _scope, onKeyEvent: _onKeyEvent, child: widget.child);

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    return _navigation?.handleCommand(MapInputCommand.cancel) == true
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }
}

final class MapGamepadFocusRing extends StatefulWidget {
  const MapGamepadFocusRing({required this.navigation, super.key});

  final MapGamepadNavigation navigation;

  @override
  State<MapGamepadFocusRing> createState() => _MapGamepadFocusRingState();
}

final class _MapGamepadFocusRingState extends State<MapGamepadFocusRing> {
  final _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      key: _canvasKey,
      painter: _FocusRingPainter(widget.navigation, () {
        final box = _canvasKey.currentContext?.findRenderObject();
        return box is RenderBox ? box.localToGlobal(Offset.zero) : Offset.zero;
      }),
    ),
  );
}

final class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter(this.navigation, this.origin) : super(repaint: navigation);

  final MapGamepadNavigation navigation;
  final Offset Function() origin;

  @override
  void paint(Canvas canvas, Size size) {
    final box = navigation.highlightedBox;
    if (box == null || !box.attached || !box.hasSize) return;
    final rect = (box.localToGlobal(Offset.zero) & box.size)
        .shift(-origin())
        .inflate(3);
    if (rect.isEmpty) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = AonwColorTokens.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) => true;
}
