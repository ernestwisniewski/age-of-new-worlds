extends RefCounted

const CreateLogicalMap := preload(
	"res://editor/map_authoring/application/create_logical_map.gd"
)
const FilesystemGeneratedMapStore := preload(
	"res://editor/map_authoring/infrastructure/filesystem_generated_map_store.gd"
)
const EngineLogicalMapWorkbench := preload(
	"res://editor/map_authoring/infrastructure/engine_logical_map_workbench.gd"
)

class FakeTerrainCompiler:
	extends AonwTerrainCompiler

	var succeeds: bool
	var calls := 0

	func _init(should_succeed: bool) -> void:
		succeeds = should_succeed

	func compile_profiles() -> Dictionary:
		calls += 1
		return (
			{"ok": true}
			if succeeds
			else {"ok": false, "message": "fixture compilation failed"}
		)

var _failures: Array[String]
var _test_root: String

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_root = "res://.godot/new_map_creation_test/%s" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_root))
	_test_successful_creation_is_complete_and_immutable()
	_test_procedural_creation_persists_engine_output()
	_test_compile_failure_removes_the_new_map()

func _test_successful_creation_is_complete_and_immutable() -> void:
	var compiler := FakeTerrainCompiler.new(true)
	var creator := _creator(compiler)
	var result := creator.execute("new_world", 5, 6, 1.0, 10.0, 25.0, "42")
	_check(result["ok"], "New Map persists the package returned by Engine")
	if not result["ok"]:
		return
	var map_root := _test_root.path_join("content/new_world")
	for file_name in [
		"map.json",
		"terrain_authoring.json",
		"map_generation.json",
		"generated_decorations.json",
	]:
		_check(
			FileAccess.file_exists(map_root.path_join(file_name)),
			"New Map writes %s" % file_name,
		)
	var original_map := _read_text(map_root.path_join("map.json"))
	var duplicate := creator.execute("new_world", 5, 6, 1.0, 10.0, 25.0, "42")
	_check(not duplicate["ok"], "New Map refuses to overwrite an existing map")
	_check(
		_read_text(map_root.path_join("map.json")) == original_map,
		"duplicate New Map leaves the existing canonical map unchanged",
	)
	_check(compiler.calls == 1, "duplicate New Map does not recompile Terrain3D")

func _test_compile_failure_removes_the_new_map() -> void:
	var compiler := FakeTerrainCompiler.new(false)
	var result := _creator(compiler).execute(
		"compile_failure",
		5,
		5,
		1.0,
		10.0,
		20.0,
		"7",
	)
	_check(not result["ok"], "New Map reports Terrain3D compilation failure")
	var content_root := _test_root.path_join("content")
	_check(
		not DirAccess.dir_exists_absolute(
			ProjectSettings.globalize_path(content_root.path_join("compile_failure"))
		),
		"failed New Map does not leave a canonical map directory",
	)
	var directory := DirAccess.open(content_root)
	var has_staging := false
	if directory != null:
		for directory_name in directory.get_directories():
			has_staging = has_staging or directory_name.begins_with(".aonw-new-")
	_check(not has_staging, "failed New Map cleans its hidden staging directory")

func _test_procedural_creation_persists_engine_output() -> void:
	var compiler := FakeTerrainCompiler.new(true)
	var result := _creator(compiler).execute(
		"procedural_world",
		40,
		30,
		1.0,
		100.0,
		240.0,
		"42",
		&"continental",
	)
	_check(result["ok"], "New Map persists the selected Engine procedural generator")
	if not result["ok"]:
		return
	var map_root := _test_root.path_join("content/procedural_world")
	var map: Dictionary = JSON.parse_string(_read_text(map_root.path_join("map.json")))
	var plan: Dictionary = JSON.parse_string(
		_read_text(map_root.path_join("generated_decorations.json"))
	)
	var terrains := {}
	var resource_tiles := 0
	for tile in map["tiles"]:
		terrains[tile["terrainTags"][0]] = true
		resource_tiles += 1 if not tile["resources"].is_empty() else 0
	_check(
		terrains.size() >= 5 and resource_tiles >= 20 and plan["placements"].size() >= 100,
		"procedural package retains varied terrain, resources, and generated objects",
	)
	_check(compiler.calls == 1, "procedural map compiles Terrain3D exactly once")

func _creator(compiler: AonwTerrainCompiler) -> AonwCreateLogicalMap:
	var store := FilesystemGeneratedMapStore.new(
		compiler,
		_test_root.path_join("content"),
		_test_root.path_join("visuals"),
	)
	return CreateLogicalMap.new(EngineLogicalMapWorkbench.new(), store)

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
