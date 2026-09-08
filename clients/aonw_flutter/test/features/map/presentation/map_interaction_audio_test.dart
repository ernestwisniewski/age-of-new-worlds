import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/delayed_movement_session.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'selection sounds only the selected hex and a completed route query',
    () async {
      final session = _session();
      final controller = _controller(session);
      final sounds = <GameSoundCue>[];
      controller.bindInteractionSounds(sounds.add);
      await controller.load();
      controller.hover((col: 2, row: 0));
      expect(sounds, isEmpty);
      controller.select((col: 2, row: 0));
      expect(sounds, [GameSoundCue.mapTileSelect]);
      controller.select((col: 0, row: 0));
      await pumpEventQueue();
      expect(sounds, hasLength(1));
      controller.select((col: 1, row: 0));
      expect(sounds, hasLength(1));
      await pumpEventQueue();
      expect(sounds, [GameSoundCue.mapTileSelect, GameSoundCue.movePreview]);
      controller.hover((col: 2, row: 1));
      await pumpEventQueue();
      expect(sounds, hasLength(2));
    },
  );

  test(
    'city selection respects ownership and repeated management modes stay quiet',
    () async {
      final session = FakeGameSession.success(
        testMapScene(
          cities: [
            testCityView(),
            testCityView(
              id: 'foreign',
              ownerPlayerId: 'other',
              owned: false,
              center: (col: 2, row: 1),
            ),
          ],
        ),
        cityInspection: testCityInspectionView(),
      );
      final controller = _controller(session);
      final sounds = <GameSoundCue>[];
      controller.bindInteractionSounds(sounds.add);
      await controller.load();
      controller.selectCity('missing');
      controller.selectCity('foreign');
      expect(sounds, isEmpty);
      controller.selectCity('preview-city');
      await pumpEventQueue();
      expect(sounds, [GameSoundCue.city]);
      controller.startCityManagement(CityManagementMode.workedHexes);
      controller.startCityManagement(CityManagementMode.workedHexes);
      controller.cancelCityManagement();
      controller.startCityManagement(CityManagementMode.expansion);
      expect(sounds, [
        GameSoundCue.city,
        GameSoundCue.uiPanelOpen,
        GameSoundCue.uiPanelOpen,
      ]);
    },
  );

  for (final success in [true, false]) {
    test(
      'founding sounds only a successful response (success: $success)',
      () async {
        final controller = _controller(_session(founding: success));
        final sounds = <GameSoundCue>[];
        controller.bindInteractionSounds(sounds.add);
        await controller.load();
        controller.openCityFounding();
        expect(sounds, isEmpty);
        controller.selectUnit('preview-commander');
        await pumpEventQueue();
        controller.openCityFounding();
        expect(sounds, isEmpty);
        await pumpEventQueue();
        expect(sounds, success ? [GameSoundCue.uiPanelOpen] : isEmpty);
        controller.cancelCityFounding();
        sounds.clear();
        controller.openCityFounding();
        controller.cancelCityFounding();
        await pumpEventQueue();
        expect(sounds, isEmpty);
      },
    );
  }

  test(
    'a blocked selection preserves the pending route and its single sound',
    () async {
      final movement = DelayedMovementSession();
      final controller = _controller(_session(), movement: movement);
      final sounds = <GameSoundCue>[];
      controller.bindInteractionSounds(sounds.add);
      await _requestRoute(controller);
      controller.select((col: 2, row: 0));
      expect(sounds, isEmpty);
      movement.requests.single.complete(testRoutePlanView());
      await pumpEventQueue();
      expect(sounds, [GameSoundCue.movePreview]);
      expect((controller.state as GameSessionReady).interaction.selected, (
        col: 1,
        row: 0,
      ));
    },
  );

  for (final interruption in [
    'suspend',
    'reload',
    'unbind',
    'dispose',
    'failure',
  ]) {
    test('drops pending route audio after $interruption', () async {
      final movement = DelayedMovementSession();
      final controller = _controller(_session(), movement: movement);
      final sounds = <GameSoundCue>[];
      controller.bindInteractionSounds(sounds.add);
      await _requestRoute(controller);
      switch (interruption) {
        case 'suspend':
          controller.silencePendingInteractionSounds();
        case 'reload':
          await controller.load();
        case 'unbind':
          controller.bindInteractionSounds(null);
        case 'dispose':
          controller.dispose();
        case 'failure':
          movement.requests.single.completeError(
            const MovementSessionException(
              code: 'unavailable',
              message: 'No route.',
            ),
          );
      }
      if (interruption != 'failure') {
        movement.requests.single.complete(testRoutePlanView());
      }
      await pumpEventQueue();
      expect(sounds, isEmpty);
    });
  }
}

FakeGameSession _session({bool founding = true}) => FakeGameSession.success(
  testMapScene(units: [testVisibleUnit()]),
  reachableResult: testReachableView(),
  routeResult: testRoutePlanView(),
  cityFoundingOptionsResult: founding ? testCityFoundingOptionsView() : null,
);

MapPresentationController _controller(
  FakeGameSession session, {
  MovementSessionPort? movement,
}) {
  final controller = MapPresentationController(
    capabilities: testGameSessionCapabilities(session, movement: movement),
    diagnosticReporter: (_, _, _) {},
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _requestRoute(MapPresentationController controller) async {
  await controller.load();
  controller.select((col: 0, row: 0));
  await pumpEventQueue();
  controller.select((col: 1, row: 0));
}
