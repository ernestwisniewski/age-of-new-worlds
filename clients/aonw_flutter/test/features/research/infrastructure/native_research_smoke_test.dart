import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_game_session_gateway.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'queries and selects research through the native Rust session',
    () async {
      final gateway = RustGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(gateway.close);
      final scene = await gateway.load(MapAssetPaths.starter);

      final options = await gateway.researchOptions(
        expectedRevision: scene.player.stamp.revision,
      );
      expect(options.playerId, scene.player.actorPlayerId);
      expect(options.options, hasLength(TechnologyIdView.values.length));
      expect(
        options.options.map((option) => option.technology),
        TechnologyIdView.values,
      );
      final available = options.options.firstWhere(
        (option) => option.availability == TechnologyAvailabilityView.available,
      );

      final selected = await gateway.selectTechnology(
        expectedRevision: options.stamp.revision,
        technology: available.technology,
      );
      expect(selected.accepted, isTrue);
      expect(selected.player?.stamp.revision, options.stamp.revision + 1);

      final refreshed = await gateway.researchOptions(
        expectedRevision: selected.player!.stamp.revision,
      );
      expect(refreshed.activeTechnology, available.technology);
      expect(
        refreshed.options
            .singleWhere((option) => option.technology == available.technology)
            .availability,
        TechnologyAvailabilityView.active,
      );
    },
  );
}

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
