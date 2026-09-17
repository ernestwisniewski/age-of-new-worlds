@tool
extends RefCounted
## Signed shoreline distance in metres shared by the bed and the water shader.
## R: signed shore distance; GB: local along-bank direction; A: water half-width.
## No mask dilation, island removal, native height changes or inferred lake levels.
const Hydrology := preload("res://editor/map_authoring/infrastructure/terrain/reference_hydrology.gd")

static func build(mask: Image, spacing: float) -> Image:
	var width := mask.get_width()
	var height := mask.get_height()
	var wet := PackedByteArray()
	var dry := PackedByteArray()
	wet.resize(width * height)
	dry.resize(wet.size())
	for y in height:
		for x in width:
			var i := y * width + x
			wet[i] = int(mask.get_pixel(x, y).r >= 0.5)
			dry[i] = 1 - wet[i]
	var hydro := Hydrology.new()
	var to_water := hydro.distance_to_water(wet, width, height)
	var to_land := hydro.distance_to_water(dry, width, height)
	var signed_distance := PackedFloat32Array()
	signed_distance.resize(wet.size())
	for i in wet.size():
		signed_distance[i] = (to_land[i] - 0.5) * spacing if wet[i] else -(to_water[i] - 0.5) * spacing
	var pixels := PackedFloat32Array()
	pixels.resize(wet.size() * 4)
	for y in height:
		for x in width:
			var i := y * width + x
			var dx := signed_distance[y * width + mini(width - 1, x + 1)] - signed_distance[y * width + maxi(0, x - 1)]
			var dz := signed_distance[mini(height - 1, y + 1) * width + x] - signed_distance[maxi(0, y - 1) * width + x]
			var along := Vector2(-dz, dx).normalized()
			if along.x < 0.0 or (is_zero_approx(along.x) and along.y < 0.0):
				along = -along
			pixels[i * 4] = clampf(signed_distance[i], -60000.0, 60000.0)
			pixels[i * 4 + 1] = along.x
			pixels[i * 4 + 2] = along.y
			pixels[i * 4 + 3] = clampf(signed_distance[i], 0.0, 60000.0)
	# Half-float is filterable across Apple GPU families and halves texture memory.
	# Far-field saturation avoids half-float infinity; shoreline samples retain
	# precision well below the native raster spacing. CPU masks stay unchanged.
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGBAF, pixels.to_byte_array())
	image.convert(Image.FORMAT_RGBAH)
	return image
