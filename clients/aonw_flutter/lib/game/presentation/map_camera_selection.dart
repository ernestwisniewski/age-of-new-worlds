import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';

typedef MapCameraSelection = ({
  String key,
  String? unitId,
  MapHexCoordinate coordinate,
});

MapCameraSelection? mapCameraSelection(MapRenderSnapshot snapshot) {
  final player = snapshot.player;
  final unitId = snapshot.interaction.selectedUnitId;
  if (unitId != null) {
    final unit = player.visibleUnitById(unitId);
    if (unit == null || !snapshot.map.contains(unit.coordinate)) return null;
    if (unit.ownerPlayerId != player.actorPlayerId &&
        player.fog.visibilityAt(unit.coordinate) !=
            MapFogVisibilityView.visible) {
      return null;
    }
    return (key: 'unit:$unitId', unitId: unitId, coordinate: unit.coordinate);
  }
  final cityId = snapshot.interaction.city?.cityId;
  final city = cityId == null ? null : player.cityById(cityId);
  if (city == null || !snapshot.map.contains(city.center)) return null;
  if (city.ownerPlayerId != player.actorPlayerId &&
      player.fog.visibilityAt(city.center) == MapFogVisibilityView.hidden) {
    return null;
  }
  return (key: 'city:$cityId', unitId: null, coordinate: city.center);
}
