@tool
extends "res://editor/map_authoring/infrastructure/terrain/terrain_authoring_scene_repository.gd"
## Existing canonical scenes are intentionally not rewritten or silently migrated.

func scene_path_for(map_id: String) -> String:
	return _scene_root.path_join("reference_maps").path_join(map_id + ".tscn")

func prepare_scene(map_id: String) -> Dictionary:
	if map_id.is_empty():
		return {"ok": false, "message": "Map ID is empty"}
	for character in map_id:
		if character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-":
			return {"ok": false, "message": "Unsafe map ID"}
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_scene_root.path_join("reference_maps")))
	if error != OK:
		return {"ok": false, "message": "Cannot create reference scene directory: " + error_string(error)}
	return super.prepare_scene(map_id)

func _is_authoring_scene(packed: PackedScene) -> bool:
	var root := packed.instantiate()
	var valid := root is AonwTerrainAuthoringSurface and root.has_method("ensure_reference_session") and root.get_node_or_null("Terrain3D") is Terrain3D
	root.free()
	return valid
