class_name AonwTerrainCompiledArtifactRepository
extends AonwTerrainCompiledArtifactReader

const Artifact := preload(
	"res://game/application/terrain/terrain_compiled_artifact.gd"
)
const MANIFEST_NAME := "terrain_compile.json"
const COMPILED_ROOT := "res://.godot/terrain_compiled"
const IMPORTED_RUNTIME_ROOT := "res://assets/terrain_compiled/"

var _compiled_root: String

func _init(compiled_root: String = COMPILED_ROOT) -> void:
	_compiled_root = compiled_root

func load_terrain(map: AonwMapView) -> Dictionary:
	var result := load_artifact(_compiled_root.path_join(str(map.map_id())), str(map.map_id()))
	if not result["ok"]:
		return result
	var artifact: AonwTerrainCompiledArtifact = result["artifact"]
	if artifact.map_content_hash != map.content_hash():
		return _failure("compiled terrain does not match the current map content hash")
	if artifact.cols != map.cols() or artifact.rows != map.rows():
		return _failure("compiled terrain dimensions do not match the current map")
	return result

func load_artifact(directory: String, expected_map_id: String = "") -> Dictionary:
	var manifest_path := directory.path_join(MANIFEST_NAME)
	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		return _failure("compiled terrain manifest is missing: %s" % manifest_path)
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	if not parsed is Dictionary:
		return _failure("compiled terrain manifest is not valid JSON")
	var manifest: Dictionary = parsed
	for field in [
		"mapId", "mapContentHash", "authoringProfileHash",
		"generatedBaseHash", "generatorVersion", "raster", "authoring", "layers",
	]:
		if not manifest.has(field):
			return _failure("compiled terrain manifest is missing %s" % field)
	var map_id := str(manifest["mapId"])
	if not expected_map_id.is_empty() and map_id != expected_map_id:
		return _failure("compiled terrain mapId does not match %s" % expected_map_id)
	for field in ["mapContentHash", "authoringProfileHash", "generatedBaseHash"]:
		if not _is_sha256(str(manifest[field])):
			return _failure("compiled terrain %s is not a SHA-256 hash" % field)
	if not manifest["raster"] is Dictionary or not manifest["authoring"] is Dictionary:
		return _failure("compiled terrain raster or authoring metadata is invalid")
	var raster: Dictionary = manifest["raster"]
	var authoring: Dictionary = manifest["authoring"]
	for field in ["width", "height", "sampleSpacingMeters", "worldMinMeters"]:
		if not raster.has(field):
			return _failure("compiled terrain raster is missing %s" % field)
	for field in [
		"cols", "rows", "hexRadiusMeters", "maxTerrainHeightMeters",
		"worldOriginMeters", "referenceTransform", "cityCoreRadiusMeters", "maxCitySlope",
	]:
		if not authoring.has(field):
			return _failure("compiled terrain authoring metadata is missing %s" % field)
	var width := int(raster["width"])
	var height := int(raster["height"])
	var spacing := float(raster["sampleSpacingMeters"])
	if width < 2 or height < 2 or spacing <= 0.0:
		return _failure("compiled terrain raster dimensions are invalid")
	var layers_result := _load_layers(directory, manifest["layers"], Vector2i(width, height))
	if not layers_result["ok"]:
		return layers_result
	if layers_result["base_hash"] != str(manifest["generatedBaseHash"]):
		return _failure("generatedBaseHash does not match the base raster hash")
	var world_min_result := _vector2_xz(raster["worldMinMeters"], "worldMinMeters")
	if not world_min_result["ok"]:
		return world_min_result
	var world_origin_result := _vector3(authoring["worldOriginMeters"], "worldOriginMeters")
	if not world_origin_result["ok"]:
		return world_origin_result
	var reference_result := _reference_transform(authoring["referenceTransform"])
	if not reference_result["ok"]:
		return reference_result
	var max_city_slope_result := _optional_non_negative_float(
		authoring["maxCitySlope"],
		"maxCitySlope",
	)
	if not max_city_slope_result["ok"]:
		return max_city_slope_result
	var max_terrain_height := float(authoring["maxTerrainHeightMeters"])
	if not is_finite(max_terrain_height) or max_terrain_height <= 0.0:
		return _failure("maxTerrainHeightMeters must be finite and positive")

	var artifact := Artifact.new()
	artifact.directory = directory
	artifact.map_id = map_id
	artifact.map_content_hash = str(manifest["mapContentHash"])
	artifact.authoring_profile_hash = str(manifest["authoringProfileHash"])
	artifact.generated_base_hash = str(manifest["generatedBaseHash"])
	artifact.generator_version = str(manifest["generatorVersion"])
	artifact.width = width
	artifact.height = height
	artifact.sample_spacing_meters = spacing
	artifact.world_min_meters = world_min_result["value"]
	artifact.world_origin_meters = world_origin_result["value"]
	artifact.cols = int(authoring["cols"])
	artifact.rows = int(authoring["rows"])
	artifact.hex_radius_meters = float(authoring["hexRadiusMeters"])
	artifact.max_terrain_height_meters = max_terrain_height
	artifact.reference_translation_meters = reference_result["translation"]
	artifact.reference_rotation_degrees = reference_result["rotation"]
	artifact.reference_scale = reference_result["scale"]
	artifact.city_core_radius_meters = float(authoring["cityCoreRadiusMeters"])
	artifact.max_city_slope = max_city_slope_result["value"]
	artifact.base_image = layers_result["base"]
	artifact.minimum_image = layers_result["min"]
	artifact.maximum_image = layers_result["max"]
	return {"ok": true, "artifact": artifact}

func _load_layers(directory: String, raw: Variant, size: Vector2i) -> Dictionary:
	if not raw is Dictionary:
		return _failure("compiled terrain layers are invalid")
	var result := {"ok": true}
	for layer_name in ["base", "min", "max"]:
		if not raw.has(layer_name) or not raw[layer_name] is Dictionary:
			return _failure("compiled terrain layer %s is missing" % layer_name)
		var layer: Dictionary = raw[layer_name]
		for field in ["openExr", "openExrSha256", "hash"]:
			if not layer.has(field):
				return _failure("compiled terrain layer %s is missing %s" % [layer_name, field])
		if not _is_sha256(str(layer["hash"])):
			return _failure("compiled terrain layer %s has an invalid raster hash" % layer_name)
		var file_name := str(layer["openExr"])
		if file_name.get_file() != file_name or file_name.get_extension().to_lower() != "exr":
			return _failure("compiled terrain layer %s has an unsafe EXR path" % layer_name)
		var path := directory.path_join(file_name)
		var expected_hash := str(layer["openExrSha256"])
		if not _is_sha256(expected_hash):
			return _failure("compiled terrain layer %s has an invalid file hash" % layer_name)
		var image_result := _load_layer(path, expected_hash, layer_name)
		if not image_result["ok"]:
			return image_result
		var image: Image = image_result["image"]
		if image.get_size() != size:
			return _failure("compiled terrain layer %s has invalid dimensions" % layer_name)
		if image.get_format() not in [Image.FORMAT_RF, Image.FORMAT_RGBF, Image.FORMAT_RGBAF]:
			return _failure("compiled terrain layer %s is not 32-bit float" % layer_name)
		result[layer_name] = image
		result["%s_hash" % layer_name] = str(layer["hash"])
	return result

func _load_layer(path: String, expected_hash: String, layer_name: String) -> Dictionary:
	if OS.has_feature("editor"):
		var absolute_path := ProjectSettings.globalize_path(path)
		if FileAccess.get_sha256(absolute_path) != expected_hash:
			return _failure(
				"compiled terrain layer %s failed SHA-256 verification" % layer_name
			)
		if not path.begins_with(IMPORTED_RUNTIME_ROOT):
			var source_image := Image.load_from_file(path)
			if source_image == null:
				return _failure("compiled terrain layer %s cannot be decoded" % layer_name)
			return {"ok": true, "image": source_image}
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		return _failure("compiled terrain layer %s import is missing" % layer_name)
	var imported_image := texture.get_image()
	if imported_image == null:
		return _failure("compiled terrain layer %s import cannot be decoded" % layer_name)
	return {"ok": true, "image": imported_image}

func _reference_transform(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return _failure("referenceTransform is invalid")
	for field in ["translationMeters", "rotationDegrees", "scale"]:
		if not raw.has(field):
			return _failure("referenceTransform is missing %s" % field)
	var translation := _vector3(raw["translationMeters"], "reference translation")
	var rotation := _vector3(raw["rotationDegrees"], "reference rotation")
	var scale := _vector3(raw["scale"], "reference scale")
	for result in [translation, rotation, scale]:
		if not result["ok"]:
			return result
	var scale_value: Vector3 = scale["value"]
	if scale_value.x <= 0.0 or scale_value.y <= 0.0 or scale_value.z <= 0.0:
		return _failure("reference scale must be positive")
	return {
		"ok": true,
		"translation": translation["value"],
		"rotation": rotation["value"],
		"scale": scale_value,
	}

func _vector2_xz(raw: Variant, label: String) -> Dictionary:
	if not raw is Dictionary or not raw.has("x") or not raw.has("z"):
		return _failure("%s is invalid" % label)
	var value := Vector2(float(raw["x"]), float(raw["z"]))
	return {"ok": true, "value": value} if value.is_finite() else _failure("%s is not finite" % label)

func _vector3(raw: Variant, label: String) -> Dictionary:
	if not raw is Dictionary:
		return _failure("%s is invalid" % label)
	for axis in ["x", "y", "z"]:
		if not raw.has(axis):
			return _failure("%s is missing %s" % [label, axis])
	var value := Vector3(float(raw["x"]), float(raw["y"]), float(raw["z"]))
	return {"ok": true, "value": value} if value.is_finite() else _failure("%s is not finite" % label)

func _optional_non_negative_float(raw: Variant, label: String) -> Dictionary:
	if raw == null:
		return {"ok": true, "value": null}
	if not raw is int and not raw is float:
		return _failure("%s is not a number" % label)
	var value := float(raw)
	if not is_finite(value) or value < 0.0:
		return _failure("%s must be finite and non-negative" % label)
	return {"ok": true, "value": value}

func _is_sha256(value: String) -> bool:
	if value.length() != 64:
		return false
	for character in value:
		if character not in "0123456789abcdef":
			return false
	return true

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
