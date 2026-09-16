@tool
extends RefCounted
## Disposable guide and model anchor, NOT a city entity or a terraforming operation.
const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const Space := preload("res://game/application/terrain/terrain_space_transform.gd")

static func build(site: Dictionary, source: AonwTerrainCompiledArtifact, data: Object,
		model: PackedScene = null) -> Dictionary:
	var root := Node3D.new()
	root.name = "CityHexPreview"
	root.set_meta(&"aonw_generated", true)
	if not bool(site.get("ok", false)):
		return {"root": root, "warning": ""}
	var center: Vector3 = site["center"]
	var factor: float = site["model_scale"]
	var anchor := Marker3D.new()
	anchor.name = "CityModelAnchor"
	anchor.position = center + Vector3(0, 0.065, 0)
	anchor.scale = Vector3.ONE * factor
	anchor.set_meta(&"core_radius_model_meters", float(site["core_radius"]) / factor)
	anchor.set_meta(&"outskirts_radius_model_meters", float(site["outskirts_radius"]) / factor)
	root.add_child(anchor)
	var warning := ""
	if model != null:
		var instance := model.instantiate()
		if instance is Node3D:
			anchor.add_child(instance)
		else:
			instance.free()
			warning = "City preview scene must have a Node3D root."
	var guides := Node3D.new()
	guides.name = "FootprintGuides"
	root.add_child(guides)
	var geometry := Geometry.new(source.cols, source.rows, source.hex_radius_meters)
	var space := Space.new(source)
	var points := PackedVector3Array()
	for corner in 7:
		points.append(space.logical_to_terrain_local(geometry.corner_position(site["coordinate"], corner % 6)))
	guides.add_child(_line("CityHex", points, data, Color(0.8, 0.85, 0.9)))
	for zone in [["BuildingCore", site["core_radius"], Color(0.96, 0.7, 0.2)],
			["Outskirts", site["outskirts_radius"], Color(0.3, 0.8, 0.5)]]:
		points = PackedVector3Array()
		for i in 65:
			var angle := TAU * float(i) / 64.0
			points.append(center + Vector3(cos(angle), 0, sin(angle)) * float(zone[1]))
		guides.add_child(_line(zone[0], points, data, zone[2]))
	return {"root": root, "warning": warning}

static func _line(label: String, points: PackedVector3Array, data: Object, color: Color) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	for i in points.size() - 1:
		for point in [points[i], points[i + 1]]:
			var p: Vector3 = point
			var height: float = data.call("get_height", p)
			p.y = (height if is_finite(height) else p.y) + 0.095
			vertices.append(p)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
