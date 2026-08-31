@tool
class_name AonwFilesystemLogicalMapEditor
extends AonwLogicalMapEditor

enum PaintOperation {
	TERRAIN,
	RESOURCES,
	HEIGHT,
}

const AtomicResourceStore := preload(
	"res://editor/map_authoring/infrastructure/atomic_resource_store.gd"
)
const TerrainCompiler := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_compiler.gd"
)

var _workbench: AonwLogicalMapWorkbench
var _atomic_store := AtomicResourceStore.new()
var _compiler: AonwTerrainCompiler

func _init(
	workbench: AonwLogicalMapWorkbench,
	compiler: AonwTerrainCompiler = null,
) -> void:
	assert(workbench != null, "Logical map workbench is required")
	_workbench = workbench
	_compiler = compiler if compiler != null else TerrainCompiler.new()

func inspect_tile(source: AonwMapSource, coordinate: Vector2i) -> Dictionary:
	var map_result := _read_text(source.map_path)
	if not map_result["ok"]:
		return map_result
	return _workbench.inspect_map_tile(map_result["content"], coordinate)

func set_tile_terrain(
	source: AonwMapSource,
	coordinate: Vector2i,
	terrain: StringName,
) -> Dictionary:
	var coordinates: Array[Vector2i] = [coordinate]
	return paint_tiles_terrain(source, coordinates, terrain)

func set_tile_resources(
	source: AonwMapSource,
	coordinate: Vector2i,
	resources: Array[StringName],
) -> Dictionary:
	var coordinates: Array[Vector2i] = [coordinate]
	return paint_tiles_resources(source, coordinates, resources)

func set_tile_height(
	source: AonwMapSource,
	coordinate: Vector2i,
	height: int,
) -> Dictionary:
	var coordinates: Array[Vector2i] = [coordinate]
	return paint_tiles_height(source, coordinates, height)

func paint_tiles_terrain(
	source: AonwMapSource,
	coordinates: Array[Vector2i],
	terrain: StringName,
) -> Dictionary:
	return _paint_tiles(source, coordinates, PaintOperation.TERRAIN, terrain)

func paint_tiles_resources(
	source: AonwMapSource,
	coordinates: Array[Vector2i],
	resources: Array[StringName],
) -> Dictionary:
	return _paint_tiles(source, coordinates, PaintOperation.RESOURCES, resources)

func paint_tiles_height(
	source: AonwMapSource,
	coordinates: Array[Vector2i],
	height: int,
) -> Dictionary:
	return _paint_tiles(source, coordinates, PaintOperation.HEIGHT, height)

func _paint_tiles(
	source: AonwMapSource,
	coordinates: Array[Vector2i],
	operation: int,
	value: Variant,
) -> Dictionary:
	if coordinates.is_empty():
		return _failure("logical paint stroke has no tiles")
	var documents := _documents(source)
	if not documents["ok"]:
		return documents
	var map_document: String = documents["map"]
	var profile_document: String = documents["profile"]
	var final_result: Dictionary
	for coordinate in coordinates:
		final_result = _apply_operation(
			map_document,
			profile_document,
			coordinate,
			operation,
			value,
		)
		if not final_result["ok"]:
			return final_result
		map_document = final_result["update"]["mapDocument"]
		profile_document = final_result["update"]["terrainAuthoringDocument"]
	return _persist_update(source, documents, final_result)

func _apply_operation(
	map_document: String,
	profile_document: String,
	coordinate: Vector2i,
	operation: int,
	value: Variant,
) -> Dictionary:
	match operation:
		PaintOperation.TERRAIN:
			return _workbench.set_tile_terrain(
				map_document,
				profile_document,
				coordinate,
				StringName(value),
			)
		PaintOperation.RESOURCES:
			var resources: Array[StringName] = []
			for resource in value:
				resources.append(StringName(resource))
			return _workbench.set_tile_resources(
				map_document,
				profile_document,
				coordinate,
				resources,
			)
		PaintOperation.HEIGHT:
			return _workbench.set_tile_height(
				map_document,
				profile_document,
				coordinate,
				int(value),
			)
	return _failure("logical paint operation is unsupported")

func _documents(source: AonwMapSource) -> Dictionary:
	if source.origin != "content":
		return _failure("only canonical content maps can be edited")
	var map_result := _read_text(source.map_path)
	if not map_result["ok"]:
		return map_result
	var profile_path := _profile_path(source)
	var profile_result := _read_text(profile_path)
	if not profile_result["ok"]:
		return profile_result
	return {
		"ok": true,
		"map": map_result["content"],
		"profile": profile_result["content"],
		"profile_path": profile_path,
	}

func _persist_update(
	source: AonwMapSource,
	documents: Dictionary,
	result: Dictionary,
) -> Dictionary:
	if not result["ok"]:
		return result
	var update: Dictionary = result["update"]
	var map_error := _atomic_store.write_text(source.map_path, update["mapDocument"])
	if map_error != OK:
		return _failure("cannot save logical map: %s" % error_string(map_error))
	var profile_error := _atomic_store.write_text(
		documents["profile_path"],
		update["terrainAuthoringDocument"],
	)
	if profile_error != OK:
		var map_rollback := _atomic_store.write_text(source.map_path, documents["map"])
		return _failure(_rollback_message(
			"cannot save terrain authoring profile: %s" % error_string(profile_error),
			map_rollback,
		))
	var compiled := _compiler.compile_profiles()
	if compiled["ok"]:
		return {"ok": true, "update": update}
	var map_rollback := _atomic_store.write_text(source.map_path, documents["map"])
	var profile_rollback := _atomic_store.write_text(
		documents["profile_path"],
		documents["profile"],
	)
	var rollback_compile := _compiler.compile_profiles()
	var message: String = compiled["message"]
	for rollback in [map_rollback, profile_rollback]:
		if rollback != OK:
			message += "; document rollback failed: %s" % error_string(rollback)
	if not rollback_compile["ok"]:
		message += "; artifact rollback failed: %s" % rollback_compile["message"]
	return _failure(message)

func _rollback_message(message: String, rollback: Error) -> String:
	if rollback == OK:
		return message
	return "%s; map rollback failed: %s" % [message, error_string(rollback)]

func _profile_path(source: AonwMapSource) -> String:
	return source.map_path.get_base_dir().path_join("terrain_authoring.json")

func _read_text(path: String) -> Dictionary:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.READ)
	if file == null:
		return _failure("cannot open %s" % path)
	return {"ok": true, "content": file.get_as_text()}

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
