@tool
extends RefCounted
## Image-space water footprints, not one flat polygon per water-tagged hex.
## Map tags seed connectivity; colour alone cannot turn blue mountain shadows
## into lakes. Ambiguous source-level water is preserved conservatively.

const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const Space := preload("res://game/application/terrain/terrain_space_transform.gd")
const WATER_TAGS := ["ocean", "sea", "lake", "river", "water", "coast"]

func sample(
	source: AonwTerrainCompiledArtifact, reference: Image,
	original: PackedFloat32Array, document: Dictionary, overrides: Dictionary = {},
	parameters: Dictionary = {},
) -> Dictionary:
	var error := _document_error(document, source)
	if not error.is_empty():
		return {"ok": false, "message": error}
	for key in overrides:
		if key not in ["water", "ridges"]:
			return {"ok": false, "message": "Unknown reference guide: %s" % key}
		var image: Variant = overrides[key]
		if image is not Image or image.is_empty() or image.is_compressed():
			return {"ok": false, "message": "Reference guides must be decoded images"}
		if image.get_size() != reference.get_size():
			return {"ok": false, "message": "Guide dimensions must match the reference atlas"}
	var samples := clampi(int(parameters.get("water_sampling", 3)), 1, 3)
	var width := source.width
	var height := source.height
	var count := width * height
	var geometry := Geometry.new(source.cols, source.rows, source.hex_radius_meters)
	var space := Space.new(source)
	var bounds := geometry.bounds()
	var tile_water := PackedByteArray()
	tile_water.resize(source.cols * source.rows)
	var protected_land := PackedByteArray()
	protected_land.resize(tile_water.size())
	for tile in document["tiles"]:
		var index := int(tile["row"]) * source.cols + int(tile["col"])
		for tag in tile["terrainTags"]:
			if tag in WATER_TAGS:
				tile_water[index] = 1
			if tag in ["snow", "ice", "glacier", "mountain", "mountains"]:
				protected_land[index] = 1
	var sea_only := tile_water.count(1) == tile_water.size()
	for value in original:
		if value > 0.05:
			sea_only = false
			break
	var luminance := PackedFloat32Array()
	var ridges := PackedFloat32Array()
	var candidates := PackedByteArray()
	var weak_candidates := PackedByteArray()
	var water := PackedByteArray()
	var queue := PackedInt32Array()
	luminance.resize(count)
	ridges.resize(count)
	candidates.resize(count)
	weak_candidates.resize(count)
	water.resize(count)
	queue.resize(count)
	var tail := 0
	var ambiguous_samples := 0
	var reference_size := reference.get_size() - Vector2i.ONE
	var footprint := Vector2(reference_size) * source.sample_spacing_meters / bounds.size
	for y in height:
		for x in width:
			var index := y * width + x
			var local := space.raster_pixel_to_terrain_local(Vector2i(x, y))
			var logical := space.terrain_local_to_logical(local)
			var uv := space.terrain_local_to_reference_uv(local, bounds)
			var pixel := Vector2i(roundi(uv.x * reference_size.x), roundi(uv.y * reference_size.y))
			var color := reference.get_pixelv(pixel)
			luminance[index] = color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			if overrides.has("ridges"):
				var guide: Image = overrides["ridges"]
				ridges[index] = clampf(guide.get_pixelv(pixel).r, 0.0, 1.0)
			var outside := not bounds.grow(0.001).has_point(logical)
			if overrides.has("water"):
				var guide: Image = overrides["water"]
				water[index] = int(outside or guide.get_pixelv(pixel).r >= 0.5)
				continue
			if sea_only:
				water[index] = 1
				continue
			var coordinate := geometry.tile_at_point(logical)
			var wet_tile := false
			var protected_tile := false
			if geometry.contains(coordinate):
				var tile_index := coordinate.y * source.cols + coordinate.x
				wet_tile = tile_water[tile_index] != 0
				protected_tile = protected_land[tile_index] != 0 and not wet_tile
			var blue := is_water_color(color)
			var weak := is_possible_water_color(color)
			if not blue and wet_tile and samples > 1:
				blue = _water_coverage(reference, Vector2(uv) * Vector2(reference_size), footprint, samples) >= 0.25
			var uncertain_water := (
				wet_tile and original[index] <= 0.05 and not _clear_land(color)
			)
			# Connected blue snow shadows are still land, even when they touch the ocean.
			# Explicit water/river tags or a guide can intentionally cross snowy terrain.
			candidates[index] = int(outside or (not protected_tile and (blue or uncertain_water)))
			weak_candidates[index] = int(not protected_tile and weak)
			if uncertain_water and not blue and not outside:
				ambiguous_samples += 1
			if outside or (candidates[index] != 0 and (blue or uncertain_water) and (wet_tile or original[index] <= 0.05)):
				water[index] = 1
				queue[tail] = index
				tail += 1
	# Weak shore colours can bridge a one-sample antialiased gap, not propagate
	# recursively through an entire green/blue forest. Never override artist guides.
	if not overrides.has("water") and not sea_only:
		var strong := candidates.duplicate()
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				var index := y * width + x
				if candidates[index] != 0 or weak_candidates[index] == 0:
					continue
				var support := 0
				for offset in [-width - 1, -width, -width + 1, -1, 1, width - 1, width, width + 1]:
					support += strong[index + offset]
				if support >= 3:
					candidates[index] = 1
	# Eight-connected flood preserves thin diagonal rivers. No scan-order growth
	# into land, and no wraparound between the last and first column of a row.
	var head := 0
	while head < tail:
		var index := queue[head]
		head += 1
		var x := index % width
		var y := int(index / width)
		for ny in range(maxi(0, y - 1), mini(height, y + 2)):
			for nx in range(maxi(0, x - 1), mini(width, x + 2)):
				var next := ny * width + nx
				if candidates[next] != 0 and water[next] == 0:
					water[next] = 1
					queue[tail] = next
					tail += 1
	return {
		"ok": true, "luminance": luminance, "water": water, "ridges": ridges,
		"explicit_ridges": overrides.has("ridges"),
		"bank_distance": distance_to_water(water, width, height),
		"ambiguous_water_samples": ambiguous_samples,
	}

func is_water_color(color: Color) -> bool:
	# Chroma, rather than luminance, separates blue/cyan water from bright snow.
	return (
		color.a > 0.5 and color.b - color.r > 0.035
		and color.b > color.g * 0.92 and color.s > 0.12
	)

func is_possible_water_color(color: Color) -> bool:
	# Hysteresis admits teal shallows / shaded blue only when connected to seeded
	# water. It does not seed lakes from arbitrary blue-green forest shadows.
	return color.a > 0.5 and color.b - color.r > 0.015 and color.b >= color.g * 0.9 and color.s > 0.09

func _water_coverage(image: Image, position: Vector2, footprint: Vector2, samples: int) -> float:
	var hits := 0
	var size := image.get_size() - Vector2i.ONE
	for y in samples:
		for x in samples:
			var offset := Vector2((x + 0.5) / samples - 0.5, (y + 0.5) / samples - 0.5) * footprint
			var pixel := Vector2i(roundi(position.x + offset.x), roundi(position.y + offset.y)).clamp(Vector2i.ZERO, size)
			hits += int(is_water_color(image.get_pixelv(pixel)))
	return float(hits) / (samples * samples)

func _clear_land(color: Color) -> bool:
	return (
		color.a > 0.5 and (
			color.r - color.b > 0.045
			or color.g - maxf(color.r, color.b) > 0.025
			or (color.v > 0.78 and color.s < 0.15)
		)
	)

func distance_to_water(water: PackedByteArray, width: int, height: int) -> PackedFloat32Array:
	# Two-pass chamfer distance in raster samples. Diagonals avoid boxy banks.
	var distances := PackedFloat32Array()
	distances.resize(water.size())
	for index in water.size():
		distances[index] = 0.0 if water[index] != 0 else float(width + height)
	for y in height:
		for x in width:
			var index := y * width + x
			if x > 0:
				distances[index] = minf(distances[index], distances[index - 1] + 1.0)
			if y > 0:
				distances[index] = minf(distances[index], distances[index - width] + 1.0)
				if x > 0:
					distances[index] = minf(distances[index], distances[index - width - 1] + sqrt(2.0))
				if x + 1 < width:
					distances[index] = minf(distances[index], distances[index - width + 1] + sqrt(2.0))
	for y in range(height - 1, -1, -1):
		for x in range(width - 1, -1, -1):
			var index := y * width + x
			if x + 1 < width:
				distances[index] = minf(distances[index], distances[index + 1] + 1.0)
			if y + 1 < height:
				distances[index] = minf(distances[index], distances[index + width] + 1.0)
				if x > 0:
					distances[index] = minf(distances[index], distances[index + width - 1] + sqrt(2.0))
				if x + 1 < width:
					distances[index] = minf(distances[index], distances[index + width + 1] + sqrt(2.0))
	return distances

func _document_error(document: Dictionary, source: AonwTerrainCompiledArtifact) -> String:
	if document.get("mapName") != source.map_id:
		return "Reference map identity does not match compiled terrain"
	if document.get("cols") != source.cols or document.get("rows") != source.rows:
		return "Reference map dimensions do not match compiled terrain"
	var tiles: Variant = document.get("tiles")
	if tiles is not Array or tiles.size() != source.cols * source.rows:
		return "Reference map must cover every logical tile"
	var seen := {}
	for tile in tiles:
		if tile is not Dictionary or tile.get("terrainTags") is not Array:
			return "Reference map tile is malformed"
		var col: Variant = tile.get("col")
		var row: Variant = tile.get("row")
		if not _coordinate(col, source.cols) or not _coordinate(row, source.rows):
			return "Reference map coordinate is invalid"
		var key := Vector2i(int(col), int(row))
		if seen.has(key):
			return "Reference map has duplicate coordinates"
		seen[key] = true
	return ""

func _coordinate(value: Variant, limit: int) -> bool:
	return (
		(value is int or value is float) and is_finite(float(value))
		and float(value) == floorf(float(value)) and value >= 0 and value < limit
	)
