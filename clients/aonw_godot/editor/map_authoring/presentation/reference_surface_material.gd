@tool
extends RefCounted
## Load only explicitly installed assets. No editor-time network requests.

const Images := preload("res://editor/map_authoring/presentation/reference_image_loader.gd")
const ROOT := "res://assets/reference_materials/"
const SHADER := preload("res://editor/map_authoring/presentation/reference_surface.gdshader")
const LAYERS := ["grass", "forest", "sand", "snow", "rock", "mud"]
static var _arrays: Dictionary = {}

static func build(masks: Dictionary, reference: Texture2D, extent: Vector2, has_reference: bool) -> Dictionary:
	if _arrays.is_empty():
		var loaded := _load_arrays()
		if not loaded["ok"]:
			return loaded
		_arrays = loaded
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("ground_ar", _arrays["ar"])
	material.set_shader_parameter("layer_means", _arrays["means"])
	material.set_shader_parameter("ground_normal", _arrays["normal"])
	material.set_shader_parameter("ground_weights", ImageTexture.create_from_image(masks["ground"]))
	material.set_shader_parameter("detail_weights", ImageTexture.create_from_image(masks["detail"]))
	material.set_shader_parameter("reference_macro", ImageTexture.create_from_image(masks["macro"]))
	material.set_shader_parameter("reference_texture", reference)
	var coverage: Image = masks.get("coverage")
	if coverage == null:
		coverage = Image.create(2, 2, false, Image.FORMAT_L8)
		coverage.fill(Color.WHITE)
	material.set_shader_parameter("coverage", ImageTexture.create_from_image(coverage))
	var distance: Image = masks.get("shore_distance")
	if distance == null:
		distance = Image.create(2, 2, false, Image.FORMAT_RF)
	material.set_shader_parameter("shore_distance", ImageTexture.create_from_image(distance))
	material.set_shader_parameter("raster_extent", extent)
	var profile: Image = masks.get("water_profile")
	if profile == null:
		profile = Image.create(2, 2, false, Image.FORMAT_RGBAH)
		profile.fill(Color(-1.0, 0.0, 0.0, 0.0))
	material.set_shader_parameter("water_profile", ImageTexture.create_from_image(profile))
	material.set_shader_parameter("sample_spacing", float(masks.get("sample_spacing", 1.0)))
	material.set_shader_parameter("has_reference", has_reference)
	return {"ok": true, "material": material}

static func _load_arrays() -> Dictionary:
	var albedo_roughness: Array[Image] = []
	var normals: Array[Image] = []
	var means := PackedColorArray()
	for layer in LAYERS:
		for suffix in ["_diffuse.jpg", "_normal.jpg", "_roughness.jpg"]:
			if not ResourceLoader.exists(ROOT + layer + suffix):
				return {"ok": false, "message": "PBR scans missing. Run python3 clients/aonw_godot/tool/install_reference_assets.py, then reopen the scene."}
		var albedo := Images.read(ROOT + layer + "_diffuse.jpg")
		var normal := Images.read(ROOT + layer + "_normal.jpg")
		var roughness := Images.read(ROOT + layer + "_roughness.jpg")
		if albedo == null or normal == null or roughness == null:
			return {"ok": false, "message": "PBR scans missing. Run python3 clients/aonw_godot/tool/install_reference_assets.py, then reopen the scene."}
		for image in [albedo, normal, roughness]:
			if image.is_empty():
				return {"ok": false, "message": "Empty PBR scan: " + layer}
			image.clear_mipmaps()
			image.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
		var thumbnail: Image = albedo.duplicate()
		thumbnail.resize(16, 16, Image.INTERPOLATE_LANCZOS)
		var mean_color := Color(0.0, 0.0, 0.0, 0.0)
		for y in 16:
			for x in 16:
				mean_color += thumbnail.get_pixel(x, y).srgb_to_linear() / 256.0
		means.append(mean_color)
		albedo.convert(Image.FORMAT_RGB8)
		roughness.convert(Image.FORMAT_L8)
		normal.convert(Image.FORMAT_RGBA8)
		# Packed bytes avoid millions of GDScript get_pixel/set_pixel calls.
		var rgb := albedo.get_data()
		var rough := roughness.get_data()
		var rgba := PackedByteArray()
		rgba.resize(1024 * 1024 * 4)
		for i in 1024 * 1024:
			rgba[i * 4] = rgb[i * 3]
			rgba[i * 4 + 1] = rgb[i * 3 + 1]
			rgba[i * 4 + 2] = rgb[i * 3 + 2]
			rgba[i * 4 + 3] = rough[i]
		var packed := Image.create_from_data(1024, 1024, false, Image.FORMAT_RGBA8, rgba)
		packed.generate_mipmaps()
		normal.generate_mipmaps(true)
		albedo_roughness.append(packed)
		normals.append(normal)
	var ar := Texture2DArray.new()
	var normal_array := Texture2DArray.new()
	if ar.create_from_images(albedo_roughness) != OK or normal_array.create_from_images(normals) != OK:
		return {"ok": false, "message": "Could not upload the PBR texture arrays"}
	return {"ok": true, "ar": ar, "normal": normal_array, "means": means}
