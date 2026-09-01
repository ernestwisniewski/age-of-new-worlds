import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/server_projection_decoder.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = ServerProjectionDecoder();

  test('decodes one strict recipient resync without canonical state', () {
    final projection = decoder.resync(
      server.GameResync(
        matchId: 'match-1',
        playerId: 'player-1',
        eventOffset: 10,
        snapshotJson: jsonEncode(_snapshot(7)),
      ),
    );

    expect(projection.playerId, 'player-1');
    expect(projection.revision, 7);
    expect(projection.canSubmitTurn, isTrue);

    final response = decoder.snapshotResponse(
      server.GameResync(
        matchId: 'match-1',
        playerId: 'player-1',
        eventOffset: 10,
        snapshotJson: jsonEncode(_snapshot(7)),
      ),
    );
    expect(response.require<AonwSnapshotResponse>().snapshot.stamp.revision, 7);
  });

  test('decodes a contiguous recipient-only command outcome', () {
    final command = decoder.command(
      server.GameCommandOutcome(
        matchId: 'match-1',
        clientCommandId: 'command-1',
        initialEventOffset: 10,
        finalEventOffset: 11,
        duplicate: false,
        outcomeJson: jsonEncode(_outcome()),
      ),
    );

    expect(command.accepted, isTrue);
    expect(command.projection.revision, 8);
    expect(command.projection.eventOffset, 11);

    final response = decoder.commandResponse(
      server.GameCommandOutcome(
        matchId: 'match-1',
        clientCommandId: 'command-1',
        initialEventOffset: 10,
        finalEventOffset: 11,
        duplicate: false,
        outcomeJson: jsonEncode(_outcome()),
      ),
    );
    expect(response.require<AonwCommandResponse>().result.accepted, isTrue);
  });

  test(
    'maps server query success and failure to the local client protocol',
    () {
      final success = decoder.queryResponse(
        server.GamePlayerQueryOutcome(
          matchId: 'match-1',
          outcomeJson: jsonEncode({
            'status': 'success',
            'result': {
              'type': 'reachable',
              'stamp': _stamp(7),
              'unitId': 'unit-1',
              'availableMovementUnits': 2,
              'tiles': <Object?>[],
            },
          }),
        ),
      );
      expect(
        success.require<AonwQueryResponse>().result,
        isA<AonwReachableResult>(),
      );

      final failure = decoder.queryResponse(
        server.GamePlayerQueryOutcome(
          matchId: 'match-1',
          outcomeJson: jsonEncode({
            'status': 'failure',
            'error': {'code': 'stale_revision', 'message': 'stale'},
          }),
        ),
      );
      expect(failure.isSuccess, isFalse);
      expect(failure.error?.code, 'stale_revision');
    },
  );

  test('rejects an outcome that exposes a canonical field', () {
    final outcome = _outcome()..['state'] = const <String, Object?>{};

    expect(
      () => decoder.command(
        server.GameCommandOutcome(
          matchId: 'match-1',
          clientCommandId: 'command-1',
          initialEventOffset: 10,
          finalEventOffset: 11,
          duplicate: false,
          outcomeJson: jsonEncode(outcome),
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects a snapshot with an unknown nested field', () {
    final snapshot = _snapshot(7)..['canonicalState'] = const {};

    expect(
      () => decoder.resync(
        server.GameResync(
          matchId: 'match-1',
          playerId: 'player-1',
          eventOffset: 10,
          snapshotJson: jsonEncode(snapshot),
        ),
      ),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _outcome() => {
  'stamp': _stamp(8),
  'rejection': null,
  'recipient': {
    'recipientPlayerId': 'player-1',
    'snapshot': _snapshot(8, submitted: true),
    'patch': {
      'fromRevision': 7,
      'toRevision': 8,
      'turn': 1,
      'turnMode': 'simultaneous',
      'fog': null,
      'economy': null,
      'research': null,
      'victory': null,
      'turnLifecycle': {
        'ownState': 'active',
        'ownSubmitted': true,
        'requiredSubmissionCount': 2,
        'submittedCount': 1,
      },
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
    'events': <Object?>[],
    'evidence': null,
  },
};

Map<String, Object?> _snapshot(int revision, {bool submitted = false}) => {
  'stamp': _stamp(revision),
  'turn': 1,
  'turnMode': 'simultaneous',
  'participants': _participants(),
  'fog': _fog(),
  'economy': _economy(),
  'research': {
    'activeTechnologyId': null,
    'activeProgress': null,
    'activeEffectiveCost': null,
    'scienceOverflow': 0,
    'scienceYield': {
      'total': 0,
      'byCityId': <String, int>{},
      'sources': <Object?>[],
    },
  },
  'victory': _victory(),
  'outcome': {
    'condition': 'ongoing',
    'winnerPlayerId': null,
    'scoreByPlayerId': <String, int>{},
  },
  'turnLifecycle': {
    'ownState': 'active',
    'ownSubmitted': submitted,
    'requiredSubmissionCount': 2,
    'submittedCount': submitted ? 1 : 0,
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

List<Map<String, Object?>> _participants() => [
  {
    'id': 'player-1',
    'name': 'Player One',
    'colorValue': 0xff000000,
    'country': 'poland',
    'kind': 'human',
  },
  {
    'id': 'player-2',
    'name': 'Player Two',
    'colorValue': 0xffffffff,
    'country': 'germany',
    'kind': 'human',
  },
];

Map<String, Object?> _fog() => {
  'enabled': true,
  'discoveredHexes': [
    {'col': 1, 'row': 1},
    {'col': 2, 'row': 1},
  ],
  'visibleHexes': [
    {'col': 2, 'row': 1},
  ],
};

Map<String, Object?> _economy() => {
  'gold': 100,
  'warWeariness': 0,
  'stabilityNet': 0,
  'strategicResourceStockpile': <Object?>[],
  'strategicResourceOutput': <Object?>[],
  'strategicResourceSources': <Object?>[],
  'forecast': {
    'treasury': 100,
    'cityIncome': 0,
    'projectIncome': 0,
    'grossIncome': 0,
    'netPerTurn': 0,
    'citySources': <Object?>[],
    'projectSources': <Object?>[],
    'upkeep': {
      'upkeepBearingUnitCount': 0,
      'freeUnitCount': 0,
      'paidUnitCount': 0,
      'total': 0,
      'nextWorkerUpkeep': 0,
      'sources': <Object?>[],
    },
    'stability': {
      'baseOrder': 0,
      'buildingSources': 0,
      'luxurySources': 0,
      'technologySources': 0,
      'artifactSources': 0,
      'wonderSources': 0,
      'cityCost': 0,
      'populationCost': 0,
      'cohesionCost': 0,
      'conqueredCityCost': 0,
      'warWearinessCost': 0,
      'hegemonyTax': 0,
      'sourceTotal': 0,
      'costTotal': 0,
      'relativeStandingAdjustment': 0,
      'effectiveNet': 0,
      'band': 'stable',
    },
  },
};

Map<String, Object?> _victory() => {
  'conquestEnabled': true,
  'dominationEnabled': true,
  'dominationRequiredControlPercent': 60,
  'dominationRequiredHoldTurns': 5,
  'culturalEnabled': true,
  'culturalRequiredArtifacts': 6,
  'culturalRequiredHoldTurns': 5,
  'scoreFallbackEnabled': false,
  'turnLimit': null,
  'remainingTurns': null,
  'scoreByPlayerId': {'player-1': 0, 'player-2': 0},
  'domination': [
    {
      'playerId': 'player-1',
      'controlledPassableHexes': 0,
      'totalPassableHexes': 6,
      'holdTurns': 0,
    },
    {
      'playerId': 'player-2',
      'controlledPassableHexes': 0,
      'totalPassableHexes': 6,
      'holdTurns': 0,
    },
  ],
  'ownCultural': {'uniqueStoredArtifacts': 0, 'holdTurns': 0},
  'mapObjectives': <Object?>[],
};

Map<String, Object?> _stamp(int revision) => {
  'revision': revision,
  'stateDigest': 'digest-$revision',
  'mapHash': 'map-hash',
  'rulesetHash': 'ruleset-hash',
};
