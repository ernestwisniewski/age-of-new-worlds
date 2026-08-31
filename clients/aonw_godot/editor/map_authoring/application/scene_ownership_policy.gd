@tool
class_name AonwSceneOwnershipPolicy
extends RefCounted

const TERRAIN_PATH := "Terrain3D"
const MANUAL_WORLD_PATH := "ManualWorld"

func apply(scene_root: Node, surface: Node) -> Array[String]:
	assert(scene_root != null, "Scene root is required")
	assert(surface != null, "Terrain authoring surface is required")
	var changed: Array[String] = []
	_set_owner(surface, scene_root, scene_root, changed)
	for node in _descendants(surface):
		var relative_path := String(surface.get_path_to(node))
		var expected_owner: Node = scene_root if is_persistent_path(relative_path) else null
		_set_owner(node, expected_owner, scene_root, changed)
	return changed

func is_persistent_path(relative_path: String) -> bool:
	return (
		relative_path == TERRAIN_PATH
		or relative_path == MANUAL_WORLD_PATH
		or relative_path.begins_with("%s/" % MANUAL_WORLD_PATH)
	)

func persistent_identities(scene_root: Node, surface: Node) -> Array[String]:
	var identities: Array[String] = []
	for node in [scene_root] + _descendants(scene_root):
		if node != scene_root and node.owner == null:
			continue
		if node != surface and surface.is_ancestor_of(node):
			var relative_path := String(surface.get_path_to(node))
			if not is_persistent_path(relative_path):
				continue
		identities.append("%s|%s" % [scene_root.get_path_to(node), node.get_class()])
	identities.sort()
	return identities

func transient_owned_paths(scene_root: Node, surface: Node) -> Array[String]:
	var paths: Array[String] = []
	for node in _descendants(surface):
		var relative_path := String(surface.get_path_to(node))
		if node.owner != null and not is_persistent_path(relative_path):
			paths.append(String(scene_root.get_path_to(node)))
	paths.sort()
	return paths

func _set_owner(
	node: Node,
	expected_owner: Node,
	scene_root: Node,
	changed: Array[String],
) -> void:
	if node.owner == expected_owner:
		return
	node.owner = expected_owner
	changed.append(String(scene_root.get_path_to(node)))

func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	var pending: Array[Node] = []
	for child in root.get_children(true):
		pending.append(child)
	while not pending.is_empty():
		var node: Node = pending.pop_front()
		result.append(node)
		for child in node.get_children(true):
			pending.append(child)
	return result
