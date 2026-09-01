import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/multiplayer_match_document_source.dart';
import 'package:aonw_flutter/features/multiplayer/read_model/multiplayer_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = AssetMultiplayerMatchDocumentSource(
    assets: _FileAssetBundle(),
  );

  test(
    'builds every catalog map as a simultaneous multiplayer match',
    () async {
      for (final entry in LocalGameCatalog.entries) {
        final documents = await source.load(
          MultiplayerMatchSetupView(
            mapId: entry.mapId,
            creatorCountry: 'japan',
            fogEnabled: false,
          ),
        );
        final map = _object(jsonDecode(documents.mapDocument));
        final scenario = _object(jsonDecode(documents.scenarioDocument));
        final identity = _object(jsonDecode(documents.matchIdentityDocument));
        final participants = _objects(identity['participants']);
        final units = _objects(scenario['initialUnits']);

        expect(documents.mapId, entry.mapId);
        expect(documents.rulesetId, entry.rulesetId);
        expect(documents.creatorPlayerId, entry.assets.actorPlayerId);
        expect(documents.fogEnabled, isFalse);
        expect(map['mapName'], entry.mapId);
        expect(map['cols'], entry.columns);
        expect(map['rows'], entry.rows);
        expect(scenario['mapId'], entry.mapId);
        expect(scenario['rulesetId'], entry.rulesetId);
        expect(identity['gameMode'], 'multiplayer');
        expect(identity['turnMode'], 'simultaneous');
        expect(participants, hasLength(entry.maximumPlayers));
        expect(
          participants.map((participant) => participant['id']),
          entry.participantIds,
        );
        expect(
          participants.map((participant) => participant['country']).toSet(),
          hasLength(entry.maximumPlayers),
        );
        expect(participants.first['country'], 'japan');
        expect(
          participants.every(
            (participant) =>
                participant['kind'] == 'human' && participant['ai'] == null,
          ),
          isTrue,
        );
        expect(
          units.map((unit) => unit['ownerPlayerId']).toSet(),
          entry.participantIds.toSet(),
        );
      }
    },
  );

  test('rejects map and civilization values outside the catalog', () async {
    await expectLater(
      source.load(
        const MultiplayerMatchSetupView(
          mapId: 'unknown-map',
          creatorCountry: 'poland',
          fogEnabled: true,
        ),
      ),
      throwsFormatException,
    );
    await expectLater(
      source.load(
        const MultiplayerMatchSetupView(
          mapId: 'aonw2_starter',
          creatorCountry: 'unknown-country',
          fogEnabled: true,
        ),
      ),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _object(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected object, got ${value.runtimeType}.');
}

List<Map<String, Object?>> _objects(Object? value) {
  if (value is! List<Object?>) {
    throw FormatException('Expected list, got ${value.runtimeType}.');
  }
  return [for (final item in value) _object(item)];
}

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
