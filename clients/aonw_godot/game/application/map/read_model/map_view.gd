class_name AonwMapView
extends RefCounted

var _map_id: StringName
var _content_hash: String
var _grid_layout: StringName
var _cols: int
var _rows: int
var _default_zoom: float
var _maximum_height: int
var _objectives: Array[AonwMapObjectiveView]
var _tiles: Array[AonwMapTileView]
var _tiles_by_coordinate: Dictionary

func _init(
	map_id: StringName,
	content_hash: String,
	grid_layout: StringName,
	cols: int,
	rows: int,
	default_zoom: float,
	objectives: Array[AonwMapObjectiveView],
	tiles: Array[AonwMapTileView],
) -> void:
	_map_id = map_id
	_content_hash = content_hash
	_grid_layout = grid_layout
	_cols = cols
	_rows = rows
	_default_zoom = default_zoom
	_objectives = objectives.duplicate()
	_tiles = tiles.duplicate()
	_objectives.make_read_only()
	_tiles.make_read_only()
	_tiles_by_coordinate = {}
	_maximum_height = 0
	for tile in _tiles:
		_tiles_by_coordinate[tile.coordinate()] = tile
		_maximum_height = maxi(_maximum_height, tile.height())
	_tiles_by_coordinate.make_read_only()

func map_id() -> StringName:
	return _map_id

func content_hash() -> String:
	return _content_hash

func grid_layout() -> StringName:
	return _grid_layout

func cols() -> int:
	return _cols

func rows() -> int:
	return _rows

func default_zoom() -> float:
	return _default_zoom

func maximum_height() -> int:
	return _maximum_height

func objectives() -> Array[AonwMapObjectiveView]:
	return _objectives

func tiles() -> Array[AonwMapTileView]:
	return _tiles

func tile_at(coordinate: Vector2i) -> AonwMapTileView:
	return _tiles_by_coordinate.get(coordinate) as AonwMapTileView

func contains(coordinate: Vector2i) -> bool:
	return _tiles_by_coordinate.has(coordinate)

func is_within_bounds(coordinate: Vector2i) -> bool:
	return (
		coordinate.x >= 0
		and coordinate.x < _cols
		and coordinate.y >= 0
		and coordinate.y < _rows
	)
