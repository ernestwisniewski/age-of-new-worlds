import 'dart:typed_data';

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('falls back from graphic to tile mode without a reference page', () {
    final scene = testMapScene();

    expect(_snapshot(scene.reference).effectiveViewMode, MapViewMode.tile);
    expect(
      _snapshot(scene.reference, requested: MapViewMode.tile).effectiveViewMode,
      MapViewMode.tile,
    );
  });

  test('keeps graphic mode when an authored reference page exists', () {
    final scene = testMapScene();
    final reference = MapReferenceBundle(
      mapId: scene.map.mapId,
      mapContentHash: scene.map.contentHash,
      worldWidth: scene.reference.worldWidth,
      worldHeight: scene.reference.worldHeight,
      pages: [
        MapReferencePage(
          file: 'page.png',
          bytes: Uint8List(0),
          pixelWidth: 1,
          pixelHeight: 1,
          destination: const (x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    );

    expect(_snapshot(reference).effectiveViewMode, MapViewMode.graphic);
  });
}

MapRenderSnapshot _snapshot(
  MapReferenceBundle reference, {
  MapViewMode requested = MapViewMode.graphic,
}) {
  final scene = testMapScene();
  return MapRenderSnapshot(
    map: scene.map,
    interaction: MapInteractionState(viewMode: requested),
    reference: reference,
    player: scene.player,
  );
}
