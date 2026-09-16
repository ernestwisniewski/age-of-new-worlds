import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';

import '../../../support/map_test_fixture.dart';
import 'resource_test_fixture.dart';

PlayerMapView strategicResourcePlayer() => resourcePlayerFixture(
  inventory: _inventory(),
  shortages: const [MapResource.oil],
  cities: [testCityView(id: 'warsaw', name: 'Warszawa')],
  participants: const [
    MatchParticipantView(
      id: 'preview-player',
      name: 'Jadwiga',
      colorValue: 0xffd64141,
      country: MatchParticipantCountryView.poland,
      kind: MatchParticipantKindView.human,
    ),
    MatchParticipantView(
      id: 'partner',
      name: 'Friedrich',
      colorValue: 0xff4998e8,
      country: MatchParticipantCountryView.germany,
      kind: MatchParticipantKindView.ai,
    ),
    MatchParticipantView(
      id: 'unknown',
      name: 'Unmet player',
      colorValue: 0xffddaa33,
      country: MatchParticipantCountryView.france,
      kind: MatchParticipantKindView.ai,
    ),
  ],
  diplomacy: _diplomacy(),
);

PlayerStrategicResourceInventoryView _inventory() =>
    PlayerStrategicResourceInventoryView(
      availableTypeCount: 1,
      shortageTypeCount: 1,
      attentionCount: 2,
      balances: _balances(),
      allocations: const [
        PlayerStrategicResourceAllocationView(
          cityId: 'warsaw',
          resource: MapResource.oil,
          amount: 3,
        ),
      ],
      deposits: const [
        PlayerStrategicResourceDepositView(
          cityId: 'warsaw',
          coordinate: (col: 0, row: 0),
          resource: MapResource.iron,
          improvement: null,
          amountPerTurn: null,
        ),
        PlayerStrategicResourceDepositView(
          cityId: 'warsaw',
          coordinate: (col: 1, row: 0),
          resource: MapResource.oil,
          improvement: FieldImprovementKind.oilWell,
          amountPerTurn: 2,
        ),
      ],
      expiringTradeIds: const ['iron-import'],
    );

List<PlayerStrategicResourceBalanceView> _balances() => [
  for (final row in PlayerStrategicResourceInventoryView.empty().balances)
    switch (row.resource) {
      MapResource.iron => const PlayerStrategicResourceBalanceView(
        resource: MapResource.iron,
        stockpiled: false,
        controlledDeposits: 1,
        available: 2,
        allocated: 0,
        storedTotal: 0,
        domesticProduction: 0,
        imports: 5,
        exports: 0,
        netPerTurn: 5,
        sourceCount: 1,
        shortage: false,
        noFreeStock: false,
      ),
      MapResource.oil => const PlayerStrategicResourceBalanceView(
        resource: MapResource.oil,
        stockpiled: true,
        controlledDeposits: 1,
        available: 0,
        allocated: 3,
        storedTotal: 3,
        domesticProduction: 2,
        imports: 0,
        exports: 1,
        netPerTurn: 1,
        sourceCount: 1,
        shortage: true,
        noFreeStock: true,
      ),
      _ => row,
    },
];

DiplomacyView _diplomacy() => DiplomacyView(
  relations: const [
    DiplomaticRelationView(
      counterpartPlayerId: 'partner',
      status: DiplomaticRelationStatusView.friendly,
      relationScore: 40,
      statusExpiresOnTurn: null,
      lastChangedTurn: null,
      lastChangeReason: null,
    ),
  ],
  proposals: const [],
  messages: const [],
  resourceTradeAgreements: const [
    ResourceTradeAgreementView(
      id: 'oil-export',
      exporterPlayerId: 'preview-player',
      importerPlayerId: 'partner',
      resource: MapResource.oil,
      goldPerTurn: 0,
      remainingTurns: 8,
      amountPerTurn: 1,
      exchangeGroupId: 'barter',
    ),
    ResourceTradeAgreementView(
      id: 'iron-import',
      exporterPlayerId: 'partner',
      importerPlayerId: 'preview-player',
      resource: MapResource.iron,
      goldPerTurn: 4,
      remainingTurns: 1,
      amountPerTurn: 5,
      exchangeGroupId: null,
    ),
  ],
);
