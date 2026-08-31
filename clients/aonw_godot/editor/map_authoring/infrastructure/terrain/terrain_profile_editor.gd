@tool
class_name AonwFilesystemTerrainProfileEditor
extends AonwTerrainProfileEditor

const AtomicResourceStore := preload(
	"res://editor/map_authoring/infrastructure/atomic_resource_store.gd"
)
const TerrainCompiler := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_compiler.gd"
)

var _workbench: AonwLogicalMapWorkbench
var _atomic_store := AtomicResourceStore.new()
var _compiler := TerrainCompiler.new()

func _init(workbench: AonwLogicalMapWorkbench) -> void:
	assert(workbench != null, "Logical map workbench is required")
	_workbench = workbench

func current_maximum(source: AonwMapSource) -> Dictionary:
	var profile_result := _read_text(_profile_path(source))
	if not profile_result["ok"]:
		return profile_result
	var parsed: Variant = JSON.parse_string(profile_result["content"])
	if parsed is not Dictionary:
		return _failure("terrain authoring profile is not valid JSON")
	var value: Variant = parsed.get("maxTerrainHeightMeters")
	if value is not float or not is_finite(value) or value <= 0.0:
		return _failure("terrain authoring profile has no valid maxTerrainHeightMeters")
	return {"ok": true, "max_terrain_height_meters": value}

func update_maximum(source: AonwMapSource, maximum: float) -> Dictionary:
	if source.origin != "content":
		return _failure("only canonical content maps can be edited")
	var map_result := _read_text(source.map_path)
	if not map_result["ok"]:
		return map_result
	var profile_path := _profile_path(source)
	var profile_result := _read_text(profile_path)
	if not profile_result["ok"]:
		return profile_result
	var update_result := _workbench.reconfigure_terrain_height(
		map_result["content"],
		profile_result["content"],
		maximum,
	)
	if not update_result["ok"]:
		return update_result
	var update: Dictionary = update_result["update"]
	var write_error := _atomic_store.write_text(
		profile_path,
		update["terrainAuthoringDocument"],
	)
	if write_error != OK:
		return _failure("cannot save terrain authoring profile: %s" % error_string(write_error))
	var compile_result := _compiler.compile_profiles()
	if compile_result["ok"]:
		return {
			"ok": true,
			"max_terrain_height_meters": update["maxTerrainHeightMeters"],
			"authoring_profile_hash": update["authoringProfileHash"],
		}
	var rollback_error := _atomic_store.write_text(profile_path, profile_result["content"])
	if rollback_error != OK:
		return _failure(
			"%s; profile rollback also failed: %s" % [
				compile_result["message"],
				error_string(rollback_error),
			]
		)
	return compile_result

func _profile_path(source: AonwMapSource) -> String:
	return source.map_path.get_base_dir().path_join("terrain_authoring.json")

func _read_text(path: String) -> Dictionary:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.READ)
	if file == null:
		return _failure("cannot open %s" % path)
	return {"ok": true, "content": file.get_as_text()}

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
