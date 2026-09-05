import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';

MapRenderSnapshot cityProductionPerformanceSnapshot(MapRenderSnapshot source) {
  final player = source.player;
  return MapRenderSnapshot(
    map: source.map,
    reference: source.reference,
    interaction: source.interaction,
    player: PlayerMapView(
      actorPlayerId: player.actorPlayerId,
      stamp: player.stamp,
      turnMode: player.turnMode,
      participants: player.participants,
      fog: player.fog,
      economy: player.economy,
      research: player.research,
      victory: player.victory,
      turnView: player.turnView,
      diplomacy: player.diplomacy,
      units: player.units,
      fieldImprovements: player.fieldImprovements,
      roads: player.roads,
      cities: [
        for (final city in player.cities)
          CityView(
            id: city.id,
            ownerPlayerId: city.ownerPlayerId,
            name: city.name,
            center: city.center,
            visibleControlledHexes: city.visibleControlledHexes,
            hitPoints: city.hitPoints,
            ownedDetails: city.ownerPlayerId == player.actorPlayerId
                ? OwnedCityDetailsView(
                    population: 1,
                    storedFood: 0,
                    maxHexes: 7,
                    territoryRadius: 1,
                    workedHexes: const [],
                    preferredExpansionHex: null,
                    productionQueue: CityProductionQueueView(
                      targetKind: 'unit',
                      target: 'worker',
                      investedProduction: 0,
                      resourceAllocation: const {},
                    ),
                  )
                : null,
          ),
      ],
    ),
  );
}
