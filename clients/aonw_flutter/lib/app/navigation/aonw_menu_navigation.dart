import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../design_system/widgets/aonw_menu_adjustable.dart';
import '../../features/map/presentation/input/map_gamepad_input.dart';
import '../../features/map/presentation/input/map_input.dart';

final class AonwMenuNavigation extends StatefulWidget {
  const AonwMenuNavigation({required this.child, this.input, super.key});

  final Stream<MapGamepadInput>? input;
  final Widget child;

  @override
  State<AonwMenuNavigation> createState() => _AonwMenuNavigationState();
}

final class _AonwMenuNavigationState extends State<AonwMenuNavigation>
    with SingleTickerProviderStateMixin {
  final _scopeNode = FocusScopeNode(debugLabel: 'AoNW menu navigation');
  final _frames = MapGamepadFrameController();
  StreamSubscription<MapGamepadInput>? _subscription;
  late final Ticker _ticker;
  var _input = MapGamepadInput.idle;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _subscribe();
  }

  @override
  void didUpdateWidget(AonwMenuNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.input, widget.input)) _subscribe();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _ticker.dispose();
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Actions(
    actions: {DismissIntent: CallbackAction<DismissIntent>(onInvoke: _dismiss)},
    child: FocusTraversalGroup(
      child: FocusScope(node: _scopeNode, autofocus: true, child: widget.child),
    ),
  );

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _input = MapGamepadInput.idle;
    _frames.prime(_input);
    _subscription = widget.input?.listen(_handleInput);
    _synchronizeTicker();
  }

  void _handleInput(MapGamepadInput input) {
    _input = input;
    _synchronizeTicker();
  }

  void _synchronizeTicker() {
    if (_input.isIdle && _frames.isIdle) {
      _lastElapsed = null;
      _ticker.stop();
      return;
    }
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    final seconds = previous == null
        ? 0.0
        : (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    final frame = _frames.advance(input: _input, dt: seconds.clamp(0, 0.05));
    if (_routeAcceptsInput()) _applyFrame(frame);
    _synchronizeTicker();
  }

  bool _routeAcceptsInput() => ModalRoute.of(context)?.isCurrent ?? true;

  Object? _dismiss(DismissIntent intent) {
    unawaited(Navigator.of(context).maybePop());
    return null;
  }

  void _applyFrame(MapGamepadFrame frame) {
    if (frame.cursorStep case final direction?) _navigate(direction);
    if (frame.activatePressed) _activate();
    if (frame.cancelPressed) unawaited(Navigator.of(context).maybePop());
  }

  void _navigate(MapInputCommand direction) {
    final bool forward;
    switch (direction) {
      case MapInputCommand.cursorDown || MapInputCommand.cursorRight:
        forward = true;
      case MapInputCommand.cursorUp || MapInputCommand.cursorLeft:
        forward = false;
      default:
        return;
    }
    if (_tryAdjust(direction)) return;
    final focused = FocusManager.instance.primaryFocus;
    if (focused?.context == null) {
      _focusBoundary(last: !forward);
      return;
    }
    final policy = FocusTraversalGroup.of(focused!.context!);
    final moved = forward ? policy.next(focused) : policy.previous(focused);
    if (!moved) _focusBoundary(last: !forward);
    _scrollFocusedIntoView();
  }

  bool _tryAdjust(MapInputCommand direction) {
    final delta = switch (direction) {
      MapInputCommand.cursorLeft => -1,
      MapInputCommand.cursorRight => 1,
      _ => 0,
    };
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (delta == 0 || focusContext == null) return false;
    return Actions.maybeInvoke(focusContext, AonwMenuAdjustIntent(delta)) ==
        true;
  }

  void _activate() {
    final focused = FocusManager.instance.primaryFocus ?? _focusBoundary();
    final focusContext = focused?.context;
    if (focusContext == null) return;
    Actions.maybeInvoke(focusContext, const ActivateIntent());
  }

  FocusNode? _focusBoundary({bool last = false}) {
    final moved = last ? _scopeNode.previousFocus() : _scopeNode.nextFocus();
    if (!moved) return null;
    _scrollFocusedIntoView();
    return FocusManager.instance.primaryFocus;
  }

  void _scrollFocusedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null || !focusContext.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          focusContext,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ),
      );
    });
  }
}
