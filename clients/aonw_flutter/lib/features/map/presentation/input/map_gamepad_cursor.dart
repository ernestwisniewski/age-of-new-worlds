import '../../application/game_session_state.dart';
import '../../read_model/map_view.dart';
import 'map_input.dart';

final class MapGamepadCursor {
  Object? _sessionKey;
  Object? _selectionKey;
  int? _revision;
  MapHexCoordinate? _coordinate;

  void reset() {
    _sessionKey = null;
    _selectionKey = null;
    _revision = null;
    _coordinate = null;
  }

  void observe(GameSessionState state) {
    if (state is! GameSessionReady) {
      reset();
      return;
    }
    final stamp = state.recipient.stamp;
    final key = (
      state.scene.map.mapId,
      state.scene.map.contentHash,
      state.recipient.actorPlayerId,
      stamp.mapHash,
      stamp.rulesetHash,
    );
    if (key != _sessionKey || stamp.revision < (_revision ?? 0)) reset();
    _sessionKey = key;
    _revision = stamp.revision;
  }

  MapHexCoordinate? current(
    GameSessionReady state, {
    MapHexCoordinate? viewportCenter,
  }) {
    observe(state);
    final map = state.scene.map;
    final selection = _selectionTarget(state);
    if (selection != null &&
        selection.key != _selectionKey &&
        map.contains(selection.coordinate)) {
      _selectionKey = selection.key;
      return _coordinate = selection.coordinate;
    }
    final coordinate = _coordinate;
    if (coordinate != null && map.contains(coordinate)) return coordinate;
    _selectionKey = selection?.key;
    if (viewportCenter != null && map.contains(viewportCenter)) {
      return _coordinate = viewportCenter;
    }
    return _coordinate = map.tiles.firstOrNull?.coordinate;
  }

  MapHexCoordinate? move(
    GameSessionReady state,
    MapInputCommand command, {
    MapHexCoordinate? viewportCenter,
  }) {
    final origin = current(state, viewportCenter: viewportCenter);
    if (origin == null) return null;
    final next = MapInputCursor.move(state.scene.map, origin, command);
    if (next == origin) return null;
    return _coordinate = next;
  }
}

({Object key, MapHexCoordinate coordinate})? _selectionTarget(
  GameSessionReady state,
) {
  final interaction = state.interaction;
  final unitId = interaction.selectedUnitId;
  final unit = unitId == null ? null : state.recipient.visibleUnitById(unitId);
  if (unit != null) {
    return (
      key: ('unit', unit.id, unit.coordinate),
      coordinate: unit.coordinate,
    );
  }
  final cityId = interaction.city?.cityId;
  final city = cityId == null ? null : state.recipient.cityById(cityId);
  if (city != null) {
    return (key: ('city', city.id, city.center), coordinate: city.center);
  }
  final selected = interaction.selected;
  return selected == null
      ? null
      : (key: ('hex', selected), coordinate: selected);
}
