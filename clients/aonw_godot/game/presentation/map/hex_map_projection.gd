class_name AonwHexMapProjection
extends RefCounted

const HexGridGeometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const TerrainSpaceTransform := preload(
	"res://game/application/terrain/terrain_space_transform.gd"
)
const INVALID_HEX := Vector2i(-1, -1)

var _map: AonwMapView
var _artifact: AonwTerrainCompiledArtifact
var _terrain_data: Terrain3DData
var _geometry: AonwHexGridGeometry
var _space: AonwTerrainSpaceTransform

func _init(
	map: AonwMapView,
	artifact: AonwTerrainCompiledArtifact,
	terrain_data: Terrain3DData,
) -> void:
	assert(map != null, "MapView is required")
	assert(artifact != null, "Compiled Terrain3D artifact is required")
	assert(terrain_data != null, "Terrain3D data is required")
	assert(str(map.map_id()) == artifact.map_id, "Terrain mapId must match MapView")
	assert(map.content_hash() == artifact.map_content_hash, "Terrain hash must match MapView")
	_map = map
	_artifact = artifact
	_terrain_data = terrain_data
	_geometry = HexGridGeometry.new(map.cols(), map.rows(), artifact.hex_radius_meters)
	_space = TerrainSpaceTransform.new(artifact)

func contains(coordinate: Vector2i) -> bool:
	return _geometry.contains(coordinate)

func hex_center(coordinate: Vector2i, vertical_offset: float = 0.0) -> Vector3:
	return _terrain_point(_geometry.tile_center(coordinate), vertical_offset)

func hex_corner(coordinate: Vector2i, corner: int, vertical_offset: float = 0.0) -> Vector3:
	return _terrain_point(_geometry.corner_position(coordinate, corner), vertical_offset)

func hex_height(coordinate: Vector2i) -> float:
	return hex_center(coordinate).y

func local_to_hex(local_position: Vector3) -> Vector2i:
	var coordinate := _geometry.tile_at_point(_space.terrain_local_to_logical(local_position))
	return coordinate if contains(coordinate) else INVALID_HEX

func ray_to_hex(local_origin: Vector3, local_direction: Vector3) -> Vector2i:
	if local_direction.is_zero_approx():
		return INVALID_HEX
	var best := INVALID_HEX
	var best_distance := INF
	for tile in _map.tiles():
		var coordinate := tile.coordinate()
		var center := hex_center(coordinate)
		for corner in 6:
			var intersection: Variant = Geometry3D.ray_intersects_triangle(
				local_origin,
				local_direction,
				center,
				hex_corner(coordinate, (corner + 1) % 6),
				hex_corner(coordinate, corner),
			)
			if intersection == null:
				continue
			var distance := local_origin.distance_to(intersection)
			if distance < best_distance:
				best = coordinate
				best_distance = distance
	return best

func geometry() -> AonwHexGridGeometry:
	return _geometry

func world_size() -> Vector2:
	return _geometry.bounds().size

func _terrain_point(logical_point: Vector2, vertical_offset: float) -> Vector3:
	var local := _space.logical_to_terrain_local(logical_point)
	var height := _terrain_data.get_height(local)
	local.y = (height if is_finite(height) else 0.0) + vertical_offset
	return local
