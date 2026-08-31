class_name AonwLogicalMapEditor
extends RefCounted

func inspect_tile(_source: AonwMapSource, _coordinate: Vector2i) -> Dictionary:
	return _not_configured()

func set_tile_terrain(
	_source: AonwMapSource,
	_coordinate: Vector2i,
	_terrain: StringName,
) -> Dictionary:
	return _not_configured()

func set_tile_resources(
	_source: AonwMapSource,
	_coordinate: Vector2i,
	_resources: Array[StringName],
) -> Dictionary:
	return _not_configured()

func set_tile_height(
	_source: AonwMapSource,
	_coordinate: Vector2i,
	_height: int,
) -> Dictionary:
	return _not_configured()

func paint_tiles_terrain(
	_source: AonwMapSource,
	_coordinates: Array[Vector2i],
	_terrain: StringName,
) -> Dictionary:
	return _not_configured()

func paint_tiles_resources(
	_source: AonwMapSource,
	_coordinates: Array[Vector2i],
	_resources: Array[StringName],
) -> Dictionary:
	return _not_configured()

func paint_tiles_height(
	_source: AonwMapSource,
	_coordinates: Array[Vector2i],
	_height: int,
) -> Dictionary:
	return _not_configured()

func _not_configured() -> Dictionary:
	return {
		"ok": false,
		"message": "logical map editor is not configured",
	}
