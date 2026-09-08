import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_cursor.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/map_test_fixture.dart';

void main() {
  test('starts at the viewport center and retains its own position', () {
    final cursor = MapGamepadCursor();
    final ready = _ready();
    expect(cursor.current(ready, viewportCenter: (col: 4, row: 2)), (
      col: 4,
      row: 2,
    ));
    expect(cursor.move(ready, MapInputCommand.cursorLeft), (col: 3, row: 2));
    expect(cursor.current(ready, viewportCenter: (col: 0, row: 0)), (
      col: 3,
      row: 2,
    ));
    expect(cursor.move(ready, MapInputCommand.cursorDown), isNull);
    expect(cursor.current(ready), (col: 3, row: 2));
  });

  test('uses the first authored hex when the viewport misses the map', () {
    final cursor = MapGamepadCursor();
    expect(cursor.current(_ready(), viewportCenter: (col: -1, row: -1)), (
      col: 0,
      row: 0,
    ));
  });

  test(
    'unit identity and position resynchronize without following its route',
    () {
      final cursor = MapGamepadCursor();
      final ready = _ready().withInteraction(
        const MapInteractionState(
          selectedUnitId: 'preview-commander',
          selected: (col: 0, row: 0),
          moveTargeting: true,
        ),
      );
      expect(cursor.current(ready), (col: 0, row: 0));
      expect(cursor.move(ready, MapInputCommand.cursorRight), (col: 1, row: 0));
      final route = ready.withInteraction(
        ready.interaction.copyWith(
          selected: (col: 4, row: 2),
          route: testRoutePlanView(),
        ),
      );
      expect(cursor.current(route), (col: 1, row: 0));
      final other = ready.withInteraction(
        ready.interaction.copyWith(
          selectedUnitId: 'other',
          selected: (col: 3, row: 1),
        ),
      );
      expect(cursor.current(other), (col: 3, row: 1));
      final moved = other.withRecipient(
        PlayerMapView.preview(
          actorPlayerId: other.recipient.actorPlayerId,
          stamp: testSessionStamp(revision: 1),
          turn: 1,
          pendingAction: null,
          units: [testVisibleUnit(id: 'other', coordinate: (col: 2, row: 1))],
        ),
      );
      expect(cursor.current(moved), (col: 2, row: 1));
    },
  );

  test('city selection uses its center and terrain selection uses its hex', () {
    final cursor = MapGamepadCursor();
    final ready = _ready().withInteraction(
      const MapInteractionState(
        selected: (col: 4, row: 2),
        city: CityState(cityId: 'preview-city'),
      ),
    );
    expect(cursor.current(ready), testCityView().center);
    final tile = ready.withInteraction(
      const MapInteractionState(selected: (col: 4, row: 1)),
    );
    expect(cursor.current(tile), (col: 4, row: 1));
    final clear = tile.withInteraction(const MapInteractionState());
    expect(cursor.current(clear), (col: 4, row: 1));
  });

  test('map, actor and revision rollback discard the previous cursor', () {
    final cursor = MapGamepadCursor();
    final ready = _ready();
    cursor.current(ready, viewportCenter: (col: 4, row: 2));
    final otherMap = GameSessionReady.initial(testMapScene(mapId: 'other-map'));
    expect(cursor.current(otherMap, viewportCenter: (col: 1, row: 1)), (
      col: 1,
      row: 1,
    ));
    final otherActor = otherMap.withRecipient(
      PlayerMapView.preview(
        actorPlayerId: 'another-player',
        stamp: testSessionStamp(revision: 5),
        turn: 1,
        pendingAction: null,
        units: const [],
      ),
    );
    expect(cursor.current(otherActor, viewportCenter: (col: 2, row: 0)), (
      col: 2,
      row: 0,
    ));
    final rollback = otherActor.withRecipient(
      PlayerMapView.preview(
        actorPlayerId: 'another-player',
        stamp: testSessionStamp(revision: 2),
        turn: 1,
        pendingAction: null,
        units: const [],
      ),
    );
    expect(cursor.current(rollback, viewportCenter: (col: 1, row: 0)), (
      col: 1,
      row: 0,
    ));
    cursor.observe(const GameSessionLoading());
    expect(cursor.current(rollback, viewportCenter: (col: 0, row: 0)), (
      col: 0,
      row: 0,
    ));
  });
}

GameSessionReady _ready() => GameSessionReady.initial(
  testMapScene(
    cols: 5,
    rows: 3,
    units: [
      testVisibleUnit(),
      testVisibleUnit(id: 'other', coordinate: (col: 3, row: 1)),
    ],
    cities: [testCityView()],
  ),
);
