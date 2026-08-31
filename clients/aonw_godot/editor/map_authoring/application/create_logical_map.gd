@tool
class_name AonwCreateLogicalMap
extends RefCounted

var _workbench: AonwLogicalMapWorkbench
var _store: AonwGeneratedMapStore

func _init(
	workbench: AonwLogicalMapWorkbench,
	store: AonwGeneratedMapStore,
) -> void:
	assert(workbench != null, "Logical map workbench is required")
	assert(store != null, "Generated map store is required")
	_workbench = workbench
	_store = store

func execute(
	map_id: String,
	cols: int,
	rows: int,
	default_zoom: float,
	hex_radius_meters: float,
	max_terrain_height_meters: float,
	seed: String,
	generator_id: StringName = &"blank",
) -> Dictionary:
	var generated := _workbench.generate_new_map(
		generator_id,
		map_id,
		cols,
		rows,
		default_zoom,
		hex_radius_meters,
		max_terrain_height_meters,
		seed,
	)
	if not generated["ok"]:
		return generated
	return _store.create(map_id, generated["package"])
