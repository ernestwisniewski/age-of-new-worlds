import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_activity_view.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('returns the shared starter MapView identity', (tester) async {
    final loadedMap = await tester.runAsync(_loadStarter);
    expect(loadedMap, isNotNull);
    final identity =
        jsonDecode(
              File(
                '../../tests/fixtures/maps/aonw2_starter/'
                'map_view_identity.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final map = loadedMap!;

    expect(map.mapId, identity['mapId']);
    expect(map.contentHash, identity['contentHash']);
    expect(map.cols, identity['cols']);
    expect(map.rows, identity['rows']);
    expect(map.gridLayout.name, identity['gridLayout']);
  });

  test('runs the recipient-safe starter movement session', () async {
    var backendCreations = 0;
    late _TrackingEngineSession backend;
    final gateway = EngineGameSessionGateway(
      assets: _FileAssetBundle(),
      sessionFactory: () async {
        backendCreations += 1;
        final native = await createAonwEngineSession();
        if (native == null) return null;
        backend = _TrackingEngineSession(native);
        return backend;
      },
    );
    addTearDown(gateway.close);

    final scene = await gateway.load(MapAssetPaths.starter);

    expect(scene, isNotNull);
    expect(scene.player.stamp.mapHash, scene.map.contentHash);
    expect(scene.player.stamp.revision, 0);
    expect(scene.player.units, hasLength(1));
    expect(scene.player.units.single.id, 'preview-commander');
    expect(scene.player.units.single.ownerPlayerId, 'preview-player');
    expect(scene.player.units.single.coordinate, (col: 2, row: 1));

    final reachableResponses = await Future.wait([
      gateway.reachable(
        expectedRevision: scene.player.stamp.revision,
        unitId: 'preview-commander',
      ),
      gateway.reachable(
        expectedRevision: scene.player.stamp.revision,
        unitId: 'preview-commander',
      ),
    ]);
    final reachable = reachableResponses.first;
    expect(reachable, isNotNull);
    expect(reachable.tiles, isNotEmpty);
    expect(backend.maximumInFlightRequests, 1);
    final route = await gateway.routePlan(
      expectedRevision: scene.player.stamp.revision,
      unitId: 'preview-commander',
      target: (col: 2, row: 2),
    );
    expect(route, isNotNull);
    expect(route.steps.first.coordinate, (col: 2, row: 1));
    expect(route.steps.last.coordinate, (col: 2, row: 2));
    final moved = await gateway.moveUnit(
      expectedRevision: scene.player.stamp.revision,
      unitId: 'preview-commander',
      target: route.target,
    );
    expect(moved, isNotNull);
    expect(moved.accepted, isTrue);
    expect(moved.player!.stamp.revision, 1);
    expect(moved.player!.units.single.coordinate, (col: 2, row: 2));
    expect(moved.execution!.events.single.unitId, 'preview-commander');
    expect(moved.execution!.evidence!.steps.last.coordinate, (col: 2, row: 2));
    final rejected = await gateway.moveUnit(
      expectedRevision: 0,
      unitId: 'preview-commander',
      target: (col: 2, row: 1),
    );
    expect(rejected, isNotNull);
    expect(rejected.accepted, isFalse);
    expect(rejected.rejectionCode, CommandRejectionCodeView.staleRevision);
    backend.corruptNextAcceptedPatch = true;
    Object? resyncFailure;
    try {
      await gateway.moveUnit(
        expectedRevision: 1,
        unitId: 'preview-commander',
        target: (col: 2, row: 1),
      );
    } on Object catch (error) {
      resyncFailure = error;
    }
    expect(
      resyncFailure,
      isA<MovementSessionException>()
          .having((error) => error.code, 'code', 'recipient_resynchronized')
          .having(
            (error) => error.resyncedPlayer?.stamp.revision,
            'resynced revision',
            2,
          ),
    );
    final recovered = await gateway.reachable(
      expectedRevision: 2,
      unitId: 'preview-commander',
    );
    expect(recovered.stamp.revision, 2);
    expect(backendCreations, 1);
    expect(backend.requestTypes, [
      'capabilities',
      'inspectMap',
      'openSession',
      'snapshot',
      'query',
      'query',
      'query',
      'dispatch',
      'dispatch',
      'dispatch',
      'snapshot',
      'query',
    ]);
    await gateway.close();
    expect(backend.closeCalls, 1);
  });

  test('executes the current unit action family through one session', () async {
    late _TrackingEngineSession backend;
    final gateway = EngineGameSessionGateway(
      assets: _FileAssetBundle(),
      sessionFactory: () async {
        final native = await createAonwEngineSession();
        if (native == null) return null;
        backend = _TrackingEngineSession(native);
        return backend;
      },
    );
    addTearDown(gateway.close);

    final scene = await gateway.load(MapAssetPaths.starter);
    final unitId = scene.player.units.single.id;
    final skipped = await gateway.executeUnitAction(
      expectedRevision: 0,
      unitId: unitId,
      action: UnitActionKindView.skip,
    );
    final cancelled = await gateway.executeUnitAction(
      expectedRevision: 1,
      unitId: unitId,
      action: UnitActionKindView.cancel,
    );
    final fortified = await gateway.executeUnitAction(
      expectedRevision: 2,
      unitId: unitId,
      action: UnitActionKindView.fortify,
    );

    expect(skipped.accepted, isTrue);
    expect(skipped.player?.stamp.revision, 1);
    expect(skipped.player?.units.single.movementUnits, 0);
    expect(cancelled.accepted, isTrue);
    expect(cancelled.player?.stamp.revision, 2);
    expect(cancelled.player!.units.single.movementUnits, greaterThan(0));
    expect(fortified.accepted, isTrue);
    expect(fortified.player?.stamp.revision, 3);
    expect(
      fortified.player?.units.single.posture,
      VisibleUnitPosture.fortified,
    );
    expect(backend.maximumInFlightRequests, 1);
    expect(backend.requestTypes, [
      'capabilities',
      'inspectMap',
      'openSession',
      'snapshot',
      'dispatch',
      'dispatch',
      'dispatch',
    ]);
    await gateway.close();
    expect(backend.closeCalls, 1);
  });

  test('invalidates an in-flight request before closing its session', () async {
    late _TrackingEngineSession backend;
    final gateway = EngineGameSessionGateway(
      assets: _FileAssetBundle(),
      sessionFactory: () async {
        final native = await createAonwEngineSession();
        if (native == null) return null;
        backend = _TrackingEngineSession(native);
        return backend;
      },
    );
    addTearDown(gateway.close);

    final scene = await gateway.load(MapAssetPaths.starter);
    backend.blockNextDispatch();
    final movement = gateway.moveUnit(
      expectedRevision: scene.player.stamp.revision,
      unitId: 'preview-commander',
      target: (col: 2, row: 2),
    );
    await backend.blockedDispatch;

    final closing = gateway.close();
    backend.releaseBlockedDispatch();

    await expectLater(
      movement,
      throwsA(
        isA<MovementSessionException>().having(
          (error) => error.code,
          'code',
          'session_superseded',
        ),
      ),
    );
    await closing;
    await expectLater(
      gateway.reachable(expectedRevision: 1, unitId: 'preview-commander'),
      throwsA(
        isA<MovementSessionException>().having(
          (error) => error.code,
          'code',
          'session_not_open',
        ),
      ),
    );
    expect(backend.closeCalls, 1);
  });

  test(
    'advances multiple complete local turns through engine patches',
    () async {
      late _TrackingEngineSession backend;
      final gateway = EngineGameSessionGateway(
        assets: _FileAssetBundle(),
        sessionFactory: () async {
          final native = await createAonwEngineSession();
          if (native == null) return null;
          backend = _TrackingEngineSession(native);
          return backend;
        },
      );
      addTearDown(gateway.close);

      var player = (await gateway.load(MapAssetPaths.starter)).player;
      final identities = <TurnActivityIdentityView>{};
      for (var step = 0; step < 3; step++) {
        final result = await gateway.endTurn(
          expectedRevision: player.stamp.revision,
        );
        expect(result.accepted, isTrue);
        expect(result.evidence, isNotNull);
        expect(result.activities, isNotEmpty);
        expect(
          result.activities.every((item) => identities.add(item.identity)),
          isTrue,
        );
        player = result.player!;
        expect(player.stamp.revision, step + 1);
        expect(player.turn, step + 2);
      }
      expect(identities, isNotEmpty);
      expect(backend.maximumInFlightRequests, 1);
    },
  );

  testWidgets('renders the engine-backed 40 by 30 Dravonia map', (
    tester,
  ) async {
    final loadedMap = await tester.runAsync(_loadDravonia);
    expect(loadedMap, isNotNull);
    final map = loadedMap!;
    final bounds = AonwOddQFlatTopGeometry(
      cols: map.cols,
      rows: map.rows,
      radius: aonwMapHexRadius,
    ).bounds;
    final snapshot = MapRenderSnapshot(
      map: map,
      interaction: const MapInteractionState(referenceVisible: false),
      reference: MapReferenceBundle(
        mapId: map.mapId,
        mapContentHash: map.contentHash,
        worldWidth: bounds.width,
        worldHeight: bounds.height,
        pages: const [],
      ),
      player: _emptyPlayer(map.contentHash),
    );
    final flameGame = AonwFlameGame();
    addTearDown(flameGame.onDispose);
    flameGame.sceneSink.replaceScene(snapshot);

    await tester.pumpWidget(
      LocalizedTestApp(
        home: RepaintBoundary(
          key: const ValueKey('dravonia-flame-viewport'),
          child: GameWidget<AonwFlameGame>(game: flameGame, autofocus: false),
        ),
      ),
    );
    await tester.runAsync(flameGame.ready);
    await tester.pump();

    expect(map.mapId, 'dravonia');
    expect(map.cols, 40);
    expect(map.rows, 30);
    expect(map.tiles, hasLength(1200));
    expect(flameGame.world.terrainLayer.debugIdentity?.mapId, 'dravonia');
    expect(flameGame.world.terrainLayer.debugIdentity?.cols, 40);
    expect(flameGame.world.terrainLayer.debugIdentity?.rows, 30);
    expect(flameGame.world.terrainLayer.debugCacheUpdateCount, 1);
    expect(flameGame.world.referenceLayer.debugCacheUpdateCount, 1);
    expect(flameGame.world.gridLayer.debugCacheUpdateCount, 1);
    expect(
      find.byKey(const ValueKey('dravonia-flame-viewport')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<MapView?> _loadStarter() =>
    _loadMap('../../content/maps/aonw2_starter/map.json');

Future<MapView?> _loadDravonia() async {
  return _loadMap('../../content/maps/dravonia/map.json');
}

Future<MapView?> _loadMap(String path) async {
  final session = await createAonwEngineSession();
  if (session == null) return null;
  try {
    final document = File(path).readAsStringSync();
    final response = await session.send(
      AonwClientRequest.inspectMap(mapDocument: document),
    );
    return const MapViewMapper().fromWire(
      response.require<AonwMapInspectedResponse>().map,
    );
  } finally {
    await session.close();
  }
}

PlayerMapView _emptyPlayer(String mapHash) => PlayerMapView.preview(
  actorPlayerId: 'preview-player',
  stamp: SessionStampView(
    revision: 0,
    stateDigest: 'b' * 64,
    mapHash: mapHash,
    rulesetHash: 'c' * 64,
  ),
  turn: 1,
  pendingAction: null,
  units: const [],
);

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

final class _TrackingEngineSession implements AonwEngineSession {
  _TrackingEngineSession(this._delegate);

  final AonwEngineSession _delegate;
  final requestTypes = <String>[];
  var closeCalls = 0;
  var _inFlightRequests = 0;
  var maximumInFlightRequests = 0;
  var corruptNextAcceptedPatch = false;
  Completer<void>? _blockedDispatch;
  Completer<void>? _releaseDispatch;

  Future<void> get blockedDispatch => _blockedDispatch!.future;

  void blockNextDispatch() {
    _blockedDispatch = Completer<void>();
    _releaseDispatch = Completer<void>();
  }

  void releaseBlockedDispatch() => _releaseDispatch!.complete();

  @override
  Future<String> requestJson(String request) async {
    final envelope = jsonDecode(request) as Map<String, dynamic>;
    final body = envelope['request'] as Map<String, dynamic>;
    requestTypes.add(body['type'] as String);
    _inFlightRequests += 1;
    if (_inFlightRequests > maximumInFlightRequests) {
      maximumInFlightRequests = _inFlightRequests;
    }
    try {
      final response = await _delegate.requestJson(request);
      final ready = _blockedDispatch;
      if (body['type'] == 'dispatch' && ready != null) {
        ready.complete();
        await _releaseDispatch!.future;
        _blockedDispatch = null;
        _releaseDispatch = null;
      }
      if (!corruptNextAcceptedPatch || body['type'] != 'dispatch') {
        return response;
      }
      final envelope = jsonDecode(response) as Map<String, dynamic>;
      final outcome = envelope['outcome'] as Map<String, dynamic>;
      final responseBody = outcome['response'] as Map<String, dynamic>;
      final result = responseBody['result'] as Map<String, dynamic>;
      final commandOutcome = result['outcome'] as Map<String, dynamic>;
      if (commandOutcome['status'] != 'accepted') return response;
      corruptNextAcceptedPatch = false;
      final patch = result['viewPatch'] as Map<String, dynamic>;
      patch['fromRevision'] = 99;
      return jsonEncode(envelope);
    } finally {
      _inFlightRequests -= 1;
    }
  }

  @override
  Future<void> close() async {
    closeCalls += 1;
    await _delegate.close();
  }
}
