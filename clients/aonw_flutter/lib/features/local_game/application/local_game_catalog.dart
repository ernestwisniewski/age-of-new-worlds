import '../../map/application/map_session_port.dart';

enum LocalGameScenarioView {
  starterDuel,
  dravonia,
  myranth,
  terenos,
  verdantia,
}

final class LocalGameCatalogEntryView {
  const LocalGameCatalogEntryView({
    required this.id,
    required this.assets,
    required this.mapId,
    required this.rulesetId,
    required this.columns,
    required this.rows,
    required this.maximumPlayers,
    required this.participantIds,
  }) : assert(columns > 0),
       assert(rows > 0),
       assert(maximumPlayers >= 2),
       assert(maximumPlayers <= 4);

  final LocalGameScenarioView id;
  final MapAssetPaths assets;
  final String mapId;
  final String rulesetId;
  final int columns;
  final int rows;
  final int maximumPlayers;
  final List<String> participantIds;

  int get opponentCount => maximumPlayers - 1;
}

abstract final class LocalGameCatalog {
  static const minimumHotseatOpponents = 2;

  static const entries = <LocalGameCatalogEntryView>[
    LocalGameCatalogEntryView(
      id: LocalGameScenarioView.starterDuel,
      mapId: 'aonw2_starter',
      rulesetId: 'aonw-standard',
      columns: 7,
      rows: 7,
      maximumPlayers: 2,
      assets: MapAssetPaths(
        document: 'assets/maps/aonw2_starter/map.json',
        bundleManifest: 'assets/maps/aonw2_starter/map_texture_manifest.json',
        scenarioDocument: 'assets/scenarios/aonw2_local_duel.json',
        actorPlayerId: 'player-1',
      ),
      participantIds: ['player-1', 'player-2'],
    ),
    LocalGameCatalogEntryView(
      id: LocalGameScenarioView.dravonia,
      mapId: 'dravonia',
      rulesetId: 'aonw-standard',
      columns: 40,
      rows: 30,
      maximumPlayers: 4,
      assets: MapAssetPaths(
        document: 'assets/maps/dravonia/map.json',
        bundleManifest: 'assets/maps/dravonia/map_texture_manifest.json',
        scenarioDocument: 'assets/scenarios/dravonia_local.json',
        actorPlayerId: 'player-1',
      ),
      participantIds: ['player-1', 'player-2', 'player-3', 'player-4'],
    ),
    LocalGameCatalogEntryView(
      id: LocalGameScenarioView.myranth,
      mapId: 'myranth',
      rulesetId: 'aonw-standard',
      columns: 25,
      rows: 19,
      maximumPlayers: 3,
      assets: MapAssetPaths(
        document: 'assets/maps/myranth/map.json',
        bundleManifest: 'assets/maps/myranth/map_texture_manifest.json',
        scenarioDocument: 'assets/scenarios/myranth_local.json',
        actorPlayerId: 'player-1',
      ),
      participantIds: ['player-1', 'player-2', 'player-3'],
    ),
    LocalGameCatalogEntryView(
      id: LocalGameScenarioView.terenos,
      mapId: 'terenos',
      rulesetId: 'aonw-standard',
      columns: 20,
      rows: 15,
      maximumPlayers: 3,
      assets: MapAssetPaths(
        document: 'assets/maps/terenos/map.json',
        bundleManifest: 'assets/maps/terenos/map_texture_manifest.json',
        scenarioDocument: 'assets/scenarios/terenos_local.json',
        actorPlayerId: 'player-1',
      ),
      participantIds: ['player-1', 'player-2', 'player-3'],
    ),
    LocalGameCatalogEntryView(
      id: LocalGameScenarioView.verdantia,
      mapId: 'verdantia',
      rulesetId: 'aonw-standard',
      columns: 30,
      rows: 20,
      maximumPlayers: 4,
      assets: MapAssetPaths(
        document: 'assets/maps/verdantia/map.json',
        bundleManifest: 'assets/maps/verdantia/map_texture_manifest.json',
        scenarioDocument: 'assets/scenarios/verdantia_local.json',
        actorPlayerId: 'player-1',
      ),
      participantIds: ['player-1', 'player-2', 'player-3', 'player-4'],
    ),
  ];

  static List<LocalGameCatalogEntryView> get hotseatEntries => [
    for (final entry in entries)
      if (entry.opponentCount >= minimumHotseatOpponents) entry,
  ];
}
