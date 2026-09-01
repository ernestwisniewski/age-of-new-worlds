import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/presentation/map_hex_selection_palette_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_pl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('resolves recipient-safe targets in legacy order', () {
    const coordinate = (col: 1, row: 0);
    final unit = testVisibleUnit(id: 'unit-1', coordinate: coordinate);
    final scene = testMapScene(
      objectives: const [
        MapObjectiveView(
          id: 'objective-1',
          type: MapObjectiveType.ruins,
          coordinate: coordinate,
          requiredHoldTurns: 2,
          victoryPoints: 3,
          goldPerTurn: 1,
        ),
      ],
      units: [unit],
      cities: [
        CityView(
          id: 'city-1',
          ownerPlayerId: 'preview-player',
          name: 'Warszawa',
          center: coordinate,
          visibleControlledHexes: [],
          hitPoints: 10,
          ownedDetails: null,
        ),
      ],
      fieldImprovements: const [
        FieldImprovementView(
          coordinate: coordinate,
          improvement: FieldImprovementKind.mine,
        ),
      ],
      artifacts: const [
        WorldArtifactView(
          id: 'carried',
          kind: WorldArtifactKindView.heroSword,
          location: CarriedArtifactLocationView('unit-1'),
        ),
        WorldArtifactView(
          id: 'map-artifact',
          kind: WorldArtifactKindView.prophetMask,
          location: MapArtifactLocationView(coordinate),
        ),
      ],
    );

    final view = buildMapHexSelectionPaletteView(
      coordinate: coordinate,
      map: scene.map,
      player: scene.player,
      l10n: AonwLocalizationsPl(),
    )!;

    expect(view.targets, [
      isA<TerrainHexSelectionTargetView>(),
      isA<UnitHexSelectionTargetView>(),
      isA<CityHexSelectionTargetView>(),
      isA<FieldImprovementHexSelectionTargetView>(),
      isA<ArtifactHexSelectionTargetView>(),
      isA<ObjectiveHexSelectionTargetView>(),
    ]);
    expect(view.targets.first.label, 'Teren');
    expect((view.targets[1] as UnitHexSelectionTargetView).unitId, 'unit-1');
    expect((view.targets[2] as CityHexSelectionTargetView).cityId, 'city-1');
    expect(
      (view.targets[4] as ArtifactHexSelectionTargetView).artifactId,
      'map-artifact',
    );
  });
}
