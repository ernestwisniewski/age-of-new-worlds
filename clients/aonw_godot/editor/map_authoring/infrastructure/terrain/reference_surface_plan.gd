@tool
extends RefCounted
## Presentation-only biome masks and reproducible forest candidates.
## Never writes logical tiles, heights, native regions or manually placed objects.

const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const Space := preload("res://game/application/terrain/terrain_space_transform.gd")
const WATER := ["ocean", "sea", "lake", "river", "water", "coast"]
const NO_TREES := ["snow", "ice", "glacier", "desert", "dunes", "road", "railroad", "city", "settlement"]
const FOREST := ["forest", "jungle", "rainforest", "woodland", "taiga", "boreal", "pine"]
const MAX_CANDIDATES := 120000
const MAX_TREES := 20000

var _source: AonwTerrainCompiledArtifact
var _reference: Image
var _water: Image
var _guide: Image
var _has_reference := false
var _tiles: Dictionary = {}
var _geometry: AonwHexGridGeometry
var _space: AonwTerrainSpaceTransform

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
	for tile in document.get("tiles", []):
		_tiles[Vector2i(int(tile["col"]), int(tile["row"]))] = tile
	return {"ok": true}

func surface_masks() -> Dictionary:
	var extent := Vector2(_source.width - 1, _source.height - 1) * _source.sample_spacing_meters
	var ratio := minf(1.0, 512.0 / maxf(_source.width, _source.height))
	var size := Vector2i(maxi(2, roundi(_source.width * ratio)), maxi(2, roundi(_source.height * ratio)))
	var ground := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var detail := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			var local := Vector3(float(x) / (size.x - 1) * extent.x, 0.0, float(y) / (size.y - 1) * extent.y)
			var tags: Array = _tile(local).get("terrainTags", [])
			var weights := biome_weights(tags)
			ground.set_pixel(x, y, Color(weights[0], weights[1], weights[2], weights[3]))
			detail.set_pixel(x, y, Color(weights[4], weights[5], 0.0, 1.0))
	# Low-pass weights, not the terrain. Blending never changes biome identities.
	for image in [ground, detail]:
		image.resize(maxi(2, int(size.x / 2)), maxi(2, int(size.y / 2)), Image.INTERPOLATE_BILINEAR)
		image.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	var macro: Image = _reference.duplicate()
	macro.clear_mipmaps()
	macro.resize(64, 64, Image.INTERPOLATE_LANCZOS)
	return {"ground": ground, "detail": detail, "macro": macro}

static func biome_weights(tags: Array) -> PackedFloat32Array:
	# Stable texture order: grass, forest floor, sand, snow, rock, mud.
	var result := PackedFloat32Array([1.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	if has_tag(tags, ["snow", "ice", "glacier"]):
		return PackedFloat32Array([0.0, 0.0, 0.0, 0.95, 0.05, 0.0])
	if has_tag(tags, ["desert", "dunes", "sand", "beach"]):
		return PackedFloat32Array([0.0, 0.0, 0.96, 0.0, 0.04, 0.0])
	if has_tag(tags, WATER + ["swamp", "marsh", "wetland"]):
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
	if density <= 0.0:
		return []
	var extent := Vector2(_source.width - 1, _source.height - 1) * _source.sample_spacing_meters
	var spacing := float(parameters["tree_spacing"])
	# Bound work independently of the map size and slider range.
	spacing = maxf(spacing, sqrt(extent.x * extent.y / float(MAX_CANDIDATES)) * 1.01)
	var columns := ceili(extent.x / spacing)
	var rows := ceili(extent.y / spacing)
	while columns * rows > MAX_CANDIDATES:
		spacing *= 1.1
		columns = ceili(extent.x / spacing)
		rows = ceili(extent.y / spacing)
	var candidates: Array = []
	for y in rows:
		for x in columns:
			var rng := RandomNumberGenerator.new()
			rng.seed = (int(parameters["seed"]) ^ _source.map_id.hash() ^ (x * 73856093) ^ (y * 19349663)) & 0x7fffffff
			# At least 60% of spacing between candidates, including across cells.
			var local := Vector3((x + rng.randf_range(0.3, 0.7)) * spacing, 0.0, (y + rng.randf_range(0.3, 0.7)) * spacing)
			var tile := _tile(local)
			var tags: Array = tile.get("terrainTags", [])
			if tile.is_empty() or has_tag(tags, NO_TREES) or not _dry_footprint(local, float(parameters["tree_height"]) * 0.18):
				continue
			var uv := _space.terrain_local_to_reference_uv(local, _geometry.bounds())
			var color := _sample(_reference, uv)
			var probability := canopy_probability(tags, color, _has_reference, float(parameters["tree_reference_strength"]))
			if _guide != null:
				probability = _sample(_guide, uv).r
			if rng.randf() >= density * probability:
				continue
			var species := 0
			if has_tag(tags, ["taiga", "boreal", "pine", "tundra"]):
				species = 1
			elif has_tag(tags, ["jungle", "rainforest"]):
				species = 2
			elif float(tile.get("height", 0.0)) >= 3.0 and rng.randf() < 0.65:
				species = 1
			candidates.append({"position": local, "species": species, "variant": rng.randi_range(0, 1),
				"yaw": rng.randf_range(-PI, PI), "scale": rng.randf_range(0.78, 1.2),
				"tint": Color(rng.randf_range(0.85, 1.02), rng.randf_range(0.9, 1.06), rng.randf_range(0.84, 1.0), 1.0),
				"priority": rng.randf()})
	# A deterministic global budget must not truncate one side of the map.
	if candidates.size() > MAX_TREES:
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["priority"] < b["priority"])
		candidates.resize(MAX_TREES)
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
