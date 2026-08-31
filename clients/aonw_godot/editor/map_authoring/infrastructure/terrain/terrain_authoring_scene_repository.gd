@tool
class_name AonwTerrainAuthoringSceneRepository
extends AonwTerrainAuthoringSceneWriter

const AtomicResourceStore := preload(
	"res://editor/map_authoring/infrastructure/atomic_resource_store.gd"
)
const SCENE_ROOT := "res://scenes/terrain_authoring"
const AUTHORING_ASSET_ROOT := "res://assets/generated_maps"
const COMPILED_ARTIFACT_ROOT := "res://.godot/terrain_compiled"

var _scene_root: String
var _authoring_asset_root: String
var _compiled_artifact_root: String
var _scene_factory: AonwTerrainAuthoringSceneFactory
var _atomic_store := AtomicResourceStore.new()

func _init(
	scene_factory: AonwTerrainAuthoringSceneFactory,
	scene_root: String = SCENE_ROOT,
	authoring_asset_root: String = AUTHORING_ASSET_ROOT,
	compiled_artifact_root: String = COMPILED_ARTIFACT_ROOT,
) -> void:
	assert(scene_factory != null, "Terrain authoring scene factory is required")
	_scene_factory = scene_factory
	_scene_root = scene_root
	_authoring_asset_root = authoring_asset_root
	_compiled_artifact_root = compiled_artifact_root

func scene_path_for(map_id: String) -> String:
	return _scene_root.path_join("%s.tscn" % map_id)

func authoring_root_for(map_id: String) -> String:
	return _authoring_asset_root.path_join(map_id).path_join("terrain_authoring")

func compiled_artifact_directory_for(map_id: String) -> String:
	return _compiled_artifact_root.path_join(map_id)

func prepare_scene(map_id: String) -> Dictionary:
	var scene_path := scene_path_for(map_id)
	if FileAccess.file_exists(scene_path):
		var existing_scene := ResourceLoader.load(
			scene_path,
			"PackedScene",
			ResourceLoader.CACHE_MODE_REPLACE_DEEP,
		) as PackedScene
		if existing_scene == null:
			return _failure("existing Terrain3D authoring scene cannot be loaded")
		if _is_authoring_scene(existing_scene):
			return _preserve_existing_scene(scene_path)
		return _failure("existing scene is not a Terrain3D authoring scene")
	var root_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_scene_root)
	)
	if root_error != OK:
		return _failure("cannot create terrain scene directory: %s" % error_string(root_error))
	var packed := _scene_factory.create_scene(
		map_id,
		compiled_artifact_directory_for(map_id),
		authoring_root_for(map_id),
	)
	if packed == null:
		return _failure("cannot build Terrain3D authoring scene")
	var pack_error := _atomic_store.save_scene(packed, scene_path)
	if pack_error != OK:
		return _failure("cannot save Terrain3D authoring scene: %s" % error_string(pack_error))
	return {
		"ok": true,
		"scene_path": scene_path,
		"scene_created": true,
	}

func _is_authoring_scene(packed: PackedScene) -> bool:
	var root := packed.instantiate()
	var surface := root.find_child("TerrainAuthoring", true, false)
	var valid := surface != null and surface.get_node_or_null("Terrain3D") is Terrain3D
	root.free()
	return valid

func _preserve_existing_scene(scene_path: String) -> Dictionary:
	return {
		"ok": true,
		"scene_path": scene_path,
		"scene_created": false,
	}

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
