import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_reference_bundle_loader.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<({MapView map, MapReferenceBundle reference})>
loadStarterMapGoldenFixture(WidgetTester tester) async {
  final loadedMap = await tester.runAsync(() async {
    final session = await createAonwEngineSession();
    if (session == null) return null;
    try {
      final response = await session.send(
        AonwClientRequest.inspectMap(
          mapDocument: await rootBundle.loadString(
            'assets/maps/aonw2_starter/map.json',
          ),
        ),
      );
      return const MapViewMapper().fromWire(
        response.require<AonwMapInspectedResponse>().map,
      );
    } finally {
      await session.close();
    }
  });
  expect(loadedMap, isNotNull);
  final map = loadedMap!;
  final reference = await MapReferenceBundleLoader(rootBundle).load(
    manifestAsset: 'assets/maps/aonw2_starter/map_texture_manifest.json',
    map: map,
  );
  expect(reference.pages, hasLength(1));
  return (map: map, reference: reference);
}

SessionStampView starterMapGoldenStamp(String mapHash) => SessionStampView(
  revision: 0,
  stateDigest: 'b' * 64,
  mapHash: mapHash,
  rulesetHash: 'c' * 64,
);
