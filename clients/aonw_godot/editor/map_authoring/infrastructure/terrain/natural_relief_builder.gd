extends RefCounted
## Presentation-only relief. No scene tree, Terrain3D mutation or file writes.
## Heights stay in metres. Hex heights locate ranges, never individual summits.

const Artifact := preload("res://game/application/terrain/terrain_compiled_artifact.gd")
const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const Space := preload("res://game/application/terrain/terrain_space_transform.gd")
const VERSION := "aonw-dravonia-natural-relief/1"
const MAX_SAMPLES := 4_194_304
const SEA_EPSILON := 0.05

func build(
	source: AonwTerrainCompiledArtifact,
	reference: Image,
	seed_value: int = 73129,
	height_scale: float = 1.65,
	reference_strength: float = 1.0,
) -> Dictionary:
	if seed_value < -2147483648 or seed_value > 2147483647:
		return {"ok": false, "message": "Relief seed must fit a signed 32-bit integer"}
	var error := _input_error(source, reference, height_scale, reference_strength)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var image: Image = source.base_image.duplicate()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RF)
	var original := image.get_data().to_float32_array()
	for value in original:
		if not is_finite(value):
			return {"ok": false, "message": "Source heightmap contains a non-finite height"}
	var width := source.width
	var height := source.height
	var spacing := source.sample_spacing_meters
	var radius := maxi(1, roundi(source.hex_radius_meters * 0.65 / spacing))
	# Three separable box passes approximate a Gaussian, spanning tile boundaries.
	# O(samples), not one independently shaped cone per hex.
	var macro := _smooth(original, width, height, radius, 3)
	var guide := _reference_guide(source, reference)
	var guide_fine := _smooth(guide, width, height, 1, 1)
	var guide_coarse := _smooth(guide, width, height, maxi(2, radius), 2)
	var ridges := _noise(seed_value, 1.0 / (source.hex_radius_meters * 2.8), true)
	var detail := _noise(seed_value ^ 0x51a9, 1.0 / (source.hex_radius_meters * 0.9), false)
	var dry := PackedFloat32Array()
	var heights := PackedFloat32Array()
	dry.resize(original.size())
	heights.resize(original.size())
	var maximum := source.max_terrain_height_meters
	for y in height:
		for x in width:
			var index := y * width + x
			var source_height := original[index]
			if source_height <= SEA_EPSILON:
				heights[index] = source_height
				continue
			# Feather into the original shoreline; never make noise islands in the sea.
			dry[index] = smoothstep(SEA_EPSILON, maximum * 0.24, source_height)
			var mountain := smoothstep(maximum * 0.28, maximum * 0.68, macro[index])
			var world_x := x * spacing + source.world_min_meters.x
			var world_z := y * spacing + source.world_min_meters.y
			var crest := pow(clampf(ridges.get_noise_2d(world_x, world_z) * 0.5 + 0.5, 0.0, 1.0), 2.2)
			var fine := detail.get_noise_2d(world_x, world_z)
			var lowland := macro[index] + fine * 0.22
			var alpine := macro[index] * height_scale * (0.55 + 1.1 * crest)
			alpine += fine * maximum * 0.045
			# Bounded local contrast guides small crests only. Bright snow/desert is
			# NOT treated as absolute altitude, nor is the illustration a DEM.
			var reference_detail := clampf((guide_fine[index] - guide_coarse[index]) * 4.0, -1.0, 1.0)
			alpine += reference_detail * reference_strength
			var sculpted := lerpf(lowland, alpine, mountain)
			heights[index] = lerpf(source_height, maxf(SEA_EPSILON, sculpted), dry[index])
	# Conservative downhill talus relaxation, not a hydraulic-erosion simulation.
	# Double buffering prevents scan-order bias; protected water never receives flux.
	for _pass in 3:
		heights = _relax_talus(heights, dry, width, height, spacing * 1.3)
	var minimum := PackedFloat32Array()
	var upper := PackedFloat32Array()
	minimum.resize(heights.size())
	upper.resize(heights.size())
	var max_height := 0.0
	var changed_samples := 0
	for index in heights.size():
		# New continuous presentation envelope, not the old hex-wise min/max:
		# clamping back to those limits would recreate the flat hex mountain tops.
		var allowance := dry[index] * maxf(0.75, macro[index] * 0.3)
		minimum[index] = minf(heights[index], maxf(0.0, heights[index] - allowance))
		upper[index] = heights[index] + allowance
		max_height = maxf(max_height, upper[index])
		if absf(heights[index] - original[index]) > 0.001:
			changed_samples += 1
	var result := _copy_geometry(source)
	result.base_image = _image(heights, width, height)
	result.minimum_image = _image(minimum, width, height)
	result.maximum_image = _image(upper, width, height)
	result.max_terrain_height_meters = maxf(max_height, 0.1)
	result.generator_version = VERSION
	result.generated_base_hash = _sha(result.base_image.get_data())
	var recipe := {
		"version": VERSION,
		"godot": Engine.get_version_info()["string"],
		"source_profile": source.authoring_profile_hash,
		"source_base": _sha(image.get_data()),
		"reference_guide": _sha(guide.to_byte_array()),
		"seed": seed_value,
		"height_scale": height_scale,
		"reference_strength": reference_strength,
	}
	result.authoring_profile_hash = _sha(JSON.stringify(recipe).to_utf8_buffer())
	var workspace_key := _sha((result.authoring_profile_hash + result.generated_base_hash).to_utf8_buffer())
	return {
		"ok": true, "artifact": result, "workspace_key": workspace_key,
		"changed_samples": changed_samples, "recipe": recipe,
	}

func _noise(seed_value: int, frequency: float, ridged: bool) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED if ridged else FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3 if ridged else 2
	noise.fractal_gain = 0.45
	noise.fractal_lacunarity = 2.0
	if ridged:
		noise.domain_warp_enabled = true
		noise.domain_warp_amplitude = 1.0 / frequency * 0.55
		noise.domain_warp_frequency = frequency * 0.45
		noise.domain_warp_fractal_octaves = 2
	return noise

func _reference_guide(source: AonwTerrainCompiledArtifact, reference: Image) -> PackedFloat32Array:
	var guide := PackedFloat32Array()
	guide.resize(source.width * source.height)
	var geometry := Geometry.new(source.cols, source.rows, source.hex_radius_meters)
	var space := Space.new(source)
	var bounds := geometry.bounds()
	# The SAME UV transform as the draped reference, including the padded last row.
	# No independent resize that would stretch or flip the reference image.
	for y in source.height:
		for x in source.width:
			var local := space.raster_pixel_to_terrain_local(Vector2i(x, y))
			var uv := space.terrain_local_to_reference_uv(local, bounds)
			var color := reference.get_pixel(
				roundi(uv.x * (reference.get_width() - 1)),
				roundi(uv.y * (reference.get_height() - 1)),
			)
			guide[y * source.width + x] = color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	return guide

func _smooth(
	values: PackedFloat32Array, width: int, height: int, radius: int, passes: int,
) -> PackedFloat32Array:
	var result := values.duplicate()
	for _pass in passes:
		result = _box_axis(result, width, height, radius, true)
		result = _box_axis(result, width, height, radius, false)
	return result

func _box_axis(
	values: PackedFloat32Array, width: int, height: int, radius: int, horizontal: bool,
) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(values.size())
	var length := width if horizontal else height
	var lines := height if horizontal else width
	var stride := 1 if horizontal else width
	var divisor := float(radius * 2 + 1)
	for line in lines:
		var start := line * width if horizontal else line
		var total := 0.0
		for offset in range(-radius, radius + 1):
			total += values[start + clampi(offset, 0, length - 1) * stride]
		for position in length:
			result[start + position * stride] = total / divisor
			total -= values[start + clampi(position - radius, 0, length - 1) * stride]
			total += values[start + clampi(position + radius + 1, 0, length - 1) * stride]
	return result

func _relax_talus(
	values: PackedFloat32Array, dry: PackedFloat32Array, width: int, height: int, talus: float,
) -> PackedFloat32Array:
	var delta := PackedFloat32Array()
	delta.resize(values.size())
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var index := y * width + x
			if dry[index] < 0.999:
				continue
			var target := index
			var largest_drop := talus
			for neighbor in [index - 1, index + 1, index - width, index + width]:
				if dry[neighbor] < 0.999:
					continue
				var drop: float = values[index] - values[neighbor]
				if drop > largest_drop:
					largest_drop = drop
					target = neighbor
			if target != index:
				var transfer := (largest_drop - talus) * 0.18
				delta[index] -= transfer
				delta[target] += transfer
	var result := values.duplicate()
	for index in result.size():
		result[index] += delta[index]
	return result

func _copy_geometry(source: AonwTerrainCompiledArtifact) -> AonwTerrainCompiledArtifact:
	var result := Artifact.new()
	# Only metadata is copied. Never mutate the canonical images or map rules.
	result.directory = source.directory
	result.map_id = source.map_id
	result.map_content_hash = source.map_content_hash
	result.width = source.width
	result.height = source.height
	result.sample_spacing_meters = source.sample_spacing_meters
	result.world_min_meters = source.world_min_meters
	result.world_origin_meters = source.world_origin_meters
	result.cols = source.cols
	result.rows = source.rows
	result.hex_radius_meters = source.hex_radius_meters
	result.reference_translation_meters = source.reference_translation_meters
	result.reference_rotation_degrees = source.reference_rotation_degrees
	result.reference_scale = source.reference_scale
	result.city_core_radius_meters = source.city_core_radius_meters
	result.max_city_slope = source.max_city_slope
	return result

func _image(values: PackedFloat32Array, width: int, height: int) -> Image:
	return Image.create_from_data(width, height, false, Image.FORMAT_RF, values.to_byte_array())

func _sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _input_error(
	source: AonwTerrainCompiledArtifact, reference: Image, scale: float, strength: float,
) -> String:
	if source == null or source.base_image == null:
		return "Compiled terrain is required"
	if reference == null or reference.is_empty() or reference.is_compressed():
		return "A decoded reference image is required"
	if source.width < 2 or source.height < 2 or source.width * source.height > MAX_SAMPLES:
		return "Unsupported relief raster dimensions"
	if source.base_image.get_size() != Vector2i(source.width, source.height):
		return "Relief raster dimensions do not match the source image"
	if source.base_image.get_format() not in [Image.FORMAT_RF, Image.FORMAT_RGBF, Image.FORMAT_RGBAF]:
		return "Relief heights must be 32-bit floats in metres"
	if not is_finite(source.sample_spacing_meters) or source.sample_spacing_meters <= 0.0:
		return "Relief sample spacing must be positive and finite"
	if not is_finite(source.hex_radius_meters) or source.hex_radius_meters <= 0.0:
		return "Relief hex radius must be positive and finite"
	if source.cols <= 0 or source.rows <= 0:
		return "Logical map dimensions must be positive"
	if not source.world_min_meters.is_finite() or not source.world_origin_meters.is_finite():
		return "Terrain coordinates must be finite"
	if source.hex_radius_meters / source.sample_spacing_meters > 256.0:
		return "Too many relief samples per hex"
	if not is_finite(source.max_terrain_height_meters) or source.max_terrain_height_meters <= 0.0:
		return "Source maximum height must be positive and finite"
	if not is_finite(scale) or scale < 0.5 or scale > 3.0:
		return "Mountain height scale must be between 0.5 and 3.0"
	if not is_finite(strength) or strength < 0.0 or strength > 3.0:
		return "Reference detail must be between 0 and 3 metres"
	return ""
