@tool
extends "res://editor/map_authoring/infrastructure/terrain/natural_relief_builder.gd"
## Pure reconstruction: no nodes, UI, files, native terrain writes or gameplay edits.

const Landscape := preload("res://editor/map_authoring/infrastructure/terrain/terrain_landscape_fields.gd")
const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
const REFERENCE_VERSION := "aonw-reference-terrain/2"

func build_reference(
	source: AonwTerrainCompiledArtifact, reference: Image, document: Dictionary,
	seed_value: int = 73129, height_scale: float = 1.65,
	reference_strength: float = 1.0, overrides: Dictionary = {},
	parameters: Dictionary = {}, has_reference: bool = true,
) -> Dictionary:
	var error := _input_error(source, reference, height_scale, reference_strength)
	if not error.is_empty():
		return {"ok": false, "message": error}
	if seed_value < 0 or seed_value > 2147483647:
		return {"ok": false, "message": "Relief seed must fit a non-negative signed 32-bit integer"}
	var requested := parameters.duplicate(true)
	if not requested.has("seed"):
		requested["seed"] = seed_value
	if not requested.has("mountain_scale"):
		requested["mountain_scale"] = height_scale
	if not requested.has("reference_strength"):
		requested["reference_strength"] = minf(reference_strength, 1.0)
	error = Parameters.validate(requested)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var p := Parameters.normalized(requested, source.max_terrain_height_meters)
	var image: Image = source.base_image.duplicate()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RF)
	var original := image.get_data().to_float32_array()
	for value in original:
		if not is_finite(value) or value < 0.0:
			return {"ok": false, "message": "Source heights must be finite and non-negative"}
	var guides := Landscape.new().sample_landscape(source, reference, original, document, overrides, has_reference)
	if not guides["ok"]:
		return guides
	var width := source.width
	var height := source.height
	var spacing := source.sample_spacing_meters
	var radius := maxi(1, roundi(source.hex_radius_meters * float(p["smoothing"]) / spacing))
	var maximum: float = p["level_height"]
	var levels: PackedFloat32Array = guides["levels"]
	var elevation := original.duplicate()
	for index in elevation.size():
		# Compiled blending and direct JSON heights both participate in the envelope.
		elevation[index] = lerpf(original[index] / source.max_terrain_height_meters, levels[index], 0.5) * maximum
	var macro := _smooth(elevation, width, height, radius, 3)
	var mountains := _smooth(guides["mountains"], width, height, radius, 2)
	var hills := _smooth(guides["hills"], width, height, radius, 2)
	var luma: PackedFloat32Array = guides["luminance"]
	var fine := _smooth(luma, width, height, maxi(1, roundi(radius * 0.12)), 2)
	var medium := _smooth(luma, width, height, maxi(2, roundi(radius * 0.5)), 2)
	var coarse := _smooth(luma, width, height, radius, 2)
	var water: PackedByteArray = guides["water"]
	var distance: PackedFloat32Array = guides["bank_distance"]
	var explicit_ridges: PackedFloat32Array = guides["ridges"]
	if guides["explicit_ridges"]:
		explicit_ridges = _smooth(explicit_ridges, width, height, 1, 1)
	var ridged_noise := _noise(int(p["seed"]), 1.0 / (source.hex_radius_meters * 2.8), true)
	var detail := _noise(int(p["seed"]) ^ 0x51a9, 1.0 / (source.hex_radius_meters * float(p["detail_scale"])), false)
	var rolling := _noise(int(p["seed"]) ^ 0x7391, 1.0 / (source.hex_radius_meters * 2.0), false)
	var heights := PackedFloat32Array()
	var dry := PackedFloat32Array()
	heights.resize(original.size())
	dry.resize(original.size())
	var shore_width := maxf(spacing, source.hex_radius_meters * float(p["bank_width"]))
	for y in height:
		for x in width:
			var index := y * width + x
			if water[index] != 0:
				continue
			var highland := smoothstep(maximum * 0.22, maximum * 0.65, macro[index])
			var mountain := highland * lerpf(0.2, 1.0, mountains[index])
			var hill := maxf(hills[index], smoothstep(maximum * 0.06, maximum * 0.28, macro[index]) * (1.0 - mountain) * 0.25)
			var world_x := x * spacing + source.world_min_meters.x
			var world_z := y * spacing + source.world_min_meters.y
			var noise := detail.get_noise_2d(world_x, world_z)
			var fallback := clampf(ridged_noise.get_noise_2d(world_x, world_z) * 0.5 + 0.5, 0.0, 1.0)
			var contrast := fine[index] - medium[index]
			var broad := medium[index] - coarse[index]
			var confidence := clampf(absf(contrast) * 18.0 + absf(broad) * 10.0, 0.0, 1.0)
			var crest := clampf(0.5 + contrast * 5.0 + broad * 2.5, 0.0, 1.0)
			if not has_reference:
				confidence = 0.0
			if guides["explicit_ridges"]:
				crest = explicit_ridges[index]
				confidence = 1.0
			crest = lerpf(fallback, crest, confidence * float(p["reference_strength"]))
			var alpine := macro[index] * float(p["mountain_scale"]) * (0.52 + 1.05 * pow(crest, float(p["ridge_sharpness"])))
			var lowland := macro[index] + rolling.get_noise_2d(world_x, world_z) * maximum * 0.15 * hill * float(p["hill_scale"])
			var sculpted := lerpf(lowland, alpine, mountain)
			sculpted += noise * maximum * float(p["detail_strength"]) * lerpf(0.15, 1.0, maxf(mountain, hill))
			dry[index] = smoothstep(0.0, shore_width, distance[index] * spacing)
			heights[index] = maxf(0.02, sculpted) * dry[index]
	for _pass in int(p["erosion_passes"]):
		heights = _relax_talus(heights, dry, width, height, spacing * 1.3)
	var minimum := PackedFloat32Array()
	var upper := PackedFloat32Array()
	minimum.resize(heights.size())
	upper.resize(heights.size())
	var highest := 0.1
	var changed := 0
	for index in heights.size():
		if water[index] != 0:
			heights[index] = 0.0
		else:
			heights[index] = maxf(0.0, heights[index])
			var allowance := dry[index] * maxf(0.5, macro[index] * 0.3)
			minimum[index] = maxf(0.0, heights[index] - allowance)
			upper[index] = heights[index] + allowance
		if not is_finite(heights[index]) or not is_finite(upper[index]):
			return {"ok": false, "message": "Reference relief produced a non-finite height"}
		highest = maxf(highest, upper[index])
		if absf(heights[index] - original[index]) > 0.001:
			changed += 1
	var result := _copy_geometry(source)
	result.base_image = _image(heights, width, height)
	result.minimum_image = _image(minimum, width, height)
	result.maximum_image = _image(upper, width, height)
	result.max_terrain_height_meters = highest
	result.generator_version = REFERENCE_VERSION
	result.generated_base_hash = _sha(result.base_image.get_data())
	var recipe := {
		"version": REFERENCE_VERSION, "schema": Parameters.VERSION, "godot": Engine.get_version_info()["string"],
		"map_id": source.map_id, "map_content": source.map_content_hash,
		"source_profile": source.authoring_profile_hash, "source_base": _sha(image.get_data()),
		"map_document": _sha(JSON.stringify(document).to_utf8_buffer()),
		"reference": _image_hash(reference) if has_reference else "semantic-only", "water": _sha(water),
		"ridge_override": _sha(explicit_ridges.to_byte_array()) if guides["explicit_ridges"] else "",
		"parameters": Parameters.geometry(p),
	}
	result.authoring_profile_hash = _sha(JSON.stringify(recipe).to_utf8_buffer())
	return {
		"ok": true, "artifact": result, "recipe": recipe, "parameters": p,
		"workspace_key": _sha((result.authoring_profile_hash + result.generated_base_hash).to_utf8_buffer()),
		"water_mask": Image.create_from_data(width, height, false, Image.FORMAT_L8, _mask_bytes(water)),
		"water_samples": water.count(1), "changed_samples": changed,
		"biome_image": _biome_image(guides, width, height, radius),
		"ambiguous_water_samples": guides["ambiguous_water_samples"],
	}

func _biome_image(guides: Dictionary, width: int, height: int, radius: int) -> Image:
	var red := _smooth(guides["red"], width, height, radius, 2)
	var green := _smooth(guides["green"], width, height, radius, 2)
	var blue := _smooth(guides["blue"], width, height, radius, 2)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var index := y * width + x
			image.set_pixel(x, y, Color(red[index], green[index], blue[index], 1.0))
	return image

func _mask_bytes(water: PackedByteArray) -> PackedByteArray:
	var bytes := water.duplicate()
	for index in bytes.size():
		bytes[index] = 255 if bytes[index] != 0 else 0
	return bytes

func _image_hash(image: Image) -> String:
	var decoded: Image = image.duplicate()
	decoded.clear_mipmaps()
	decoded.convert(Image.FORMAT_RGBA8)
	return _sha(decoded.get_data())
