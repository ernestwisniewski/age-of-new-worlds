import '../../map/application/map_session_port.dart';

enum LocalGameScenarioView { starterDuel }

final class LocalGameCatalogEntryView {
  const LocalGameCatalogEntryView({
    required this.id,
    required this.assets,
    required this.participantIds,
  });

  final LocalGameScenarioView id;
  final MapAssetPaths assets;
  final List<String> participantIds;
}

abstract final class LocalGameCatalog {
  static const entries = <LocalGameCatalogEntryView>[
    LocalGameCatalogEntryView(
      id: LocalGameScenarioView.starterDuel,
      assets: MapAssetPaths(
        document: 'assets/maps/aonw2_starter/map.json',
        bundleManifest: 'assets/maps/aonw2_starter/map_texture_manifest.json',
        scenarioDocument: 'assets/scenarios/aonw2_local_duel.json',
        actorPlayerId: 'player-1',
      ),
      participantIds: ['player-1', 'player-2'],
    ),
  ];
}
