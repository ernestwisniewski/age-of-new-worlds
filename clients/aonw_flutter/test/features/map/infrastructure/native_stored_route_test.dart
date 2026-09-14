import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'retains the complete native queued route across save and resume',
    () async {
      final gateway = EngineGameSessionGateway(assets: _FileAssets());
      addTearDown(gateway.close);
      final scene = await gateway.load(MapAssetPaths.starter);
      final unit = scene.player.units.single;
      final skipped = await gateway.executeUnitAction(
        expectedRevision: 0,
        unitId: unit.id,
        action: UnitActionKindView.skip,
      );
      expect(skipped.accepted, isTrue);
      final route = await gateway.routePlan(
        expectedRevision: 1,
        unitId: unit.id,
        target: (col: 5, row: 4),
      );
      expect(route.estimatedTurns, greaterThan(1));
      expect(route.stepTurns, hasLength(route.steps.length));
      expect(route.stepTurns.first, 1);
      expect(route.stepTurns[1], 2);
      expect(route.stepTurns.last, route.estimatedTurns);
      final moved = await gateway.moveUnit(
        expectedRevision: 1,
        unitId: unit.id,
        target: route.target,
      );
      expect(moved.accepted, isTrue);
      final current = moved.player!.units.single;
      final queued = current.queuedRoute!;
      expect(queued.steps.length, greaterThan(1));
      expect(queued.steps.first.coordinate, current.coordinate);
      expect(queued.steps.last.coordinate, route.target);
      final save = await gateway.saveSession.exportSaveDocument();
      final other = EngineGameSessionGateway(assets: _FileAssets());
      addTearDown(other.close);
      final restored = await other.saveSession.openSaveDocument(
        assets: MapAssetPaths.starter,
        document: save,
      );
      final restoredRoute = restored.player.units.single.queuedRoute!;
      expect(
        restoredRoute.steps.map(
          (s) => (s.coordinate, s.enterCostUnits, s.cumulativeCostUnits),
        ),
        queued.steps.map(
          (s) => (s.coordinate, s.enterCostUnits, s.cumulativeCostUnits),
        ),
      );
      expect(
        restored.player.stamp.stateDigest,
        moved.player!.stamp.stateDigest,
      );
      expect(await other.saveSession.exportSaveDocument(), save);
    },
  );
}

final class _FileAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}
