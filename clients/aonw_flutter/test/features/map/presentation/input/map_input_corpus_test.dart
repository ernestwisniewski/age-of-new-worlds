import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  testWidgets('pointer keyboard and gamepad honor the original input corpus', (
    tester,
  ) async {
    final oracle =
        jsonDecode(_oracleFile().readAsStringSync()) as Map<String, dynamic>;
    final dimensions = oracle['map'] as Map<String, dynamic>;
    final cols = dimensions['cols'] as int;
    final rows = dimensions['rows'] as int;

    for (final value in oracle['inputCases'] as List<dynamic>) {
      final inputCase = value as Map<String, dynamic>;
      final gamepadEvents = StreamController<NormalizedGamepadEvent>(
        sync: true,
      );
      final input = GamepadMapInputSource(events: gamepadEvents.stream);
      addTearDown(input.close);
      addTearDown(gamepadEvents.close);
      final session = FakeGameSession.success(
        testMapScene(cols: cols, rows: rows),
      );
      final controller = MapPresentationController(
        capabilities: testGameSessionCapabilities(session),
      );
      final flameGame = AonwFlameGame();
      await tester.pumpWidget(
        LocalizedTestApp(
          home: Scaffold(
            body: MapScreen(
              controller: controller,
              inputSource: input,
              flameGameFactory: () => flameGame,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      switch (inputCase['source']) {
        case 'pointer':
          final coordinate = _coordinate(inputCase['hex']);
          final center = flameGame.debugScreenForHex(coordinate)!;
          final viewport = find.byKey(const ValueKey('map-viewport'));
          final renderBox = tester.renderObject<RenderBox>(viewport);
          await tester.tapAt(
            renderBox.localToGlobal(Offset(center.x, center.y)),
          );
        case 'keyboard':
          for (final event in inputCase['events'] as List<dynamic>) {
            await tester.sendKeyEvent(_keyboardKey(event as String));
          }
        case 'gamepad':
          for (final event in inputCase['events'] as List<dynamic>) {
            final button = GamepadButton.values.byName(event as String);
            gamepadEvents.add(_button(button, 1));
            await tester.pump();
            gamepadEvents.add(_button(button, 0));
            await tester.pump();
          }
        default:
          throw StateError(
            'Unknown input corpus source: ${inputCase['source']}',
          );
      }
      await tester.pump();

      final expected = _coordinate(inputCase['expectedSelectedHex']);
      final ready = controller.state as GameSessionReady;
      expect(
        ready.interaction.selected,
        expected,
        reason: inputCase['source'] as String,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
    }
  });
}

MapHexCoordinate _coordinate(Object? value) {
  final coordinate = value! as List<dynamic>;
  return (col: coordinate[0] as int, row: coordinate[1] as int);
}

LogicalKeyboardKey _keyboardKey(String value) => switch (value) {
  'arrowLeft' => LogicalKeyboardKey.arrowLeft,
  'enter' => LogicalKeyboardKey.enter,
  _ => throw StateError('Unknown keyboard corpus event: $value'),
};

File _oracleFile() {
  for (final path in ['test/fixtures/input/viewport_oracle.json']) {
    final file = File(path);
    if (file.existsSync()) return file;
  }
  throw StateError('Flutter viewport oracle fixture not found.');
}

NormalizedGamepadEvent _button(GamepadButton button, double value) =>
    NormalizedGamepadEvent(
      gamepadId: 'corpus-pad',
      timestamp: 1,
      button: button,
      value: value,
      rawEvent: GamepadEvent(
        gamepadId: 'corpus-pad',
        timestamp: 1,
        type: KeyType.button,
        key: button.name,
        value: value,
      ),
    );
