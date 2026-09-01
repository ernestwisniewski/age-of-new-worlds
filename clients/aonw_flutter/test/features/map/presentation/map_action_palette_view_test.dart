import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_action_palette_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_state.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_en.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_pl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('builds localized move confirmation from engine turn estimate', () {
    final route = testRoutePlanView();
    final scene = testMapScene();

    final view = buildMapActionPaletteView(
      interaction: MapInteractionState(route: route),
      player: scene.player,
      l10n: AonwLocalizationsPl(),
    );

    expect(view, isA<MapMovePreviewPillView>());
    final move = view! as MapMovePreviewPillView;
    expect(move.label, 'Potwierdź · 1 tura');
    expect(move.coordinate, route.destination);
    expect(move.warning, isFalse);
  });

  test('worker palette takes priority and exposes only queried options', () {
    const unitId = 'worker-1';
    const coordinate = (col: 1, row: 1);
    final scene = testMapScene(
      pendingAction: const PendingWorkerActionSelectionView(
        unitId: unitId,
        improvement: FieldImprovementKind.mine,
      ),
    );
    final options = WorkerOptionsView(
      stamp: testSessionStamp(),
      unitId: unitId,
      coordinate: coordinate,
      improvements: const [
        WorkerImprovementOptionView(
          improvement: FieldImprovementKind.farm,
          buildTurns: 2,
        ),
        WorkerImprovementOptionView(
          improvement: FieldImprovementKind.mine,
          buildTurns: 3,
        ),
      ],
      canAssign: true,
      canBuildRoad: true,
      automation: null,
    );

    final view = buildMapActionPaletteView(
      interaction: MapInteractionState(
        route: testRoutePlanView(),
        worker: WorkerState(unitId: unitId, options: options),
      ),
      player: scene.player,
      l10n: AonwLocalizationsEn(),
    );

    expect(view, isA<MapWorkerActionPaletteView>());
    final worker = view! as MapWorkerActionPaletteView;
    expect(worker.coordinate, coordinate);
    expect(worker.options.map((option) => option.improvement), [
      FieldImprovementKind.farm,
      FieldImprovementKind.mine,
    ]);
    expect(worker.options.map((option) => option.turnLabel), [
      '2 turns',
      '3 turns',
    ]);
    expect(worker.previewedImprovement, FieldImprovementKind.mine);
    expect(worker.confirmLabel, 'Confirm improvement · Mine');
  });

  test('suppresses movement actions while a founding draft owns the map', () {
    final scene = testMapScene();
    final options = testCityFoundingOptionsView();

    final view = buildMapActionPaletteView(
      interaction: MapInteractionState(
        route: testRoutePlanView(),
        city: CityState(
          founderUnitId: options.founderUnitId,
          foundingOptions: options,
        ),
      ),
      player: scene.player,
      l10n: AonwLocalizationsEn(),
    );

    expect(view, isNull);
  });
}
