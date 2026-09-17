@tool
extends RefCounted
## Continuous seeded woodland in biome neighbourhoods. No reference-image input.
## Noise is sampled in map metres, not pixels or individual hex coordinates.

static func build(context: Image, extent: Vector2, hex_radius: float,
		map_seed: int, values: Dictionary) -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = map_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.45
	noise.frequency = 1.0 / maxf(0.1, hex_radius * float(values.get("forest_patch_size", 2.6)))
	var cover := float(values.get("forest_patch_coverage", 0.45))
	var edge := float(values.get("forest_edge_softness", 0.12))
	var threshold := lerpf(0.85, 0.15, cover)
	var result := Image.create(context.get_width(), context.get_height(), false, Image.FORMAT_L8)
	for y in result.get_height():
		for x in result.get_width():
			var position := Vector2(x, y) / Vector2(result.get_size() - Vector2i.ONE) * extent
			var habitat := smoothstep(0.04, 0.65, context.get_pixel(x, y).r)
			var signal_value := clampf(0.5 + noise.get_noise_2dv(position) * 0.9, 0.0, 1.0)
			var canopy := habitat * smoothstep(threshold - edge, threshold + edge, signal_value)
			result.set_pixel(x, y, Color(canopy, 0.0, 0.0))
	return result

static func active_blocks(mask: Image, extent: Vector2, block_size: float) -> Array[Rect2]:
	# Visit every mask sample, including small groves, and include interpolation
	# neighbours. Dictionary membership bounds work without missing thin patches.
	var occupied := {}
	var columns := ceili(extent.x / block_size)
	var rows := ceili(extent.y / block_size)
	var pixel_size := extent / Vector2(mask.get_size() - Vector2i.ONE)
	for y in mask.get_height():
		for x in mask.get_width():
			if mask.get_pixel(x, y).r <= 0.0:
				continue
			var point := Vector2(x, y) * pixel_size
			var first := Vector2i((point - pixel_size) / block_size)
			var last := Vector2i((point + pixel_size) / block_size)
			for by in range(maxi(0, first.y), mini(rows - 1, last.y) + 1):
				for bx in range(maxi(0, first.x), mini(columns - 1, last.x) + 1):
					occupied[Vector2i(bx, by)] = true
	var result: Array[Rect2] = []
	# Stable row-major order, not insertion order tied to mask resolution.
	for y in rows:
		for x in columns:
			if occupied.has(Vector2i(x, y)):
				var start := Vector2(x, y) * block_size
				result.append(Rect2(start, (extent - start).min(Vector2.ONE * block_size)))
	return result

static func grid_cells(blocks: Array[Rect2], spacing: float) -> int:
	var count := 0
	for block in blocks:
		var start := Vector2i(ceilf(block.position.x / spacing), ceilf(block.position.y / spacing))
		var end := Vector2i(ceilf(block.end.x / spacing), ceilf(block.end.y / spacing))
		count += (end.x - start.x) * (end.y - start.y)
	return count
