import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';
import '../../../support/counting_map_session.dart';

void main() {
  test(
    'superseded and disposed preference reads never open a session',
    () async {
      final session = FakeGameSession.success(testMapScene());
      final counted = CountingMapSession(session);
      final coordinator = MapCoordinator(
        capabilities: testGameSessionCapabilities(session, map: counted),
      );
      final pending = Completer<MapViewMode>();
      coordinator.readInitialMapViewMode = () => pending.future;
      final first = coordinator.load();
      expect(coordinator.state, isA<GameSessionLoading>());
      expect(counted.loadCalls, 0);
      coordinator.readInitialMapViewMode = () async => MapViewMode.tile;
      await coordinator.load();
      expect(counted.loadCalls, 1);
      pending.complete(MapViewMode.graphic);
      await first;
      expect(
        (coordinator.state as GameSessionReady).interaction.viewMode,
        MapViewMode.tile,
      );
      expect(counted.loadCalls, 1);
      final disposed = Completer<MapViewMode>();
      coordinator.readInitialMapViewMode = () => disposed.future;
      final last = coordinator.load();
      coordinator.dispose();
      disposed.complete(MapViewMode.graphic);
      await last;
      expect(counted.loadCalls, 1);
    },
  );

  test(
    'failed preference read reports a diagnostic and opens with the default',
    () async {
      final session = FakeGameSession.success(testMapScene());
      final counted = CountingMapSession(session);
      final diagnostics = <String>[];
      final coordinator = MapCoordinator(
        capabilities: testGameSessionCapabilities(session, map: counted),
        diagnosticReporter: (code, _, _) => diagnostics.add(code),
      );
      addTearDown(coordinator.dispose);
      coordinator.readInitialMapViewMode = () async =>
          throw StateError('storage unavailable');
      await coordinator.load();
      expect(counted.loadCalls, 1);
      expect(
        (coordinator.state as GameSessionReady).interaction.viewMode,
        MapViewMode.graphic,
      );
      expect(diagnostics, ['map_view_preference_failed']);
    },
  );
}
