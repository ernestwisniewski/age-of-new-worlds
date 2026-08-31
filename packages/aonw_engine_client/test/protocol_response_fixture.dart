part of 'protocol_response_test.dart';

const _stamp = {
  'revision': 7,
  'stateDigest': 'digest-7',
  'mapHash': 'map-hash',
  'rulesetHash': 'ruleset-hash',
};

const _snapshot = {
  'stamp': _stamp,
  'turn': 1,
  'turnMode': 'sequential',
  'participants': [
    {
      'id': 'player-1',
      'name': 'Player One',
      'colorValue': 0xff000000,
      'country': 'poland',
      'kind': 'human',
    },
  ],
  'fog': {
    'enabled': true,
    'discoveredHexes': [
      {'col': 1, 'row': 1},
      {'col': 2, 'row': 1},
    ],
    'visibleHexes': [
      {'col': 2, 'row': 1},
    ],
  },
  'economy': {
    'gold': 73,
    'warWeariness': 5,
    'stabilityNet': -4,
    'strategicResourceStockpile': [
      {'resource': 'oil', 'amount': 2},
    ],
    'strategicResourceOutput': [
      {'resource': 'oil', 'amount': 1},
    ],
    'strategicResourceSources': [
      {
        'cityId': 'city-a',
        'coordinate': {'col': 1, 'row': 1},
        'resource': 'oil',
        'improvement': 'oilWell',
        'amountPerTurn': 1,
      },
    ],
  },
  'research': {
    'activeTechnologyId': 'agriculture',
    'activeProgress': 4,
    'activeEffectiveCost': 20,
    'scienceOverflow': 1,
    'scienceYield': {
      'total': 0,
      'byCityId': <String, int>{},
      'sources': <Object?>[],
    },
  },
  'outcome': {
    'condition': 'ongoing',
    'winnerPlayerId': null,
    'scoreByPlayerId': <String, int>{},
  },
  'turnLifecycle': {
    'ownState': 'active',
    'ownSubmitted': false,
    'requiredSubmissionCount': 1,
    'submittedCount': 0,
  },
  'pendingAction': null,
  'cityFoundingDraft': null,
  'diplomacy': {
    'relations': <Object?>[],
    'proposals': <Object?>[],
    'messages': <Object?>[],
    'resourceTradeAgreements': <Object?>[],
  },
  'units': <Object?>[],
  'cities': <Object?>[],
  'artifacts': <Object?>[],
  'fieldImprovements': <Object?>[],
  'roads': <Object?>[],
};

String _success(Map<String, Object?> response) => jsonEncode({
  'apiVersion': aonwClientApiVersion,
  'outcome': {'status': 'success', 'response': response},
});

Map<String, Object?> _commandResult(Map<String, Object?> outcome) => {
  'stamp': _stamp,
  'outcome': outcome,
  'events': const [],
  'evidence': null,
  'viewPatch': const {
    'fromRevision': 7,
    'toRevision': 7,
    'turn': 7,
    'turnMode': 'sequential',
    'fog': null,
    'economy': null,
    'research': null,
    'turnLifecycle': null,
    'outcome': null,
    'upsertedUnits': <Object?>[],
    'removedUnitIds': <Object?>[],
    'upsertedCities': <Object?>[],
    'removedCityIds': <Object?>[],
    'upsertedArtifacts': <Object?>[],
    'removedArtifactIds': <Object?>[],
    'upsertedFieldImprovements': <Object?>[],
    'removedFieldImprovementCoordinates': <Object?>[],
    'upsertedRoads': <Object?>[],
    'removedRoadCoordinates': <Object?>[],
    'pendingAction': null,
    'cityFoundingDraft': null,
    'diplomacy': null,
  },
};
