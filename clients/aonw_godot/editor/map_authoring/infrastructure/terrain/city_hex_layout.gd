@tool
extends RefCounted
## Presentation scale and an optional city footprint. Never edits map or terrain data.
## Model metres are deliberately separate from the compressed strategic-map metres.
const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const Space := preload("res://game/application/terrain/terrain_space_transform.gd")
const EXCLUDED := ["ocean", "sea", "lake", "river", "water", "coast", "ice", "glacier"]

static func model_scale(source: AonwTerrainCompiledArtifact, values: Dictionary) -> float:
	return 2.0 * source.hex_radius_meters / float(values["city_hex_diameter"])

static func forest_parameters(source: AonwTerrainCompiledArtifact, values: Dictionary) -> Dictionary:
	var result := values.duplicate()
	if source != null and float(values.get("city_scale_enabled", 0.0)) >= 0.5:
		var factor := model_scale(source, values)
		result["tree_height"] = float(values["city_tree_height"]) * factor
		result["tree_spacing"] = float(values["city_tree_spacing"]) * factor
	return result

static func layout(source: AonwTerrainCompiledArtifact, coordinate: Vector2i,
		values: Dictionary) -> Dictionary:
	var geometry := Geometry.new(source.cols, source.rows, source.hex_radius_meters)
	if not geometry.contains(coordinate):
		return {"ok": false, "message": "Select a city hex inside the map."}
	var radius := source.hex_radius_meters
	var core := radius * float(values["city_core_ratio"])
	var outskirts := radius * float(values["city_outskirts_ratio"])
	if core <= 0.0 or core >= outskirts or outskirts >= radius * sqrt(3.0) * 0.5:
		return {"ok": false, "message": "City zones must fit inside the selected hex."}
	var space := Space.new(source)
	return {"ok": true, "coordinate": coordinate,
		"center": space.logical_to_terrain_local(geometry.tile_center(coordinate)),
		"core_radius": core, "outskirts_radius": outskirts,
		"hex_radius": radius, "model_scale": model_scale(source, values)}

static func prepare(source: AonwTerrainCompiledArtifact, coordinate: Vector2i,
		values: Dictionary, water: Image, data: Object, document: Dictionary) -> Dictionary:
	if float(values.get("city_reserve_enabled", 0.0)) < 0.5:
		return {} # A map is not a grid of empty circular building plots.
	var site := layout(source, coordinate, values)
	if not site["ok"]:
		return site
	for tile in document.get("tiles", []):
		if Vector2i(int(tile["col"]), int(tile["row"])) == coordinate:
			for tag in tile.get("terrainTags", []):
				if tag in EXCLUDED:
					return {"ok": false, "message": "City preview needs a land hex, not water or ice."}
	var validation := validate_core(site, source, water, data)
	if not validation["ok"]:
		return validation
	var center: Vector3 = site["center"]
	center.y = float(validation["height"])
	site["center"] = center
	site["height_range"] = validation["height_range"]
	return site

static func validate_core(site: Dictionary, source: AonwTerrainCompiledArtifact,
		water: Image, data: Object) -> Dictionary:
	if water == null or water.is_compressed() or water.get_size() != Vector2i(source.width, source.height):
		return {"ok": false, "message": "City preview needs the current decoded water mask."}
	var center: Vector3 = site["center"]
	var radius: float = site["core_radius"]
	var spacing := source.sample_spacing_meters
	var space := Space.new(source)
	var first := Vector2i(floori((center.x - radius) / spacing), floori((center.z - radius) / spacing))
	var last := Vector2i(ceili((center.x + radius) / spacing), ceili((center.z + radius) / spacing))
	if (last.x - first.x + 1) * (last.y - first.y + 1) > 65536:
		return {"ok": false, "message": "City footprint exceeds the preview sampling budget."}
	var minimum := INF
	var maximum := -INF
	var grade := 0.35 if source.max_city_slope == null else float(source.max_city_slope)
	if not is_finite(grade) or grade <= 0.0:
		return {"ok": false, "message": "City preview slope limit must be finite and positive."}
	# Include every raster cell touching the core, not just its centre or four corners.
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var point := space.raster_pixel_to_terrain_local(Vector2i(x, y))
			if Vector2(point.x - center.x, point.z - center.z).length() > radius + spacing * 0.707107:
				continue
			if not source.contains_pixel(Vector2i(x, y)) or water.get_pixel(x, y).r >= 0.5:
				return {"ok": false, "message": "City core intersects water or the map boundary; choose another hex."}
			var h: float = data.call("get_height", point)
			var hx: float = data.call("get_height", point + Vector3(spacing, 0, 0))
			var hz: float = data.call("get_height", point + Vector3(0, 0, spacing))
			if not is_finite(h) or not is_finite(hx) or not is_finite(hz):
				return {"ok": false, "message": "City core has missing native terrain samples."}
			if Vector2(hx - h, hz - h).length() / spacing > grade:
				return {"ok": false, "message": "City core is too steep; sculpt it or choose another hex. No heights were changed."}
			minimum = minf(minimum, h)
			maximum = maxf(maximum, h)
	var center_height: float = data.call("get_height", center)
	if not is_finite(center_height):
		return {"ok": false, "message": "City centre has no native terrain height."}
	return {"ok": true, "height": center_height, "height_range": Vector2(minimum, maximum)}

static func vegetation_weight(site: Dictionary, position: Vector3, footprint_radius: float) -> float:
	if not bool(site.get("ok", false)):
		return 1.0
	var center: Vector3 = site["center"]
	var distance := Vector2(position.x - center.x, position.z - center.z).length() - footprint_radius
	# Clear the entire crown/rock footprint from the future building core.
	return smoothstep(float(site["core_radius"]), float(site["outskirts_radius"]), distance)

static func accepts_vegetation(site: Dictionary, position: Vector3, footprint_radius: float) -> bool:
	var weight := vegetation_weight(site, position, footprint_radius)
	if weight >= 1.0:
		return true
	if weight <= 0.0:
		return false
	# A separate stream: adding/removing a city never reshuffles the rest of the forest.
	var random := RandomNumberGenerator.new()
	random.seed = ("city-edge:%.6f:%.6f" % [position.x, position.z]).hash()
	return random.randf() < weight
