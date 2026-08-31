import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps strict wire DTOs into feature-local immutable values', () {
    final wire = AonwClientResponse.parse(
      File(
        '../../tests/fixtures/client_protocol/map_inspected_response.json',
      ).readAsStringSync(),
    ).require<AonwMapInspectedResponse>().map;

    final map = const MapViewMapper().fromWire(wire);

    expect(map.mapId, 'map-1');
    expect(map.gridLayout, MapGridLayout.oddQFlatTop);
    expect(map.tileAt((col: 0, row: 0))?.displayTerrain, MapTerrain.forest);
    expect(map.tiles.single.terrainTags, [
      MapTerrain.forest,
      MapTerrain.grassland,
    ]);
    expect(map.objectives.single.id, 'ruins-1');
    expect(map.objectives.single.type, MapObjectiveType.ruins);
    expect(map.tiles.single.resources, [MapResource.deer]);
    expect(() => map.tiles.add(map.tiles.single), throwsUnsupportedError);
  });
}
