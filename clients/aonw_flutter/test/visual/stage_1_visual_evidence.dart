import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized_test_app.dart';

const _evidenceDirectory = String.fromEnvironment('AONW_STAGE_1_EVIDENCE_DIR');
const _captureKey = ValueKey('stage-1-flutter-capture');

void main() {
  testWidgets(
    'captures the Flutter terrain grid',
    (tester) => _captureEvidence(
      tester,
      interaction: const MapInteractionState(referenceVisible: false),
      fileName: 'flutter-terrain-grid.png',
    ),
  );
  testWidgets(
    'captures the Flutter terrain selection',
    (tester) => _captureEvidence(
      tester,
      interaction: const MapInteractionState(
        selected: (col: 3, row: 3),
        referenceVisible: false,
      ),
      fileName: 'flutter-terrain-selection.png',
    ),
  );
}

Future<void> _captureEvidence(
  WidgetTester tester, {
  required MapInteractionState interaction,
  required String fileName,
}) async {
  if (_evidenceDirectory.isEmpty) {
    fail('AONW_STAGE_1_EVIDENCE_DIR is required.');
  }
  final map = await _loadMap(tester);
  expect(map, isNotNull);
  final loadedMap = map!;
  final bounds = AonwOddQFlatTopGeometry(
    cols: loadedMap.cols,
    rows: loadedMap.rows,
    radius: aonwMapHexRadius,
  ).bounds;
  debugPrint('Flutter evidence: MapView loaded for $fileName');
  await tester.binding.setSurfaceSize(const Size(660, 728));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final snapshot = MapRenderSnapshot(
    map: loadedMap,
    interaction: interaction,
    reference: MapReferenceBundle(
      mapId: loadedMap.mapId,
      mapContentHash: loadedMap.contentHash,
      worldWidth: bounds.width,
      worldHeight: bounds.height,
      pages: const [],
    ),
    player: PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: SessionStampView(
        revision: 0,
        stateDigest: 'b' * 64,
        mapHash: loadedMap.contentHash,
        rulesetHash: 'c' * 64,
      ),
      turn: 1,
      pendingAction: null,
      units: const [],
    ),
  );
  final game = AonwFlameGame()..replaceScene(snapshot);

  await tester.pumpWidget(
    LocalizedTestApp(
      home: ColoredBox(
        color: Colors.black,
        child: RepaintBoundary(
          key: _captureKey,
          child: GameWidget<AonwFlameGame>(game: game, autofocus: false),
        ),
      ),
    ),
  );
  await tester.runAsync(game.ready);
  game.stepEngine(stepTime: 0);
  await tester.pump(const Duration(milliseconds: 200));
  debugPrint('Flutter evidence: $fileName rendered');
  await expectLater(
    find.byKey(_captureKey),
    matchesGoldenFile('../../../../docs/acceptance/stage-1/$fileName'),
  );
  debugPrint('Flutter evidence: $fileName complete');
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<MapView?> _loadMap(WidgetTester tester) =>
    tester.runAsync<MapView?>(() async {
      final session = await createAonwRustSession();
      if (session == null) return null;
      try {
        final response = await session.send(
          AonwClientRequest.inspectMap(
            mapDocument: await rootBundle.loadString(
              'assets/maps/aonw2_starter/map.json',
            ),
          ),
        );
        return const MapViewMapper().fromWire(
          response.require<AonwMapInspectedResponse>().map,
        );
      } finally {
        await session.close();
      }
    });
