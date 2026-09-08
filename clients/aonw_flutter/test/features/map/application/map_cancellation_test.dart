import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/delayed_movement_session.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  for (final loading in [true, false]) {
    test(
      'cancels founding while preserving the founder (loading: $loading)',
      () async {
        final session = _session();
        final controller = _controller(session);
        final sounds = <GameSoundCue>[];
        controller.bindInteractionSounds(sounds.add);
        await _selectUnit(controller);
        final recipient = _ready(controller).recipient;
        controller.openCityFounding();
        if (!loading) await pumpEventQueue();
        sounds.clear();
        controller.cancelInteraction();
        await pumpEventQueue();
        expect(_ready(controller).interaction.city, isNull);
        expect(
          _ready(controller).interaction.selectedUnitId,
          'preview-commander',
        );
        expect(_ready(controller).recipient, same(recipient));
        expect(session.cityCommandCalls, 0);
        expect(sounds, isEmpty);
      },
    );
  }

  for (final mode in CityManagementMode.values) {
    test('cancels $mode while preserving city inspection', () async {
      final session = _session();
      final controller = _controller(session);
      await controller.load();
      controller.selectCity('preview-city');
      await pumpEventQueue();
      controller.startCityManagement(mode);
      final inspection = _ready(controller).interaction.city?.inspection;
      controller.cancelInteraction();
      expect(_ready(controller).interaction.city?.managementMode, isNull);
      expect(_ready(controller).interaction.city?.inspection, same(inspection));
      expect(_ready(controller).interaction.city?.cityId, 'preview-city');
      expect(session.cityCommandCalls, 0);
    });
  }

  test(
    'a city command cannot be cancelled before its result arrives',
    () async {
      final session = _session();
      final controller = _controller(session);
      await controller.load();
      controller.selectCity('preview-city');
      await pumpEventQueue();
      controller.startCityManagement(CityManagementMode.workedHexes);
      controller.executeCityAction(
        const ToggleWorkedHexActionView(
          cityId: 'preview-city',
          target: (col: 1, row: 0),
        ),
      );
      final pending = controller.state;
      expect(_ready(controller).interaction.city?.commandPending, isTrue);
      controller.cancelInteraction();
      expect(controller.state, same(pending));
      await pumpEventQueue();
      expect(session.cityCommandCalls, 1);
      controller.cancelInteraction();
      expect(_ready(controller).interaction.city?.managementMode, isNull);
    },
  );

  test(
    'cancels a route query and discards its late result without sound',
    () async {
      final movement = DelayedMovementSession();
      final controller = _controller(_session(), movement: movement);
      final sounds = <GameSoundCue>[];
      controller.bindInteractionSounds(sounds.add);
      await _selectUnit(controller);
      controller.select((col: 1, row: 0));
      expect(_ready(controller).interaction.movementPending, isTrue);
      controller.cancelInteraction();
      expect(_ready(controller).interaction.selected, (col: 0, row: 0));
      expect(_ready(controller).interaction.movementPending, isFalse);
      movement.requests.single.complete(testRoutePlanView());
      await pumpEventQueue();
      expect(_ready(controller).interaction.route, isNull);
      expect(
        _ready(controller).interaction.selectedUnitId,
        'preview-commander',
      );
      expect(sounds, isEmpty);
    },
  );

  test('cancels a ready route before clearing the selected unit', () async {
    final controller = _controller(_session());
    await _selectUnit(controller);
    controller.select((col: 1, row: 0));
    await pumpEventQueue();
    expect(_ready(controller).interaction.route, isNotNull);
    controller.cancelInteraction();
    expect(_ready(controller).interaction.route, isNull);
    expect(_ready(controller).interaction.selected, (col: 0, row: 0));
    expect(_ready(controller).interaction.selectedUnitId, 'preview-commander');
    controller.cancelInteraction();
    expect(_ready(controller).interaction.selectedUnitId, isNull);
  });

  test('cannot cancel or reopen a submitted founding command', () async {
    final session = _session();
    final controller = _controller(session);
    await _selectUnit(controller);
    controller.openCityFounding();
    await pumpEventQueue();
    controller.toggleCityFoundingHex((col: 1, row: 0));
    controller.confirmCityFounding();
    final pending = controller.state;
    expect(_ready(controller).interaction.city?.commandPending, isTrue);
    controller.cancelInteraction();
    controller.openCityFounding();
    expect(controller.state, same(pending));
    await pumpEventQueue();
    expect(session.cityCommandCalls, 1);
    controller.cancelInteraction();
    expect(_ready(controller).interaction.city, isNull);
  });

  test('cannot cancel a submitted movement command', () async {
    final session = _session();
    final controller = _controller(session);
    await _selectUnit(controller);
    controller.select((col: 1, row: 0));
    await pumpEventQueue();
    controller.confirmMove();
    final pending = controller.state;
    expect(_ready(controller).interaction.movementPending, isTrue);
    controller.cancelInteraction();
    expect(controller.state, same(pending));
    await pumpEventQueue();
  });

  for (final loading in [true, false]) {
    test(
      'cancels combat preview and preserves the attacker (loading: $loading)',
      () async {
        final session = FakeGameSession.success(
          testMapScene(
            units: [
              testVisibleUnit(),
              testVisibleUnit(
                id: 'defender',
                ownerPlayerId: 'foreign',
                coordinate: (col: 1, row: 0),
              ),
            ],
          ),
          reachableResult: testReachableView(),
          combatPreviewResult: testCombatPreviewView(),
        );
        final controller = _controller(session);
        await _selectUnit(controller);
        controller.select((col: 1, row: 0));
        if (!loading) await pumpEventQueue();
        expect(_ready(controller).interaction.combat, isNotNull);
        controller.cancelInteraction();
        await pumpEventQueue();
        expect(_ready(controller).interaction.combat, isNull);
        expect(_ready(controller).interaction.reachable, isNotNull);
        expect(
          _ready(controller).interaction.unitLogistics?.options,
          isNotNull,
        );
        expect(
          _ready(controller).interaction.selectedUnitId,
          'preview-commander',
        );
        expect(_ready(controller).interaction.selected, (col: 0, row: 0));
      },
    );
  }
}

FakeGameSession _session() => FakeGameSession.success(
  testMapScene(units: [testVisibleUnit()], cities: [testCityView()]),
  reachableResult: testReachableView(),
  routeResult: testRoutePlanView(),
  moveFailure: const MovementSessionException(
    code: 'movement_rejected',
    message: 'Rejected fixture',
  ),
  cityFoundingOptionsResult: testCityFoundingOptionsView(),
  cityInspection: testCityInspectionView(),
  cityResult: const CityCommandResultView.rejected(
    rejectionCode: CityRejectionCodeView.cityNotControlled,
  ),
);

MapPresentationController _controller(
  FakeGameSession session, {
  MovementSessionPort? movement,
}) {
  final controller = MapPresentationController(
    capabilities: testGameSessionCapabilities(session, movement: movement),
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _selectUnit(MapPresentationController controller) async {
  await controller.load();
  controller.selectUnit('preview-commander');
  await pumpEventQueue();
}

GameSessionReady _ready(MapPresentationController controller) =>
    controller.state as GameSessionReady;
