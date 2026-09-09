import 'dart:async';

import 'package:aonw_flutter/features/map/application/city_planning_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/city_planning_presentation.dart';
import 'package:aonw_flutter/features/map/read_model/city_planning_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'disabled markings are lazy and identical states reuse one query',
    () async {
      final session = _Session();
      final player = testMapScene().player;
      CityPlanningView? shown;
      final controller = CityPlanningPresentation(
        onChanged: (value) => shown = value,
      );
      addTearDown(controller.dispose);
      void sync(bool enabled) => controller.synchronize(
        session: session,
        player: player,
        enabled: enabled,
        epoch: 0,
      );
      sync(false);
      expect(session.requests, isEmpty);
      sync(true);
      sync(true);
      expect(session.requests, hasLength(1));
      final view = _view(player);
      session.requests.single.complete(view);
      await pumpEventQueue();
      expect(shown, same(view));
      for (var i = 0; i < 120; i++) {
        sync(true);
      }
      expect(session.requests, hasLength(1));
      sync(false);
      expect(shown, isNull);
      sync(true);
      expect(session.requests, hasLength(2));
    },
  );

  test('recipient and epoch changes discard delayed responses', () async {
    final session = _Session();
    final player = testMapScene().player;
    final next = PlayerMapView.preview(
      turn: 1,
      pendingAction: null,
      units: const [],
      actorPlayerId: 'next',
      stamp: player.stamp,
    );
    CityPlanningView? shown;
    final controller = CityPlanningPresentation(
      onChanged: (value) => shown = value,
    );
    addTearDown(controller.dispose);
    void sync(PlayerMapView value, int epoch) => controller.synchronize(
      session: session,
      player: value,
      enabled: true,
      epoch: epoch,
    );
    sync(player, 0);
    sync(next, 0);
    session.requests[0].complete(_view(player));
    await pumpEventQueue();
    expect(shown, isNull);
    session.requests[1].complete(_view(next));
    await pumpEventQueue();
    expect(shown!.actorPlayerId, 'next');
    sync(next, 1);
    expect(shown, isNull);
    expect(session.requests, hasLength(3));
    controller.dispose();
    session.requests[2].complete(_view(next));
    await pumpEventQueue();
    expect(shown, isNull);
  });

  test(
    'mismatched results stay absent without polling or retry loops',
    () async {
      final session = _Session();
      final player = testMapScene().player;
      CityPlanningView? shown;
      final controller = CityPlanningPresentation(
        onChanged: (value) => shown = value,
      );
      addTearDown(controller.dispose);
      void sync() => controller.synchronize(
        session: session,
        player: player,
        enabled: true,
        epoch: 0,
      );
      sync();
      session.requests.single.complete(
        _view(
          PlayerMapView.preview(
            turn: 1,
            pendingAction: null,
            units: const [],
            actorPlayerId: 'other',
            stamp: player.stamp,
          ),
        ),
      );
      await pumpEventQueue();
      sync();
      expect(shown, isNull);
      expect(session.requests, hasLength(1));
    },
  );
}

CityPlanningView _view(PlayerMapView player) => CityPlanningView(
  stamp: player.stamp,
  actorPlayerId: player.actorPlayerId,
  citySites: const [(col: 0, row: 0)],
  growthTiles: const [(col: 0, row: 0)],
);

final class _Session implements CityPlanningSessionPort {
  final requests = <Completer<CityPlanningView>>[];
  @override
  Future<CityPlanningView> cityPlanning({required int expectedRevision}) {
    final request = Completer<CityPlanningView>();
    requests.add(request);
    return request.future;
  }
}
