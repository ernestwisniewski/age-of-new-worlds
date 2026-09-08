import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets(
    'AI effort follows loaded settings and controller replacement without changing the scene',
    (tester) async {
      final first = _coordinator();
      await first.load();
      final firstController = MapPresentationController.fromCoordinator(first);
      var settings = ClientSettingsController(store: _Store(true));
      await tester.pumpWidget(
        AonwApp(mapController: firstController, settingsController: settings),
      );
      await tester.pumpAndSettle();
      expect(settings.isLoaded, isTrue);
      final initial = (first.state as GameSessionReady).scene;
      expect(first.aiRuntimeProfile, LocalAiRuntimeProfileView.batterySaver);
      for (final enabled in [false, true]) {
        await settings.update(
          settings.settings.copyWith(
            ai: ClientAiSettings(batterySaver: enabled),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          first.aiRuntimeProfile,
          enabled
              ? LocalAiRuntimeProfileView.batterySaver
              : LocalAiRuntimeProfileView.standard,
        );
        expect((first.state as GameSessionReady).scene, same(initial));
      }

      final second = _coordinator();
      await second.load();
      final secondController = MapPresentationController.fromCoordinator(
        second,
      );
      await tester.pumpWidget(
        AonwApp(mapController: secondController, settingsController: settings),
      );
      await tester.pumpAndSettle();
      expect(second.aiRuntimeProfile, LocalAiRuntimeProfileView.batterySaver);
      final retained = (second.state as GameSessionReady).scene;
      settings = ClientSettingsController(store: _Store(false));
      await tester.pumpWidget(
        AonwApp(mapController: secondController, settingsController: settings),
      );
      await tester.pumpAndSettle();
      expect(second.aiRuntimeProfile, LocalAiRuntimeProfileView.standard);
      await settings.update(
        settings.settings.copyWith(
          ai: const ClientAiSettings(batterySaver: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(second.aiRuntimeProfile, LocalAiRuntimeProfileView.batterySaver);
      expect((second.state as GameSessionReady).scene, same(retained));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

MapCoordinator _coordinator() => MapCoordinator(
  capabilities: testGameSessionCapabilities(
    FakeGameSession.success(testMapScene()),
  ),
);

final class _Store implements ClientSettingsStore {
  _Store(bool enabled)
    : value = ClientSettings.defaults.copyWith(
        ai: ClientAiSettings(batterySaver: enabled),
      );
  ClientSettings value;

  @override
  Future<ClientSettings> load() async => value;

  @override
  Future<void> save(ClientSettings settings) async => value = settings;
}
