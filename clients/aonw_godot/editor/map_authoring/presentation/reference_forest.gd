@tool
extends RefCounted
## Derived, ownerless, chunked MultiMeshes. ManualWorld and Terrain3D regions are untouched.
const Library := preload("res://editor/map_authoring/presentation/reference_tree_library.gd")
const CityLayout := preload("res://editor/map_authoring/infrastructure/terrain/city_hex_layout.gd")
const CHUNK_SIZE := 128.0

func build(candidates: Array, data: Object, sample_spacing: float, parameters: Dictionary, city_site: Dictionary = {}) -> Dictionary:
	var library := Library.load_library()
	if not library["ok"]:
		return library
	var root := Node3D.new()
	root.name = "ReferenceForest"
	root.set_meta(&"aonw_generated", true)
	var groups := {}
	var crown_radii := {}
	if bool(city_site.get("ok", false)):
		for key in library["prototypes"]:
			crown_radii[key] = prototype_radius(library["prototypes"][key])
	var count := 0
	var minimum_up := cos(deg_to_rad(float(parameters["tree_max_slope"])))
	for candidate in candidates:
		var local: Vector3 = candidate["position"]
		var prototype_id := int(candidate["species"]) * 2 + int(candidate["variant"])
		if crown_radii.has(prototype_id):
			var height := float(parameters["tree_height"]) * float(candidate["scale"])
			if not CityLayout.accepts_vegetation(city_site, local, float(crown_radii[prototype_id]) * height):
				continue
		var ground := ground_sample(data, local, sample_spacing)
		if not ground["ok"] or float(ground["up"]) < minimum_up:
			continue
		local.y = float(ground["height"]) - 0.03
		var key := Vector3i(floori(local.x / CHUNK_SIZE), floori(local.z / CHUNK_SIZE), int(candidate["species"]) * 2 + int(candidate["variant"]))
		if not groups.has(key):
			groups[key] = []
		var entry: Dictionary = candidate.duplicate()
		entry["position"] = local
		groups[key].append(entry)
		count += 1
	for key in groups:
		var prototype: Dictionary = library["prototypes"][key.z]
		var placements: Array = groups[key]
		for part in prototype["parts"]:
			var instance := MultiMeshInstance3D.new()
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.use_custom_data = true
			multi.mesh = part["mesh"]
			multi.instance_count = placements.size()
			# Chunk-relative transforms produce useful culling bounds on large maps.
			instance.position = Vector3(key.x * CHUNK_SIZE, 0.0, key.y * CHUNK_SIZE)
			for i in placements.size():
				var placement: Dictionary = placements[i]
				var scale_value := float(parameters["tree_height"]) * float(placement["scale"]) / float(prototype["height"])
				var position: Vector3 = placement["position"] - instance.position
				position.y -= float(prototype["base_y"]) * scale_value
				var basis := Basis(Vector3.UP, float(placement["yaw"])).scaled(Vector3.ONE * scale_value)
				multi.set_instance_transform(i, Transform3D(basis, position) * part["transform"])
				multi.set_instance_custom_data(i, placement["tint"])
			instance.multimesh = multi
			instance.material_override = part["material"]
			instance.visibility_range_end = float(parameters["tree_draw_distance"])
			instance.visibility_range_end_margin = 40.0
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(instance)
	return {"ok": true, "root": root, "count": count, "batches": root.get_child_count()}

static func ground_sample(data: Object, local: Vector3, spacing: float) -> Dictionary:
	var step := maxf(spacing, 0.1)
	var height: float = data.call("get_height", local)
	var left: float = data.call("get_height", local - Vector3(step, 0.0, 0.0))
	var right: float = data.call("get_height", local + Vector3(step, 0.0, 0.0))
	var back: float = data.call("get_height", local - Vector3(0.0, 0.0, step))
	var front: float = data.call("get_height", local + Vector3(0.0, 0.0, step))
	for value in [height, left, right, back, front]:
		if not is_finite(value):
			return {"ok": false}
	var normal := Vector3(left - right, 2.0 * step, back - front).normalized()
	return {"ok": true, "height": height, "up": normal.y}

static func prototype_radius(prototype: Dictionary) -> float:
	# Conservative circumscribed horizontal radius per unit height, including
	# internal mesh offsets. Remains valid for every random Y rotation.
	var radius := 0.0
	for part in prototype["parts"]:
		var mesh: Mesh = part["mesh"]
		var bounds: AABB = part["transform"] * mesh.get_aabb()
		var x := maxf(absf(bounds.position.x), absf(bounds.end.x))
		var z := maxf(absf(bounds.position.z), absf(bounds.end.z))
		radius = maxf(radius, Vector2(x, z).length())
	return radius / maxf(float(prototype["height"]), 0.001)
