class_name AonwGeneratedWorldBuilder
extends RefCounted

const TerrainSpaceTransform := preload(
	"res://game/application/terrain/terrain_space_transform.gd"
)

func rebuild(
	root: Node3D,
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	placements: Array,
) -> void:
	_clear(root)
	var grouped := {}
	for placement in placements:
		var kind: String = placement["kind"]
		if not grouped.has(kind):
			grouped[kind] = []
		grouped[kind].append(placement)
	for kind in grouped:
		root.add_child(_multi_mesh(kind, grouped[kind], artifact, data))

func _multi_mesh(
	kind: String,
	placements: Array,
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
) -> MultiMeshInstance3D:
	var instance := MultiMeshInstance3D.new()
	instance.name = "%sInstances" % kind.capitalize()
	instance.set_meta(&"aonw_generated", true)
	instance.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if kind == "water"
		else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	)
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = _mesh(kind)
	multi_mesh.instance_count = placements.size()
	var space := TerrainSpaceTransform.new(artifact)
	for index in placements.size():
		multi_mesh.set_instance_transform(
			index,
			_placement_transform(kind, placements[index], artifact, data, space),
		)
	instance.multimesh = multi_mesh
	return instance

func _placement_transform(
	kind: String,
	placement: Dictionary,
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	space: AonwTerrainSpaceTransform,
) -> Transform3D:
	var local := space.logical_to_terrain_local(Vector2(
		placement["xMeters"],
		placement["zMeters"],
	))
	var terrain_height := data.get_height(local)
	local.y = placement["yMeters"] if not is_finite(terrain_height) else terrain_height
	var authored_scale: float = placement["scale"]
	var metric_scale := clampf(artifact.hex_radius_meters * 0.12, 0.5, 8.0)
	var scale := _scale(kind, authored_scale, metric_scale)
	local.y += _base_offset(kind) * scale.y
	var rotation := Basis(Vector3.UP, deg_to_rad(placement["rotationDegreesY"]))
	return Transform3D(rotation.scaled(scale), local)

func _scale(kind: String, authored: float, metric: float) -> Vector3:
	match kind:
		"rock":
			return Vector3(1.2, 0.7, 1.0) * authored * metric
		"water":
			return Vector3(0.75, 1.0, 0.75) * authored * metric
		"detail":
			return Vector3(0.7, 0.45, 0.7) * authored * metric
	return Vector3.ONE * authored * metric

func _base_offset(kind: String) -> float:
	match kind:
		"tree":
			return 1.25
		"rock":
			return 0.5
		"detail":
			return 0.35
	return 0.02

func _mesh(kind: String) -> PrimitiveMesh:
	var mesh: PrimitiveMesh
	match kind:
		"tree":
			var tree := CylinderMesh.new()
			tree.top_radius = 0.0
			tree.bottom_radius = 0.7
			tree.height = 2.5
			tree.radial_segments = 8
			mesh = tree
		"rock":
			var rock := SphereMesh.new()
			rock.radius = 0.8
			rock.height = 1.6
			rock.radial_segments = 8
			rock.rings = 4
			mesh = rock
		"water":
			var water := PlaneMesh.new()
			water.size = Vector2(2.0, 2.0)
			mesh = water
		_:
			var detail := BoxMesh.new()
			detail.size = Vector3(0.7, 0.7, 0.7)
			mesh = detail
	mesh.material = _material(kind)
	return mesh

func _material(kind: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.roughness = 0.9
	match kind:
		"tree":
			material.albedo_color = Color(0.12, 0.42, 0.16)
		"rock":
			material.albedo_color = Color(0.32, 0.30, 0.28)
		"water":
			material.albedo_color = Color(0.08, 0.35, 0.62, 0.58)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_:
			material.albedo_color = Color(0.62, 0.52, 0.20)
	return material

func _clear(root: Node3D) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.free()
