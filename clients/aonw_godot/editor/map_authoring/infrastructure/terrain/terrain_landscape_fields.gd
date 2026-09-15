@tool
extends "res://editor/map_authoring/infrastructure/terrain/reference_hydrology.gd"
## Adds semantic height/biome fields using the same raster-to-logical transform.
## Terrain tags locate landforms, not hex-sized peaks. Unknown tags remain valid.

func sample_landscape(
	source: AonwTerrainCompiledArtifact, reference: Image,
	original: PackedFloat32Array, document: Dictionary, overrides: Dictionary,
	has_reference: bool = true,
) -> Dictionary:
	var result := sample(source, reference, original, document, overrides)
	if not result["ok"]:
		return result
	var tiles := {}
	for tile in document["tiles"]:
		var value: Variant = tile.get("height")
		if not (value is int or value is float) or not is_finite(float(value)):
			return {"ok": false, "message": "JSON tile height must be finite"}
		if value < 0 or value > 5 or float(value) != floorf(float(value)):
			return {"ok": false, "message": "JSON tile height must be an integer from 0 to 5"}
		for tag in tile["terrainTags"]:
			if tag is not String:
				return {"ok": false, "message": "Terrain tags must be strings"}
		tiles[Vector2i(int(tile["col"]), int(tile["row"]))] = tile
	var fields := {}
	for key in ["levels", "mountains", "hills", "red", "green", "blue", "rock_evidence"]:
		var values := PackedFloat32Array()
		values.resize(original.size())
		fields[key] = values
	var levels: PackedFloat32Array = fields["levels"]
	var mountains: PackedFloat32Array = fields["mountains"]
	var hills: PackedFloat32Array = fields["hills"]
	var red: PackedFloat32Array = fields["red"]
	var green: PackedFloat32Array = fields["green"]
	var blue: PackedFloat32Array = fields["blue"]
	var rock_evidence: PackedFloat32Array = fields["rock_evidence"]
	var bounds := Geometry.new(source.cols, source.rows, source.hex_radius_meters).bounds()
	var reference_size := reference.get_size() - Vector2i.ONE
	var water: PackedByteArray = result["water"]
	var geometry := Geometry.new(source.cols, source.rows, source.hex_radius_meters)
	var space := Space.new(source)
	for y in source.height:
		for x in source.width:
			var index := y * source.width + x
			var logical := space.terrain_local_to_logical(space.raster_pixel_to_terrain_local(Vector2i(x, y)))
			var coordinate := geometry.tile_at_point(logical)
			var tile: Dictionary = tiles.get(coordinate, {})
			var tags: Array = tile.get("terrainTags", [])
			levels[index] = float(tile.get("height", 0.0)) / 5.0
			mountains[index] = 1.0 if _any_tag(tags, ["mountain", "mountains"]) else 0.0
			hills[index] = 1.0 if _any_tag(tags, ["hill", "hills"]) else 0.0
			var uv := space.terrain_local_to_reference_uv(space.raster_pixel_to_terrain_local(Vector2i(x, y)), bounds)
			var sampled := reference.get_pixel(roundi(uv.x * reference_size.x), roundi(uv.y * reference_size.y))
			rock_evidence[index] = smoothstep(0.35, 0.8, sampled.v) * (1.0 - smoothstep(0.15, 0.55, sampled.s))
			var color := _biome_color(tags)
			red[index] = color.r
			green[index] = color.g
			blue[index] = color.b
			if not has_reference and not overrides.has("water"):
				water[index] = int(tile.is_empty() or _any_tag(tags, WATER_TAGS))
	result.merge({"levels": levels, "mountains": mountains, "hills": hills,
		"red": red, "green": green, "blue": blue, "rock_evidence": rock_evidence}, true)
	result["water"] = water
	result["bank_distance"] = distance_to_water(water, source.width, source.height)
	return result

func _any_tag(tags: Array, choices: Array) -> bool:
	for tag in tags:
		if tag in choices:
			return true
	return false

func _biome_color(tags: Array) -> Color:
	if _any_tag(tags, ["snow", "ice", "glacier"]):
		return Color(0.82, 0.85, 0.86)
	if _any_tag(tags, ["desert", "dunes"]):
		return Color(0.63, 0.49, 0.29)
	if _any_tag(tags, ["tundra"]):
		return Color(0.4, 0.44, 0.35)
	if _any_tag(tags, ["forest", "jungle", "rainforest"]):
		return Color(0.19, 0.3, 0.13)
	if _any_tag(tags, ["swamp", "marsh"]):
		return Color(0.28, 0.32, 0.18)
	if _any_tag(tags, WATER_TAGS):
		return Color(0.31, 0.29, 0.23) # A dry basin, not a pretend water surface.
	return Color(0.38, 0.43, 0.24)
