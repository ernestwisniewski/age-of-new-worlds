@tool
extends AonwTerrainAuthoringSceneFactory

const Template := preload("res://scenes/terrain_authoring/reference_terrain.tscn")

func create_scene(map_id: String, compiled_artifact_directory: String, authoring_root: String) -> PackedScene:
	var root := Template.instantiate()
	root.name = map_id
	root.source_map_id = map_id
	root.compiled_artifact_directory = compiled_artifact_directory
	root.authoring_root = authoring_root
	# No _ready() runs outside the tree: derived meshes/regions are never packed.
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		packed = null
	root.free()
	return packed
