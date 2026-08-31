import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  testWidgets('applies camera client preference', (tester) async {
    final settings = ClientSettingsController.ephemeral();
    await settings.update(
      ClientSettings.defaults.copyWith(cameraSensitivity: 2),
    );
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );
    final flameGame = AonwFlameGame();
    addTearDown(settings.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        home: ClientSettingsScope(
          controller: settings,
          child: MapScreen(
            controller: controller,
            flameGameFactory: () => flameGame,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(flameGame.inputSurface.debugCameraSensitivity, 2);
  });
}
