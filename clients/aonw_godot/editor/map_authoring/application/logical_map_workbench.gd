class_name AonwLogicalMapWorkbench
extends RefCounted

func generate_map(_spec_document: String) -> Dictionary:
	return {
		"ok": false,
		"code": "logical_map_workbench_not_configured",
		"message": "logical map workbench is not configured",
	}

func generate_blank_map(
	_map_id: String,
	_cols: int,
	_rows: int,
	_default_zoom: float,
	_hex_radius_meters: float,
	_max_terrain_height_meters: float,
	_seed: String,
) -> Dictionary:
	return _not_configured()

func generate_new_map(
	_generator_id: StringName,
	_map_id: String,
	_cols: int,
	_rows: int,
	_default_zoom: float,
	_hex_radius_meters: float,
	_max_terrain_height_meters: float,
	_seed: String,
) -> Dictionary:
	return _not_configured()

func reconfigure_terrain_height(
	_map_document: String,
	_terrain_authoring_document: String,
	_max_terrain_height_meters: float,
) -> Dictionary:
	return {
		"ok": false,
		"code": "logical_map_workbench_not_configured",
		"message": "logical map workbench is not configured",
	}

func inspect_map_tile(_map_document: String, _coordinate: Vector2i) -> Dictionary:
	return _not_configured()

func set_tile_terrain(
	_map_document: String,
	_terrain_authoring_document: String,
	_coordinate: Vector2i,
	_terrain: StringName,
) -> Dictionary:
	return _not_configured()

func set_tile_resources(
	_map_document: String,
	_terrain_authoring_document: String,
	_coordinate: Vector2i,
	_resources: Array[StringName],
) -> Dictionary:
	return _not_configured()

func set_tile_height(
	_map_document: String,
	_terrain_authoring_document: String,
	_coordinate: Vector2i,
	_height: int,
) -> Dictionary:
	return _not_configured()

func _not_configured() -> Dictionary:
	return {
		"ok": false,
		"code": "logical_map_workbench_not_configured",
		"message": "logical map workbench is not configured",
	}
