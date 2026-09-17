@tool
extends RefCounted
## Derived, ownerless, chunked MultiMeshes. ManualWorld and Terrain3D regions are untouched.
const Library := preload("res://editor/map_authoring/presentation/reference_tree_library.gd")
const CityLayout := preload("res://editor/map_authoring/infrastructure/terrain/city_hex_layout.gd")
const CHUNK_SIZE := 64.0

var _ground_cache: Dictionary = {}
var _cache_spacing := -1.0
var height_sample_calls := 0

func build(candidates: Array, data: Object, sample_spacing: float, parameters: Dictionary, city_site: Dictionary = {}) -> Dictionary:
	if not is_equal_approx(sample_spacing, _cache_spacing):
		clear_ground_cache()
		_cache_spacing = sample_spacing
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
		var point := Vector2(local.x, local.z)
		if not _ground_cache.has(point):
			_ground_cache[point] = ground_sample(data, local, sample_spacing)
			height_sample_calls += 5
		var ground: Dictionary = _ground_cache[point]
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
	var render_groups: Array = []
	for key in groups:
		var prototype: Dictionary = library["prototypes"][key.z]
		var placements: Array = groups[key]
		# Stable spatially distributed prefixes for an editor draw budget. Never
		# choose the first rows of a chunk or change the generated candidate set.
		placements.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("priority", 0.0)) < float(b.get("priority", 0.0)))
		var group := {"count": placements.size(), "nodes": []}
		for part in prototype["parts"]:
			var instance := MultiMeshInstance3D.new()
			var multi := MultiMesh.new()
			multi.transform_format = MultiMesh.TRANSFORM_3D
			multi.use_custom_data = true
			multi.mesh = part["mesh"]
			multi.instance_count = placements.size()
			# Chunk-relative transforms produce useful culling bounds on large maps.
			instance.position = Vector3(key.x * CHUNK_SIZE, 0.0, key.y * CHUNK_SIZE)
			# A single buffer upload replaces two RenderingServer calls per tree/part.
			multi.buffer = instance_buffer(placements, prototype, part, instance.position, float(parameters["tree_height"]))
			instance.multimesh = multi
			instance.material_override = part["material"]
			instance.set_meta(&"full_material", part["material"])
			instance.visibility_range_end = float(parameters["tree_draw_distance"])
			instance.visibility_range_end_margin = 40.0
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(instance)
			group["nodes"].append(instance)
		render_groups.append(group)
	root.set_meta(&"forest_groups", render_groups)
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

func clear_ground_cache() -> void:
	_ground_cache.clear()

func invalidate_ground(changed_pixels: Rect2i, spacing: float) -> void:
	if not changed_pixels.has_area():
		return
	# Include the left/right/front/back slope samples and interpolation support.
	var rect := Rect2(Vector2(changed_pixels.position) * spacing,
		Vector2(changed_pixels.size) * spacing).grow(maxf(spacing, 0.1) * 2.0)
	for point in _ground_cache.keys():
		if rect.has_point(point):
			_ground_cache.erase(point)

static func instance_buffer(placements: Array, prototype: Dictionary, part: Dictionary,
		origin: Vector3, tree_height: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(placements.size() * 16) # 3x4 row-major transform + RGBA custom data.
	for i in placements.size():
		var placement: Dictionary = placements[i]
		var scale_value := tree_height * float(placement["scale"]) / float(prototype["height"])
		var position: Vector3 = placement["position"] - origin
		position.y -= float(prototype["base_y"]) * scale_value
		var basis := Basis(Vector3.UP, float(placement["yaw"])).scaled(Vector3.ONE * scale_value)
		var transform: Transform3D = Transform3D(basis, position) * part["transform"]
		var tint: Color = placement["tint"]
		var offset := i * 16
		result[offset] = transform.basis.x.x
		result[offset + 1] = transform.basis.y.x
		result[offset + 2] = transform.basis.z.x
		result[offset + 3] = transform.origin.x
		result[offset + 4] = transform.basis.x.y
		result[offset + 5] = transform.basis.y.y
		result[offset + 6] = transform.basis.z.y
		result[offset + 7] = transform.origin.y
		result[offset + 8] = transform.basis.x.z
		result[offset + 9] = transform.basis.y.z
		result[offset + 10] = transform.basis.z.z
		result[offset + 11] = transform.origin.z
		result[offset + 12] = tint.r
		result[offset + 13] = tint.g
		result[offset + 14] = tint.b
		result[offset + 15] = tint.a
	return result
