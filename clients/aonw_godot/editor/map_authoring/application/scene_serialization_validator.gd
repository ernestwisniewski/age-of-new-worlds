@tool
class_name AonwSceneSerializationValidator
extends RefCounted

const Problem := preload(
	"res://editor/map_authoring/application/scene_safety_problem.gd"
)
const OwnershipPolicy := preload(
	"res://editor/map_authoring/application/scene_ownership_policy.gd"
)
const DANGEROUS_RESOURCE_TYPES := {
	"Image": true,
	"ImageTexture": true,
	"ArrayMesh": true,
	"MultiMesh": true,
}

var _policy := OwnershipPolicy.new()

func validate_scene(scene_root: Node) -> Array:
	var problems: Array = []
	if scene_root == null:
		problems.append(Problem.new(
			&"scene_root_missing",
			"The edited scene has no root and cannot be saved safely.",
		))
		return problems
	var surface := scene_root.find_child("TerrainAuthoring", true, false)
	if surface == null:
		problems.append(Problem.new(
			&"authoring_surface_missing",
			"The edited scene has no TerrainAuthoring surface.",
		))
		return problems
	if surface.owner != scene_root:
		problems.append(Problem.new(
			&"persistent_owner_missing",
			"TerrainAuthoring must be owned by the scene root.",
			String(scene_root.get_path_to(surface)),
		))
	for node in _descendants(surface):
		_validate_node(scene_root, surface, node, problems)
	return problems

func result_for(scene_root: Node) -> Dictionary:
	var problems := validate_scene(scene_root)
	var blocking := problems.filter(func(problem: Variant) -> bool: return problem.blocks_save)
	return {
		"ok": blocking.is_empty(),
		"problems": problems,
		"message": "" if blocking.is_empty() else blocking[0].message,
	}

func _validate_node(
	scene_root: Node,
	surface: Node,
	node: Node,
	problems: Array,
) -> void:
	var relative_path := String(surface.get_path_to(node))
	var scene_path := String(scene_root.get_path_to(node))
	var persistent := _policy.is_persistent_path(relative_path)
	if persistent and node.owner != scene_root:
		problems.append(Problem.new(
			&"persistent_owner_missing",
			"A persistent authoring node would be lost during save.",
			scene_path,
		))
		return
	if persistent or node.owner == null:
		return
	var resource_types := _dangerous_resource_types(node)
	problems.append(Problem.new(
		&"transient_node_owned",
		"A runtime/generated node is owned by the .tscn and would be serialized.",
		scene_path,
		", ".join(resource_types),
	))

func _dangerous_resource_types(node: Node) -> Array[String]:
	var found := {}
	var visited := {}
	for property in node.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_STORAGE == 0:
			continue
		_collect_value(node.get(property["name"]), found, visited, 0)
	var result: Array[String] = []
	for resource_type in found:
		result.append(resource_type)
	result.sort()
	return result

func _collect_value(
	value: Variant,
	found: Dictionary,
	visited: Dictionary,
	depth: int,
) -> void:
	if depth > 4:
		return
	if value is Resource:
		_collect_resource(value, found, visited, depth)
	elif value is Array:
		for entry in value:
			_collect_value(entry, found, visited, depth + 1)
	elif value is Dictionary:
		for entry in value.values():
			_collect_value(entry, found, visited, depth + 1)

func _collect_resource(
	resource: Resource,
	found: Dictionary,
	visited: Dictionary,
	depth: int,
) -> void:
	var identity := resource.get_instance_id()
	if visited.has(identity):
		return
	visited[identity] = true
	var resource_type := resource.get_class()
	if DANGEROUS_RESOURCE_TYPES.has(resource_type) and resource.resource_path.is_empty():
		found[resource_type] = true
	if resource is ImageTexture:
		var image: Image = (resource as ImageTexture).get_image()
		if image != null:
			found["Image"] = true
	for property in resource.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_STORAGE == 0:
			continue
		_collect_value(resource.get(property["name"]), found, visited, depth + 1)

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
