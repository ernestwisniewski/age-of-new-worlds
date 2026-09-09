import 'dart:async';

import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/counting_map_session.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets(
    'opening waits for the current settings and active view stays independent',
    (tester) async {
      final session = FakeGameSession.success(testMapScene());
      final counted = CountingMapSession(session);
      final map = MapPresentationController(
        capabilities: testGameSessionCapabilities(session, map: counted),
      );
      final first = _PendingStore();
      var settings = ClientSettingsController(store: first);
      await tester.pumpWidget(
        AonwApp(mapController: map, settingsController: settings),
      );
      final opening = map.load();
      await tester.pump();
      expect(counted.loadCalls, 0);
      final second = _PendingStore();
      settings = ClientSettingsController(store: second);
      await tester.pumpWidget(
        AonwApp(mapController: map, settingsController: settings),
      );
      first.loaded.complete(ClientSettings.defaults);
      await tester.pump();
      expect(counted.loadCalls, 0);
      second.loaded.complete(
        ClientSettings.defaults.copyWith(
          mapDisplay: ClientSettings.defaults.mapDisplay.copyWith(
            preferredMapViewMode: MapViewMode.tile,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await opening;
      expect(counted.loadCalls, 1);
      expect(
        (map.state as GameSessionReady).interaction.viewMode,
        MapViewMode.tile,
      );
      final scene = (map.state as GameSessionReady).scene;
      await settings.reset();
      await tester.pump();
      expect((map.state as GameSessionReady).scene, same(scene));
      expect(
        (map.state as GameSessionReady).interaction.viewMode,
        MapViewMode.tile,
      );
      await map.load();
      expect(
        (map.state as GameSessionReady).interaction.viewMode,
        MapViewMode.graphic,
      );
      map.setMapViewMode(MapViewMode.tile);
      expect(settings.settings.preferredMapViewMode, MapViewMode.graphic);
      await settings.update(settings.settings.copyWith(highContrast: true));
      await tester.pump();
      expect(
        (map.state as GameSessionReady).interaction.viewMode,
        MapViewMode.tile,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

final class _PendingStore implements ClientSettingsStore {
  final loaded = Completer<ClientSettings>();
  @override
  Future<ClientSettings> load() => loaded.future;
  @override
  Future<void> save(ClientSettings settings) async {}
}
