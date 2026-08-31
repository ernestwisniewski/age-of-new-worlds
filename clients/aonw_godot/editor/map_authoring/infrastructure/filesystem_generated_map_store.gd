@tool
class_name AonwFilesystemGeneratedMapStore
extends AonwGeneratedMapStore

const MapSource := preload("res://game/application/map/map_source.gd")

const DEFAULT_CONTENT_ROOT := "res://../../content/maps"
const DEFAULT_VISUAL_ROOT := "res://../../assets/runtime/maps"
const DOCUMENT_FIELDS := {
	"map.json": "mapDocument",
	"terrain_authoring.json": "terrainAuthoringDocument",
	"map_generation.json": "generationDocument",
	"generated_decorations.json": "generatedDecorationPlanDocument",
}

var _compiler: AonwTerrainCompiler
var _content_root: String
var _visual_root: String

func _init(
	compiler: AonwTerrainCompiler,
	content_root: String = DEFAULT_CONTENT_ROOT,
	visual_root: String = DEFAULT_VISUAL_ROOT,
) -> void:
	assert(compiler != null, "Terrain compiler is required")
	_compiler = compiler
	_content_root = content_root
	_visual_root = visual_root

func create(map_id: String, package: Dictionary) -> Dictionary:
	if not _is_safe_path_segment(map_id):
		return _failure("generated map id is not a safe directory name")
	var package_error := _package_error(package)
	if not package_error.is_empty():
		return _failure(package_error)
	var root_absolute := _absolute(_content_root)
	var target_path := _content_root.path_join(map_id)
	var target_absolute := _absolute(target_path)
	if DirAccess.dir_exists_absolute(target_absolute) or FileAccess.file_exists(target_absolute):
		return _failure("map already exists: %s" % map_id)
	var root_error := DirAccess.make_dir_recursive_absolute(root_absolute)
	if root_error != OK:
		return _failure("cannot create map content root: %s" % error_string(root_error))
	var staging_absolute := root_absolute.path_join(
		".aonw-new-%s-%s" % [map_id, Time.get_ticks_usec()]
	)
	var staging_error := DirAccess.make_dir_absolute(staging_absolute)
	if staging_error != OK:
		return _failure("cannot create map staging directory: %s" % error_string(staging_error))
	for file_name in DOCUMENT_FIELDS:
		var write_error := _write_text(
			staging_absolute.path_join(file_name),
			package[DOCUMENT_FIELDS[file_name]],
		)
		if write_error != OK:
			_remove_tree(staging_absolute)
			return _failure("cannot stage %s: %s" % [file_name, error_string(write_error)])
	var publish_error := DirAccess.rename_absolute(staging_absolute, target_absolute)
	if publish_error != OK:
		_remove_tree(staging_absolute)
		return _failure("cannot publish new map directory: %s" % error_string(publish_error))
	var compiled := _compiler.compile_profiles()
	if not compiled["ok"]:
		return _rollback_failed_compile(map_id, target_absolute, staging_absolute, compiled["message"])
	return {
		"ok": true,
		"source": MapSource.new(
			map_id,
			target_path.path_join("map.json"),
			_visual_root.path_join(map_id),
			"content",
		),
	}

func _rollback_failed_compile(
	map_id: String,
	target_absolute: String,
	staging_absolute: String,
	compile_message: String,
) -> Dictionary:
	var rollback_error := DirAccess.rename_absolute(target_absolute, staging_absolute)
	if rollback_error != OK:
		return _failure(
			"%s; map %s remains on disk because rollback failed: %s"
			% [compile_message, map_id, error_string(rollback_error)]
		)
	var cleanup_error := _remove_tree(staging_absolute)
	if cleanup_error != OK:
		return _failure(
			"%s; hidden staging cleanup failed: %s"
			% [compile_message, error_string(cleanup_error)]
		)
	return _failure("%s; new map was rolled back" % compile_message)

func _package_error(package: Dictionary) -> String:
	for field in DOCUMENT_FIELDS.values():
		if not package.get(field) is String or package[field].is_empty():
			return "generated map package is missing %s" % field
	return ""

func _write_text(path: String, content: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file = null
	return OK

func _remove_tree(path: String) -> Error:
	var directory := DirAccess.open(path)
	if directory == null:
		return DirAccess.get_open_error()
	for file_name in directory.get_files():
		var error := DirAccess.remove_absolute(path.path_join(file_name))
		if error != OK:
			return error
	for directory_name in directory.get_directories():
		var error := _remove_tree(path.path_join(directory_name))
		if error != OK:
			return error
	directory = null
	return DirAccess.remove_absolute(path)

func _absolute(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path).simplify_path()
	return path.simplify_path()

func _is_safe_path_segment(value: String) -> bool:
	return (
		not value.is_empty()
		and value.length() <= 64
		and value != "."
		and value != ".."
		and not value.contains("/")
		and not value.contains("\\")
	)

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
