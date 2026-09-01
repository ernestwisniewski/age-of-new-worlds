import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter/services.dart';

import '../../local_game/application/local_game_catalog.dart';
import '../application/multiplayer_session_port.dart';
import '../read_model/multiplayer_view.dart';

final class AssetMultiplayerMatchDocumentSource
    implements MultiplayerMatchDocumentSource {
  const AssetMultiplayerMatchDocumentSource({required AssetBundle assets})
    : _assets = assets;

  final AssetBundle _assets;

  @override
  Future<MultiplayerMatchDocuments> load(
    MultiplayerMatchSetupView setup,
  ) async {
    final entry = _catalogEntry(setup.mapId);
    final mapDocument = await _assets.loadString(entry.assets.document);
    final scenarioDocument = await _assets.loadString(
      entry.assets.scenarioDocument,
    );
    _validateMapDocument(mapDocument, entry);
    _validateScenarioDocument(scenarioDocument, entry);
    return MultiplayerMatchDocuments(
      mapId: entry.mapId,
      mapDocument: mapDocument,
      scenarioDocument: scenarioDocument,
      rulesetId: entry.rulesetId,
      matchIdentityDocument: jsonEncode(_matchIdentity(entry, setup)),
      fogEnabled: setup.fogEnabled,
      creatorPlayerId: entry.assets.actorPlayerId,
    );
  }
}

LocalGameCatalogEntryView _catalogEntry(String mapId) {
  for (final entry in LocalGameCatalog.entries) {
    if (entry.mapId == mapId) return entry;
  }
  throw const FormatException('The selected multiplayer map is invalid.');
}

void _validateMapDocument(String document, LocalGameCatalogEntryView entry) {
  final value = _object(jsonDecode(document), 'map');
  if (value['schemaVersion'] != 1 ||
      value['mapName'] != entry.mapId ||
      value['cols'] != entry.columns ||
      value['rows'] != entry.rows) {
    throw const FormatException('The packaged multiplayer map is invalid.');
  }
}

void _validateScenarioDocument(
  String document,
  LocalGameCatalogEntryView entry,
) {
  final value = _object(jsonDecode(document), 'scenario');
  final units = _list(value['initialUnits'], 'scenario.initialUnits');
  final owners = <String>{};
  for (final rawUnit in units) {
    final unit = _object(rawUnit, 'scenario.initialUnits[]');
    final owner = unit['ownerPlayerId'];
    if (owner is! String || !entry.participantIds.contains(owner)) {
      throw const FormatException(
        'The packaged multiplayer scenario roster is invalid.',
      );
    }
    owners.add(owner);
  }
  if (value['schemaVersion'] != 1 ||
      value['mapId'] != entry.mapId ||
      value['rulesetId'] != entry.rulesetId ||
      owners.length != entry.maximumPlayers ||
      !owners.containsAll(entry.participantIds)) {
    throw const FormatException(
      'The packaged multiplayer scenario is invalid.',
    );
  }
}

Map<String, Object?> _matchIdentity(
  LocalGameCatalogEntryView entry,
  MultiplayerMatchSetupView setup,
) {
  final countries = _participantCountries(setup.creatorCountry);
  return AonwMatchIdentity(
    participants: [
      for (var index = 0; index < entry.maximumPlayers; index++)
        AonwParticipant(
          id: entry.participantIds[index],
          name: 'Player ${index + 1}',
          colorValue: _participantColors[index],
          country: countries[index],
          kind: AonwPlayerKind.human,
        ),
    ],
    gameMode: AonwGameMode.multiplayer,
    turnMode: AonwTurnMode.simultaneous,
  ).toJson();
}

List<AonwPlayerCountry> _participantCountries(String creatorCountry) {
  final creator = AonwPlayerCountry.fromJson(creatorCountry);
  return [
    creator,
    for (final country in AonwPlayerCountry.values)
      if (country != creator) country,
  ];
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$path must be an object.');
}

List<Object?> _list(Object? value, String path) {
  if (value is List<Object?>) return value;
  throw FormatException('$path must be an array.');
}

const _participantColors = [0xff3d5a80, 0xffee6c4d, 0xff4f772d, 0xfff4d35e];
