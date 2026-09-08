import 'dart:async';

import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/gamepad_map_input_source.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  for (final mode in ['founding', 'workedHexes', 'expansion']) {
    for (final keyboard in [false, true]) {
      testWidgets(
        'cancels $mode once with ${keyboard ? 'Escape' : 'gamepad B'}',
        (tester) async {
          final events = StreamController<NormalizedGamepadEvent>(sync: true);
          final input = GamepadMapInputSource(events: events.stream);
          final session = FakeGameSession.success(
            testMapScene(units: [testVisibleUnit()], cities: [testCityView()]),
            reachableResult: testReachableView(),
            cityFoundingOptionsResult: testCityFoundingOptionsView(),
            cityInspection: testCityInspectionView(),
          );
          final controller = MapPresentationController(
            capabilities: testGameSessionCapabilities(session),
          );
          addTearDown(controller.dispose);
          addTearDown(input.close);
          addTearDown(events.close);
          await tester.binding.setSurfaceSize(const Size(1000, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            LocalizedTestApp(
              home: MapScreen(controller: controller, inputSource: input),
            ),
          );
          await tester.pumpAndSettle();
          if (mode == 'founding') {
            controller.selectUnit('preview-commander');
            await tester.pumpAndSettle();
            controller.openCityFounding();
          } else {
            controller.selectCity('preview-city');
            await tester.pumpAndSettle();
            controller.startCityManagement(
              CityManagementMode.values.byName(mode),
            );
          }
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          final before = controller.state as GameSessionReady;
          if (keyboard) {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
          } else {
            events.add(_button(1));
          }
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          final after = controller.state as GameSessionReady;
          expect(after.interaction.city?.founderUnitId, isNull);
          expect(after.interaction.city?.managementMode, isNull);
          expect(after.recipient, same(before.recipient));
          expect(after.interaction.selected, before.interaction.selected);
          expect(
            after.interaction.selectedUnitId,
            before.interaction.selectedUnitId,
          );
          if (mode != 'founding') {
            expect(after.interaction.city?.cityId, 'preview-city');
          }
          if (keyboard) {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
          } else {
            events.add(_button(0));
          }
          await tester.pumpAndSettle();
          expect(session.cityCommandCalls, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

NormalizedGamepadEvent _button(double value) => NormalizedGamepadEvent(
  gamepadId: 'pad-1',
  timestamp: 1,
  button: GamepadButton.b,
  value: value,
  rawEvent: GamepadEvent(
    gamepadId: 'pad-1',
    timestamp: 1,
    type: KeyType.button,
    key: GamepadButton.b.name,
    value: value,
  ),
);
