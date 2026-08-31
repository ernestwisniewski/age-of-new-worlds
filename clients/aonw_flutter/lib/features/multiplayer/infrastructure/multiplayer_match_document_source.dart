import 'dart:convert';

import 'package:flutter/services.dart';

import '../application/multiplayer_session_port.dart';
import '../read_model/multiplayer_view.dart';

final class AssetMultiplayerMatchDocumentSource
    implements MultiplayerMatchDocumentSource {
  const AssetMultiplayerMatchDocumentSource({required AssetBundle assets})
    : _assets = assets;

  static const _mapPath = 'assets/maps/aonw2_starter/map.json';

  final AssetBundle _assets;

  @override
  Future<MultiplayerMatchDocuments> load() async {
    final mapDocument = await _assets.loadString(_mapPath);
    return documentsFor(mapDocument);
  }

  static MultiplayerMatchDocuments documentsFor(String mapDocument) {
    _validateMapDocument(mapDocument);
    return MultiplayerMatchDocuments(
      mapId: 'aonw2_starter',
      mapDocument: mapDocument,
      scenarioDocument: jsonEncode(_scenario),
      rulesetId: 'aonw-standard',
      matchIdentityDocument: jsonEncode(_matchIdentity),
      fogEnabled: true,
      creatorPlayerId: 'player-1',
    );
  }

  static void _validateMapDocument(String document) {
    final value = jsonDecode(document);
    if (value is! Map<String, Object?> ||
        value['schemaVersion'] != 1 ||
        value['mapName'] != 'aonw2_starter') {
      throw const FormatException('The packaged multiplayer map is invalid.');
    }
  }
}

const _scenario = <String, Object?>{
  'schemaVersion': 1,
  'scenarioId': 'aonw2_starter_multiplayer',
  'mapId': 'aonw2_starter',
  'rulesetId': 'aonw-standard',
  'initialUnits': [
    {
      'id': 'player-1-commander',
      'ownerPlayerId': 'player-1',
      'kind': 'commander',
      'name': 'First Commander',
      'col': 2,
      'row': 1,
    },
    {
      'id': 'player-2-commander',
      'ownerPlayerId': 'player-2',
      'kind': 'commander',
      'name': 'Second Commander',
      'col': 4,
      'row': 4,
    },
  ],
};

const _matchIdentity = <String, Object?>{
  'matchRules': {
    'gameLength': {
      'kind': 'unlimited',
      'targetMinutes': null,
      'turnLimit': null,
      'paceProfile': 'unlimited',
      'scoreFallbackEnabled': false,
    },
    'victory': {
      'conquestEnabled': true,
      'dominationEnabled': true,
      'dominationControlPercent': 60,
      'dominationHoldTurns': 5,
      'scoreFallbackEnabled': false,
      'turnLimit': null,
      'hardTimeLimitMinutes': null,
      'culturalEnabled': true,
      'culturalRequiredArtifacts': 6,
      'culturalHoldTurns': 5,
    },
    'balance': <String, Object?>{},
  },
  'participants': [
    {
      'id': 'player-1',
      'name': 'Player One',
      'colorValue': 4278190335,
      'country': 'poland',
      'kind': 'human',
      'ai': null,
    },
    {
      'id': 'player-2',
      'name': 'Player Two',
      'colorValue': 16711935,
      'country': 'germany',
      'kind': 'human',
      'ai': null,
    },
  ],
  'gameMode': 'multiplayer',
};
