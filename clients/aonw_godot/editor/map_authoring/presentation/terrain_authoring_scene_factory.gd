@tool
class_name AonwTerrainAuthoringPresentationSceneFactory
extends AonwTerrainAuthoringSceneFactory

const AuthoringSurface := preload(
	"res://editor/map_authoring/presentation/terrain_authoring_surface.gd"
)
const OwnershipPolicy := preload(
	"res://editor/map_authoring/application/scene_ownership_policy.gd"
)

var _ownership_policy := OwnershipPolicy.new()

func create_scene(
	map_id: String,
	compiled_artifact_directory: String,
	authoring_root: String,
) -> PackedScene:
	var root := Node3D.new()
	root.name = map_id
	var surface := AuthoringSurface.new()
	surface.name = "TerrainAuthoring"
	surface.configure(map_id, compiled_artifact_directory, authoring_root)
	root.add_child(surface)
	_ownership_policy.apply(root, surface)
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		packed = null
	root.free()
	return packed
