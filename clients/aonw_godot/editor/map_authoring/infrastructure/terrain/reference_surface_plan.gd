@tool
extends RefCounted
## Presentation-only biome masks and reproducible forest candidates.
## Never writes logical tiles, heights, native regions or manually placed objects.

const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const Space := preload("res://game/application/terrain/terrain_space_transform.gd")
const Classifier := preload("res://editor/map_authoring/infrastructure/terrain/reference_feature_classifier.gd")
const Hydrology := preload("res://editor/map_authoring/infrastructure/terrain/reference_hydrology.gd")
const WATER := ["ocean", "sea", "lake", "river", "water", "coast"]
const NO_TREES := ["ice", "glacier", "desert", "dunes", "road", "railroad", "city", "settlement"]
const FOREST := ["forest", "jungle", "rainforest", "woodland", "taiga", "boreal", "pine"]
const Patches := preload("res://editor/map_authoring/infrastructure/terrain/forest_patch_field.gd")
const WaterProfile := preload("res://editor/map_authoring/infrastructure/terrain/water_surface_profile.gd")
const MAX_CANDIDATES := 240000
const MAX_TREES := 80000
var forest_statistics: Dictionary = {}
var _context: Image
var _natural_canopy: Image

var _source: AonwTerrainCompiledArtifact
var _reference: Image
var _water: Image
var _guide: Image
var _has_reference := false
var _tiles: Dictionary = {}
var _geometry: AonwHexGridGeometry
var _space: AonwTerrainSpaceTransform
var _canopy: Image
var _palette: Image
var _coverage: Image
var _wet_distance: PackedFloat32Array
var _masks: Dictionary = {}

func configure(source: AonwTerrainCompiledArtifact, reference: Image,
		document: Dictionary, water: Image, has_reference: bool,
		forest_guide: Image = null) -> Dictionary:
	if source == null or reference == null or water == null:
		return {"ok": false, "message": "Missing landscape inputs"}
	if reference.is_empty() or reference.is_compressed() or water.is_compressed():
		return {"ok": false, "message": "Landscape images must be decoded"}
	if water.get_size() != Vector2i(source.width, source.height):
		return {"ok": false, "message": "Water mask and terrain dimensions differ"}
	if forest_guide != null and (forest_guide.is_compressed() or forest_guide.get_size() != reference.get_size()):
		return {"ok": false, "message": "Forest guide must match the decoded reference atlas"}
	if source.width < 2 or source.height < 2 or not is_finite(source.sample_spacing_meters) or source.sample_spacing_meters <= 0.0:
		return {"ok": false, "message": "Invalid landscape raster geometry"}
	if document.get("mapName") != source.map_id or document.get("cols") != source.cols or document.get("rows") != source.rows:
		return {"ok": false, "message": "Landscape map identity mismatch"}
	if document.get("tiles") is not Array or document["tiles"].size() != source.cols * source.rows:
		return {"ok": false, "message": "Landscape tiles must cover the map"}
	_source = source
	_reference = reference
	_water = water
	_guide = forest_guide
	_has_reference = has_reference
	_geometry = Geometry.new(source.cols, source.rows, source.hex_radius_meters)
	_space = Space.new(source)
	_tiles.clear()
	_masks.clear()
	_canopy = null
	for tile in document.get("tiles", []):
		_tiles[Vector2i(int(tile["col"]), int(tile["row"]))] = tile
	return {"ok": true}

func surface_masks(parameters: Dictionary = {}) -> Dictionary:
	var extent := Vector2(_source.width - 1, _source.height - 1) * _source.sample_spacing_meters
	var ratio := minf(1.0, 512.0 / maxf(_source.width, _source.height))
	var size := Vector2i(maxi(2, roundi(_source.width * ratio)), maxi(2, roundi(_source.height * ratio)))
	var ground := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var detail := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var context := Image.create(size.x, size.y, false, Image.FORMAT_L8)
	var bounds := _geometry.bounds()
	for y in size.y:
		for x in size.x:
			var local := Vector3(float(x) / (size.x - 1) * extent.x, 0.0, float(y) / (size.y - 1) * extent.y)
			var tags: Array = _tile(local).get("terrainTags", [])
			var weights := biome_weights(tags)
			ground.set_pixel(x, y, Color(weights[0], weights[1], weights[2], weights[3]))
			detail.set_pixel(x, y, Color(weights[4], weights[5], 0.0, 1.0))
			context.set_pixel(x, y, Color.WHITE if has_tag(tags, FOREST) else Color.BLACK)
	# Smooth semantics in metres, not one constant pixel at every map resolution.
	var small := Vector2i(maxi(2, roundi(extent.x / (_source.hex_radius_meters * 0.8))),
		maxi(2, roundi(extent.y / (_source.hex_radius_meters * 0.8))))
	for image in [ground, detail, context]:
		image.resize(small.x, small.y, Image.INTERPOLATE_BILINEAR)
		image.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	_context = context
	_natural_canopy = Patches.build(context, extent, _source.hex_radius_meters,
		(int(parameters.get("seed", 73129)) ^ _source.map_id.hash()) & 0x7fffffff, parameters)
	var macro: Image = _reference.duplicate()
	macro.clear_mipmaps()
	macro.resize(maxi(2, size.x / 4), maxi(2, size.y / 4), Image.INTERPOLATE_LANCZOS)
	macro.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	_palette = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	_canopy = Image.create(size.x, size.y, false, Image.FORMAT_L8)
	_coverage = Image.create(size.x, size.y, false, Image.FORMAT_L8)
	var strength := float(parameters.get("surface_reference_strength", 0.85)) if _has_reference else 0.0
	var threshold := float(parameters.get("tree_canopy_threshold", 0.3))
	var water_bytes := PackedByteArray()
	water_bytes.resize(_source.width * _source.height)
	for y in _source.height:
		for x in _source.width:
			# Inverted mask: distance inside water to its actual land boundary.
			water_bytes[y * _source.width + x] = int(_water.get_pixel(x, y).r < 0.5)
	_wet_distance = Hydrology.new().distance_to_water(water_bytes, _source.width, _source.height)
	var depth := Image.create(_source.width, _source.height, false, Image.FORMAT_RF)
	for y in _source.height:
		for x in _source.width:
			depth.set_pixel(x, y, Color(_wet_distance[y * _source.width + x] * _source.sample_spacing_meters, 0.0, 0.0))
	for y in size.y:
		for x in size.x:
			var local := Vector3(float(x) / (size.x - 1) * extent.x, 0.0, float(y) / (size.y - 1) * extent.y)
			var uv := _space.terrain_local_to_reference_uv(local, bounds)
			var color := _sample(_reference, uv)
			var average := _sample(macro, uv)
			var g := ground.get_pixel(x, y)
			var d := detail.get_pixel(x, y)
			var prior := PackedFloat32Array([g.r, g.g, g.b, g.a, d.r, d.g])
			var classified := Classifier.classify(prior, color, average, context.get_pixel(x, y).r, threshold, strength)
			var weights: PackedFloat32Array = classified["weights"]
			ground.set_pixel(x, y, Color(weights[0], weights[1], weights[2], weights[3]))
			detail.set_pixel(x, y, Color(weights[4], weights[5], 0.0, 1.0))
			_canopy.set_pixel(x, y, Color(float(classified["canopy"]), 0.0, 0.0))
			_palette.set_pixel(x, y, average)
			_coverage.set_pixel(x, y, Color.WHITE if not _has_reference or (color.a > 0.5 and color.v > 0.015) else Color.BLACK)
	if int(parameters.get("forest_distribution", 1)) == 1:
		for y in _natural_canopy.get_height():
			for x in _natural_canopy.get_width():
				var point := Vector3(float(x) / (size.x - 1) * extent.x, 0.0, float(y) / (size.y - 1) * extent.y)
				if has_tag(_tile(point).get("terrainTags", []), NO_TREES) or not _dry_footprint(point, 0.0) or _coverage.get_pixel(x, y).r < 0.5:
					_natural_canopy.set_pixel(x, y, Color.BLACK)
		_canopy = _natural_canopy
	var profile := WaterProfile.build(_water, _source.sample_spacing_meters)
	_masks = {"ground": ground, "detail": detail, "macro": _palette, "canopy": _canopy,
		"coverage": _coverage, "shore_distance": depth, "water": _water,
		"water_profile": profile, "sample_spacing": _source.sample_spacing_meters}
	return _masks

static func biome_weights(tags: Array) -> PackedFloat32Array:
	# Stable texture order: grass, forest floor, sand, snow, rock, mud.
	var result := PackedFloat32Array([1.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	if has_tag(tags, ["snow", "ice", "glacier"]):
		return PackedFloat32Array([0.0, 0.0, 0.0, 0.95, 0.05, 0.0])
	if has_tag(tags, ["desert", "dunes", "sand", "beach"]):
		return PackedFloat32Array([0.0, 0.0, 0.96, 0.0, 0.04, 0.0])
	if has_tag(tags, WATER + ["swamp", "marsh", "wetland", "wetlands"]):
		return PackedFloat32Array([0.1, 0.0, 0.15, 0.0, 0.0, 0.75])
	if has_tag(tags, FOREST):
		return PackedFloat32Array([0.18, 0.82, 0.0, 0.0, 0.0, 0.0])
	if has_tag(tags, ["rock", "bare_rock", "mountain", "mountains"]):
		return PackedFloat32Array([0.25, 0.0, 0.0, 0.0, 0.75, 0.0])
	if has_tag(tags, ["tundra"]):
		return PackedFloat32Array([0.4, 0.15, 0.0, 0.0, 0.25, 0.2])
	return result

func forest_candidates(parameters: Dictionary) -> Array:
	var density := float(parameters["tree_density"])
	forest_statistics = {"candidate_cells": 0, "accepted": 0, "budget_limited": false}
	if density <= 0.0:
		return []
	if _canopy == null:
		surface_masks(parameters)
	var natural := int(parameters.get("forest_distribution", 1)) == 1
	var extent := Vector2(_source.width - 1, _source.height - 1) * _source.sample_spacing_meters
	var spacing := maxf(0.05, float(parameters["tree_spacing"]))
	var blocks: Array[Rect2] = [Rect2(Vector2.ZERO, extent)]
	if natural and _guide == null:
		blocks = Patches.active_blocks(_natural_canopy, extent, _source.hex_radius_meters)
	var cells := Patches.grid_cells(blocks, spacing)
	while cells > MAX_CANDIDATES:
		spacing *= maxf(1.02, sqrt(float(cells) / MAX_CANDIDATES))
		cells = Patches.grid_cells(blocks, spacing)
	var candidates: Array = []
	for block in blocks:
		var start := Vector2i(ceilf(block.position.x / spacing), ceilf(block.position.y / spacing))
		var end := Vector2i(ceilf(block.end.x / spacing), ceilf(block.end.y / spacing))
		for y in range(start.y, end.y):
			for x in range(start.x, end.x):
				var rng := RandomNumberGenerator.new()
				rng.seed = (int(parameters["seed"]) ^ _source.map_id.hash() ^ (x * 73856093) ^ (y * 19349663)) & 0x7fffffff
				var local := Vector3((x + rng.randf_range(0.25, 0.75)) * spacing, 0.0, (y + rng.randf_range(0.25, 0.75)) * spacing)
				if local.x > extent.x or local.z > extent.y:
					continue
				var tile := _tile(local)
				var tags: Array = tile.get("terrainTags", [])
				if tile.is_empty() or has_tag(tags, NO_TREES) or not _dry_footprint(local, float(parameters["tree_height"]) * 0.3):
					continue
				var uv := _space.terrain_local_to_reference_uv(local, _geometry.bounds())
				var field_uv := Vector2(local.x / extent.x, local.z / extent.y)
				var color := _sample(_reference, uv)
				var probability := _sample(_natural_canopy, field_uv).r if natural else canopy_probability(tags, color, _has_reference, float(parameters["tree_reference_strength"]))
				if not natural and _has_reference:
					probability = lerpf(1.0 if has_tag(tags, FOREST) else 0.0,
						_sample(_canopy, field_uv).r, float(parameters["tree_reference_strength"]))
				if _coverage != null and _sample(_coverage, field_uv).r < 0.5:
					continue
				if _guide != null:
					probability = _sample(_guide, uv).r
				if rng.randf() >= density * probability:
					continue
				var species := 1 if rng.randf() < float(parameters.get("tree_conifer_share", 0.75)) else 0
				if has_tag(tags, ["taiga", "boreal", "pine", "tundra"]):
					species = 1
				elif has_tag(tags, ["jungle", "rainforest"]):
					species = 2
				var tint := Color(rng.randf_range(0.78, 0.93), rng.randf_range(0.85, 1.0), 0.8, 1.0) if natural else _canopy_tint(color, rng)
				candidates.append({"position": local, "species": species, "variant": rng.randi_range(0, 1),
					"yaw": rng.randf_range(-PI, PI), "scale": rng.randf_range(0.72, 1.15),
					"tint": tint, "priority": rng.randf()})
	var budget := clampi(int(parameters.get("forest_tree_budget", 40000)), 1000, MAX_TREES)
	forest_statistics = {"candidate_cells": cells, "accepted": candidates.size(),
		"effective_spacing": spacing, "requested_spacing": float(parameters["tree_spacing"]),
		"budget_limited": candidates.size() > budget or spacing > float(parameters["tree_spacing"]) * 1.001}
	if candidates.size() > budget:
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["priority"] < b["priority"])
		candidates.resize(budget)
	return candidates

static func canopy_probability(tags: Array, color: Color, has_reference: bool, influence: float) -> float:
	if has_tag(tags, NO_TREES):
		return 0.0
	if not has_tag(tags, FOREST):
		return 0.0 # Green fields alone are not evidence of a forest.
	if not has_reference:
		return 1.0
	var green := smoothstep(-0.02, 0.12, color.g - maxf(color.r, color.b))
	var dark := 1.0 - smoothstep(0.35, 0.8, color.v)
	# Preserve some autumn/shaded canopy, but thin bright clearings.
	return lerpf(1.0, clampf(0.12 + green * 0.55 + dark * 0.33, 0.0, 1.0), influence)

func _tile(local: Vector3) -> Dictionary:
	var coordinate := _geometry.tile_at_point(_space.terrain_local_to_logical(local))
	return _tiles.get(coordinate, {}) if _geometry.contains(coordinate) else {}

func _dry_footprint(local: Vector3, radius: float) -> bool:
	for offset in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
			Vector2(-0.707, -0.707), Vector2(0.707, -0.707), Vector2(-0.707, 0.707), Vector2(0.707, 0.707)]:
		var pixel := _space.terrain_local_to_raster_pixel(local + Vector3(offset.x, 0.0, offset.y) * maxf(radius, _source.sample_spacing_meters))
		if pixel.x < 0 or pixel.y < 0 or pixel.x >= _water.get_width() or pixel.y >= _water.get_height():
			return false
		if _water.get_pixelv(pixel).r >= 0.5:
			return false
	return true

static func _sample(image: Image, uv: Vector2) -> Color:
	var size := image.get_size() - Vector2i.ONE
	return image.get_pixel(roundi(clampf(uv.x, 0.0, 1.0) * size.x), roundi(clampf(uv.y, 0.0, 1.0) * size.y))

static func has_tag(tags: Array, choices: Array) -> bool:
	for tag in tags:
		if tag in choices:
			return true
	return false

func _canopy_tint(color: Color, rng: RandomNumberGenerator) -> Color:
	if not _has_reference:
		return Color(rng.randf_range(0.85, 1.0), rng.randf_range(0.9, 1.0), 0.9, 1.0)
	var value := maxf(color.v, 0.08)
	var brightness := rng.randf_range(0.68, 0.88)
	return Color(clampf(color.r / value, 0.55, 1.05) * brightness,
		clampf(color.g / value, 0.65, 1.05) * brightness,
		clampf(color.b / value, 0.4, 1.0) * brightness, 1.0)
