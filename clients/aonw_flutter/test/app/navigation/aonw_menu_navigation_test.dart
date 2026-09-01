import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_menu_navigation.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_menu_adjustable.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';
import '../../support/test_map_input_source.dart';

void main() {
  testWidgets('gamepad traverses, activates, and adjusts menu controls', (
    tester,
  ) async {
    final input = TestMapInputSource();
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    final sliderFocus = FocusNode();
    addTearDown(input.close);
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);
    addTearDown(sliderFocus.dispose);
    var activations = 0;
    var sliderValue = 0.5;

    await tester.pumpWidget(
      MaterialApp(
        home: AonwMenuNavigation(
          input: input.continuousInputs,
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ListView(
                children: [
                  FilledButton(
                    focusNode: firstFocus,
                    onPressed: () {},
                    child: const Text('First'),
                  ),
                  FilledButton(
                    focusNode: secondFocus,
                    onPressed: () => activations += 1,
                    child: const Text('Second'),
                  ),
                  AonwMenuAdjustable(
                    onAdjust: (delta) => setState(
                      () =>
                          sliderValue = (sliderValue + delta * 0.1).clamp(0, 1),
                    ),
                    child: Slider(
                      focusNode: sliderFocus,
                      value: sliderValue,
                      onChanged: (value) => setState(() => sliderValue = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await _pulse(tester, input, const MapGamepadInput(dpadDown: true));
    expect(firstFocus.hasFocus, isTrue);
    await _pulse(tester, input, const MapGamepadInput(dpadDown: true));
    expect(secondFocus.hasFocus, isTrue);
    await _pulse(tester, input, const MapGamepadInput(activate: true));
    expect(activations, 1);
    await _pulse(tester, input, const MapGamepadInput(dpadDown: true));
    expect(sliderFocus.hasFocus, isTrue);
    await _pulse(tester, input, const MapGamepadInput(dpadLeft: true));
    expect(sliderValue, closeTo(0.4, 0.0001));
  });

  testWidgets('keyboard opens and leaves pregame routes', (tester) async {
    final input = TestMapInputSource();
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(testMapScene()),
      ),
    );
    await tester.pumpWidget(
      AonwApp(mapController: controller, mapInputSource: input),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Play with the computer'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('main-menu-panel')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('gamepad opens and leaves pregame routes', (tester) async {
    final input = TestMapInputSource();
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(testMapScene()),
      ),
    );
    await tester.pumpWidget(
      AonwApp(mapController: controller, mapInputSource: input),
    );
    await tester.pumpAndSettle();

    await _pulse(tester, input, const MapGamepadInput(dpadDown: true));
    await _pulse(tester, input, const MapGamepadInput(activate: true));
    await tester.pumpAndSettle();
    expect(find.text('Play with the computer'), findsOneWidget);
    await _pulse(tester, input, const MapGamepadInput(cancel: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('main-menu-panel')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _pulse(
  WidgetTester tester,
  TestMapInputSource input,
  MapGamepadInput value,
) async {
  input.addContinuous(value);
  await tester.pump(const Duration(milliseconds: 16));
  input.addContinuous(MapGamepadInput.idle);
  await tester.pump(const Duration(milliseconds: 16));
}
