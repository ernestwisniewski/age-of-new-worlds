import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'opens every catalog map with its complete participant roster',
    () async {
      final gateway = EngineGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(gateway.close);

      expect(LocalGameCatalog.entries, hasLength(5));
      for (final entry in LocalGameCatalog.entries) {
        expect(entry.participantIds, hasLength(entry.maximumPlayers));
        expect(entry.participantIds.toSet(), hasLength(entry.maximumPlayers));

        final scene = await gateway.startLocalMatch(_setup(entry));

        expect(scene.map.mapId, entry.mapId);
        expect(scene.map.cols, entry.columns);
        expect(scene.map.rows, entry.rows);
        expect(scene.player.actorPlayerId, entry.assets.actorPlayerId);
        expect(
          scene.player.participants.map((participant) => participant.id),
          entry.participantIds,
        );
        expect(scene.player.units, hasLength(entry.maximumPlayers));
      }
    },
  );
}

LocalMatchSetupView _setup(LocalGameCatalogEntryView entry) =>
    LocalMatchSetupView(
      assets: entry.assets,
      participants: [
        for (var index = 0; index < entry.maximumPlayers; index++)
          LocalParticipantSetupView(
            id: entry.participantIds[index],
            name: 'Player ${index + 1}',
            colorValue: 0xff000000 + index,
            country: LocalPlayerCountryView.values[index],
            control: index == 0
                ? LocalPlayerControlView.human
                : LocalPlayerControlView.ai,
            ai: index == 0 ? null : LocalAiProfileView(seed: index + 1),
          ),
      ],
      fogEnabled: false,
    );

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
