import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/map/city_founding_preview_layer.dart';
import 'package:aonw_flutter/game/map/city_management_overlay_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';

import '../support/map_test_fixture.dart';

MapCityManagementOverlayLayerComponent managementOverlay({
  bool expansion = false,
  bool pending = false,
  bool largeYield = false,
}) {
  final city = testCityView();
  final scene = testMapScene(cols: 4, rows: 3, cities: [city]);
  return MapCityManagementOverlayLayerComponent()..applyManagement(
    MapStaticRenderCache.build(scene.map),
    CityState(
      cityId: city.id,
      inspection: _inspection(largeYield),
      managementMode: expansion
          ? CityManagementMode.expansion
          : CityManagementMode.workedHexes,
      inFlightAction: pending
          ? SelectCityExpansionActionView(
              cityId: city.id,
              target: const (col: 2, row: 1),
            )
          : null,
    ),
    scene.player,
  );
}

CityInspectionView _inspection(bool largeYield) {
  final source = testCityInspectionView();
  if (!largeYield) return source;
  final expansion = source.expansion;
  return CityInspectionView(
    workedHexes: source.workedHexes,
    cityYield: source.cityYield,
    expansion: CityExpansionOptionsView(
      stamp: expansion.stamp,
      cityId: expansion.cityId,
      controlledHexes: expansion.controlledHexes,
      preferredHex: expansion.preferredHex,
      candidates: const [
        CityExpansionCandidateView(
          coordinate: (col: 2, row: 1),
          score: 1,
          distance: 1,
          tileYield: YieldValueView(
            food: 123,
            production: 4567,
            gold: 1234567890123456789,
            defense: 987654321098765432,
          ),
        ),
      ],
    ),
  );
}

MapCityFoundingPreviewLayerComponent foundingOverlay() {
  final founder = testVisibleUnit(kind: VisibleUnitKind.settler);
  final scene = testMapScene(cols: 4, rows: 3, units: [founder]);
  const available = [(col: 1, row: 1), (col: 0, row: 1), (col: 1, row: 0)];
  return MapCityFoundingPreviewLayerComponent()..applyFounding(
    MapStaticRenderCache.build(scene.map),
    CityState(
      founderUnitId: founder.id,
      foundingOptions: CityFoundingOptionsView(
        stamp: scene.player.stamp,
        founderUnitId: founder.id,
        center: founder.coordinate,
        selectedControlledHexes: const [],
        availableControlledHexes: available,
        rankedAvailableControlledHexes: available,
        requiredControlledHexes: 2,
        maximumRadius: 2,
      ),
      foundingSelection: const [(col: 1, row: 0)],
    ),
    scene.player,
  );
}
