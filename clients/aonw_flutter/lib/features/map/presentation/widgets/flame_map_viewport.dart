import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../game/aonw_flame_game.dart';
import '../../../../l10n/l10n.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/map_view_mode.dart';
import '../input/map_input.dart';

final class FlameMapViewport extends StatefulWidget {
  const FlameMapViewport({
    required this.scene,
    required this.interaction,
    required this.onInput,
    required this.game,
    required this.generation,
    required this.focusNode,
    required this.onRetry,
    super.key,
  });

  final MapScene scene;
  final MapInteractionState interaction;
  final ValueChanged<MapInputCommand> onInput;
  final AonwFlameGame game;
  final int generation;
  final FocusNode focusNode;
  final VoidCallback onRetry;

  @override
  State<FlameMapViewport> createState() => _FlameMapViewportState();
}

final class _FlameMapViewportState extends State<FlameMapViewport> {
  static final _panKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
  };
  static final _commandsByKey = <LogicalKeyboardKey, MapInputCommand>{
    LogicalKeyboardKey.enter: MapInputCommand.activate,
    LogicalKeyboardKey.space: MapInputCommand.activate,
    LogicalKeyboardKey.escape: MapInputCommand.cancel,
    LogicalKeyboardKey.keyR: MapInputCommand.toggleMapViewMode,
  };

  final Set<LogicalKeyboardKey> _pressedPanKeys = {};

  @override
  void didUpdateWidget(covariant FlameMapViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.game, oldWidget.game)) return;
    oldWidget.game.setKeyboardPanDirection(x: 0, y: 0);
    _pressedPanKeys.clear();
  }

  @override
  void dispose() {
    widget.game.setKeyboardPanDirection(x: 0, y: 0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final selection = widget.interaction.selected;
    return Semantics(
      key: const ValueKey('map-viewport'),
      label: l10n.mapSemanticsLabel(
        widget.scene.map.mapId,
        widget.scene.map.cols,
        widget.scene.map.rows,
      ),
      hint: l10n.mapInputHint,
      value: selection == null
          ? l10n.noHexSelected
          : l10n.selectedHex(selection.col, selection.row),
      focusable: true,
      child: ClipRect(
        key: const ValueKey('flame-viewport-clip'),
        child: RepaintBoundary(
          key: const ValueKey('flame-viewport-repaint-boundary'),
          child: Focus(
            focusNode: widget.focusNode,
            autofocus: true,
            onFocusChange: _onFocusChange,
            onKeyEvent: _onKeyEvent,
            child: MapViewportGestureLayer(
              game: widget.game,
              onPointerDown: widget.focusNode.requestFocus,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: GameWidget<AonwFlameGame>(
                  key: ValueKey(('flame-viewport', widget.generation)),
                  game: widget.game,
                  autofocus: false,
                  addRepaintBoundary: false,
                  behavior: HitTestBehavior.opaque,
                  loadingBuilder: (_) => const SizedBox.expand(
                    key: ValueKey('flame-viewport-loading'),
                  ),
                  errorBuilder: _buildError,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final l10n = context.aonwL10n;
    return Center(
      child: AonwMessagePanel(
        key: const ValueKey('flame-load-error'),
        semanticLabel: l10n.mapLoadingFailed,
        title: l10n.mapUnavailable,
        message: l10n.mapLoadFailure,
        actionLabel: l10n.retry,
        onAction: widget.onRetry,
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (_panKeys.contains(key)) {
      if (event is KeyUpEvent) {
        _pressedPanKeys.remove(key);
      } else if (event is KeyDownEvent || event is KeyRepeatEvent) {
        _pressedPanKeys.add(key);
      }
      _synchronizeKeyboardPan();
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final command = _commandsByKey[key];
    if (command == null) return KeyEventResult.ignored;
    widget.onInput(command);
    return KeyEventResult.handled;
  }

  void _onFocusChange(bool focused) {
    if (focused) return;
    _pressedPanKeys.clear();
    _synchronizeKeyboardPan();
  }

  void _synchronizeKeyboardPan() {
    final x = _axis(
      negative: const [LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft],
      positive: const [LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight],
    );
    final y = _axis(
      negative: const [LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp],
      positive: const [LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown],
    );
    widget.game.setKeyboardPanDirection(x: x, y: y);
  }

  double _axis({
    required List<LogicalKeyboardKey> negative,
    required List<LogicalKeyboardKey> positive,
  }) {
    final negativePressed = negative.any(_pressedPanKeys.contains);
    final positivePressed = positive.any(_pressedPanKeys.contains);
    if (negativePressed == positivePressed) return 0;
    return negativePressed ? -1 : 1;
  }
}

final class MapViewportGestureLayer extends StatelessWidget {
  const MapViewportGestureLayer({
    required this.game,
    required this.child,
    this.onPointerDown,
    super.key,
  });

  final AonwFlameGame game;
  final Widget child;
  final VoidCallback? onPointerDown;

  @override
  Widget build(BuildContext context) {
    Widget result = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        onPointerDown?.call();
        game.handleViewportPointerDown(
          event.pointer,
          _vector(event.localPosition),
        );
      },
      onPointerMove: (event) => game.handleViewportPointerMove(
        event.pointer,
        _vector(event.localPosition),
      ),
      onPointerUp: (event) => game.handleViewportPointerUp(event.pointer),
      onPointerCancel: (event) =>
          game.handleViewportPointerCancel(event.pointer),
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        game.handleViewportScroll(
          focalPoint: _vector(event.localPosition),
          deltaY: event.scrollDelta.dy,
        );
      },
      onPointerPanZoomStart: (event) =>
          game.handleViewportPanZoomStart(_vector(event.localPosition)),
      onPointerPanZoomUpdate: (event) => game.handleViewportPanZoomUpdate(
        panDelta: _vector(event.localPanDelta),
        scale: event.scale,
        focalPoint: _vector(event.localPosition),
      ),
      onPointerPanZoomEnd: (_) => game.handleViewportPanZoomEnd(),
      child: child,
    );
    result = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) =>
          game.handleViewportTap(_vector(details.localPosition)),
      child: result,
    );
    return MouseRegion(
      onHover: (event) =>
          game.handleViewportHover(_vector(event.localPosition)),
      onExit: (_) => game.handleViewportExit(),
      child: result,
    );
  }

  static Vector2 _vector(Offset offset) => Vector2(offset.dx, offset.dy);
}

final class MapViewModeToggle extends StatelessWidget {
  const MapViewModeToggle({
    required this.value,
    required this.allowGraphicMode,
    required this.onChanged,
    super.key,
  });

  final MapViewMode value;
  final bool allowGraphicMode;
  final ValueChanged<MapViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Tooltip(
      key: const ValueKey('map-view-mode-toggle'),
      message: allowGraphicMode
          ? l10n.mapViewModeTooltip
          : l10n.mapViewGraphicUnavailable,
      child: SegmentedButton<MapViewMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: MapViewMode.graphic,
            enabled: allowGraphicMode,
            label: Text(l10n.mapViewModeGraphic),
          ),
          ButtonSegment(
            value: MapViewMode.tile,
            label: Text(l10n.mapViewModeTiles),
          ),
        ],
        selected: {value},
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          minimumSize: WidgetStateProperty.all(const Size(0, 30)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 10),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AonwColorTokens.textTertiary;
            }
            if (states.contains(WidgetState.selected)) {
              return AonwColorTokens.background;
            }
            return AonwColorTokens.textSecondary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AonwColorTokens.textPrimary;
            }
            return AonwColorTokens.background.withAlpha(205);
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.disabled)
                ? AonwColorTokens.textTertiary
                : AonwColorTokens.textSecondary;
            return BorderSide(color: color);
          }),
          textStyle: WidgetStateProperty.all(AonwTextStyles.labelSmall),
        ),
        onSelectionChanged: (selection) {
          final selected = selection.single;
          if (selected != value) onChanged(selected);
        },
      ),
    );
  }
}
