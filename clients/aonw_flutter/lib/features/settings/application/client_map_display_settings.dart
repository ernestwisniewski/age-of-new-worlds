import '../../map/read_model/map_view_mode.dart';
import 'client_city_planning_settings.dart';

final class ClientMapDisplaySettings {
  const ClientMapDisplaySettings({
    this.cityPlanning = const ClientCityPlanningSettings(),
    this.preferredMapViewMode = MapViewMode.graphic,
    this.showMapGrid = false,
    this.showMapElevationWalls = false,
    this.showMapTerrainIcons = false,
    this.showMapResourceIcons = true,
    this.showMapHeightBadges = false,
  });

  final ClientCityPlanningSettings cityPlanning;
  final MapViewMode preferredMapViewMode;
  final bool showMapGrid;
  final bool showMapElevationWalls;
  final bool showMapTerrainIcons;
  final bool showMapResourceIcons;
  final bool showMapHeightBadges;

  ClientMapDisplaySettings copyWith({
    ClientCityPlanningSettings? cityPlanning,
    MapViewMode? preferredMapViewMode,
    bool? showMapGrid,
    bool? showMapElevationWalls,
    bool? showMapTerrainIcons,
    bool? showMapResourceIcons,
    bool? showMapHeightBadges,
  }) => ClientMapDisplaySettings(
    cityPlanning: cityPlanning ?? this.cityPlanning,
    preferredMapViewMode: preferredMapViewMode ?? this.preferredMapViewMode,
    showMapGrid: showMapGrid ?? this.showMapGrid,
    showMapElevationWalls: showMapElevationWalls ?? this.showMapElevationWalls,
    showMapTerrainIcons: showMapTerrainIcons ?? this.showMapTerrainIcons,
    showMapResourceIcons: showMapResourceIcons ?? this.showMapResourceIcons,
    showMapHeightBadges: showMapHeightBadges ?? this.showMapHeightBadges,
  );
}
