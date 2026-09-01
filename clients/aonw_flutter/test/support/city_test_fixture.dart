part of 'map_test_fixture.dart';

CityView testCityView({
  String id = 'preview-city',
  String ownerPlayerId = 'preview-player',
  String name = 'Preview City',
  MapHexCoordinate center = const (col: 1, row: 1),
  List<MapHexCoordinate>? visibleControlledHexes,
  int population = 1,
  bool owned = true,
}) => CityView(
  id: id,
  ownerPlayerId: ownerPlayerId,
  name: name,
  center: center,
  visibleControlledHexes: visibleControlledHexes ?? [center],
  hitPoints: 10,
  ownedDetails: owned
      ? OwnedCityDetailsView(
          population: population,
          storedFood: 0,
          maxHexes: 4,
          territoryRadius: 2,
          workedHexes: const [],
          preferredExpansionHex: null,
        )
      : null,
);

CityFoundingOptionsView testCityFoundingOptionsView({
  String founderUnitId = 'preview-commander',
}) => CityFoundingOptionsView(
  stamp: testSessionStamp(),
  founderUnitId: founderUnitId,
  center: const (col: 0, row: 0),
  selectedControlledHexes: const [],
  availableControlledHexes: const [(col: 1, row: 0), (col: 0, row: 1)],
  requiredControlledHexes: 1,
  maximumRadius: 2,
);

CityInspectionView testCityInspectionView({String cityId = 'preview-city'}) =>
    CityInspectionView(
      workedHexes: CityWorkedHexOptionsView(
        stamp: testSessionStamp(),
        cityId: cityId,
        center: const (col: 1, row: 1),
        controlledHexes: const [(col: 1, row: 0)],
        availableHexes: const [(col: 1, row: 0)],
        selectedHexes: const [],
        effectiveHexes: const [(col: 1, row: 0)],
        limit: 1,
      ),
      expansion: CityExpansionOptionsView(
        stamp: testSessionStamp(),
        cityId: cityId,
        controlledHexes: const [(col: 1, row: 0)],
        preferredHex: null,
        candidates: const [
          CityExpansionCandidateView(
            coordinate: (col: 2, row: 1),
            score: 3,
            distance: 1,
          ),
        ],
      ),
      cityYield: CityYieldView(
        stamp: testSessionStamp(),
        cityId: cityId,
        contributions: const [],
        total: const YieldValueView(
          food: 2,
          production: 1,
          gold: 1,
          defense: 0,
        ),
      ),
    );
