import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../game/aonw_flame_game.dart';
import '../../../../l10n/l10n.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../input/map_input.dart';

final class FlameMapViewport extends StatelessWidget {
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

  static final _commandsByKey = <LogicalKeyboardKey, MapInputCommand>{
    LogicalKeyboardKey.arrowUp: MapInputCommand.cursorUp,
    LogicalKeyboardKey.keyW: MapInputCommand.cursorUp,
    LogicalKeyboardKey.arrowDown: MapInputCommand.cursorDown,
    LogicalKeyboardKey.keyS: MapInputCommand.cursorDown,
    LogicalKeyboardKey.arrowLeft: MapInputCommand.cursorLeft,
    LogicalKeyboardKey.keyA: MapInputCommand.cursorLeft,
    LogicalKeyboardKey.arrowRight: MapInputCommand.cursorRight,
    LogicalKeyboardKey.keyD: MapInputCommand.cursorRight,
    LogicalKeyboardKey.enter: MapInputCommand.activate,
    LogicalKeyboardKey.space: MapInputCommand.activate,
    LogicalKeyboardKey.escape: MapInputCommand.cancel,
    LogicalKeyboardKey.keyR: MapInputCommand.toggleReference,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final selection = interaction.selected;
    return Semantics(
      key: const ValueKey('map-viewport'),
      label: l10n.mapSemanticsLabel(
        scene.map.mapId,
        scene.map.cols,
        scene.map.rows,
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
            focusNode: focusNode,
            autofocus: true,
            onKeyEvent: _onKeyEvent,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => focusNode.requestFocus(),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: GameWidget<AonwFlameGame>(
                  key: ValueKey(('flame-viewport', generation)),
                  game: game,
                  autofocus: false,
                  addRepaintBoundary: false,
                  behavior: HitTestBehavior.opaque,
                  loadingBuilder: (_) => const SizedBox.expand(
                    key: ValueKey('flame-viewport-loading'),
                  ),
                  errorBuilder: (context, error) {
                    final l10n = context.aonwL10n;
                    return Center(
                      child: AonwMessagePanel(
                        key: const ValueKey('flame-load-error'),
                        semanticLabel: l10n.mapLoadingFailed,
                        title: l10n.mapUnavailable,
                        message: l10n.mapLoadFailure,
                        actionLabel: l10n.retry,
                        onAction: onRetry,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final command = _commandsByKey[event.logicalKey];
    if (command == null) return KeyEventResult.ignored;
    onInput(command);
    return KeyEventResult.handled;
  }
}

final class MapReferenceToggle extends StatelessWidget {
  const MapReferenceToggle({
    required this.visible,
    required this.onPressed,
    super.key,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return IconButton.filledTonal(
      key: const ValueKey('reference-toggle'),
      tooltip: visible ? l10n.hideReferenceLayer : l10n.showReferenceLayer,
      onPressed: onPressed,
      icon: Icon(visible ? Icons.layers : Icons.layers_clear),
    );
  }
}
