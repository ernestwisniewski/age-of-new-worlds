extends SceneTree
## Proves every geometry parameter changes samples, not only an identity hash.

const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
const Builder := preload("res://editor/map_authoring/infrastructure/terrain/reference_terrain_builder.gd")
const Artifact := preload("res://game/application/terrain/terrain_compiled_artifact.gd")
const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
var _failures := PackedStringArray()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var source := Artifact.new()
	source.map_id = "parameter_fixture"
	source.cols = 6
	source.rows = 4
	source.hex_radius_meters = 10.0
	source.sample_spacing_meters = 1.0
	var bounds := Geometry.new(6, 4, 10.0).bounds()
	source.world_min_meters = bounds.position
	source.reference_scale = Vector3.ONE
	source.width = ceili(bounds.size.x) + 1
	source.height = ceili(bounds.size.y) + 1
	source.max_terrain_height_meters = 90.0
	source.map_content_hash = "a".repeat(64)
	source.authoring_profile_hash = "b".repeat(64)
	source.base_image = Image.create(source.width, source.height, false, Image.FORMAT_RF)
	source.base_image.fill(Color(72.0, 0, 0))
	source.minimum_image = source.base_image.duplicate()
	source.maximum_image = source.base_image.duplicate()
	var original := source.base_image.get_data()
	var document := {"mapName": source.map_id, "cols": 6, "rows": 4, "tiles": []}
	for y in 4:
		for x in 6:
			document["tiles"].append({"col": x, "row": y, "height": 4, "terrainTags": ["mountains" if x < 3 else "hills"]})
	var reference := Image.create(source.width, source.height, false, Image.FORMAT_RGBA8)
	var water := Image.create(source.width, source.height, false, Image.FORMAT_L8)
	water.fill(Color.BLACK)
	water.fill_rect(Rect2i(44, 0, 3, source.height), Color.WHITE)
	for y in source.height:
		for x in source.width:
			var value := 0.5 + 0.3 * sin(float(x) * 0.4 + sin(float(y) * 0.15))
			reference.set_pixel(x, y, Color(value, value, value))
	var parameters := Parameters.defaults(90.0)
	var builder := Builder.new()
	var baseline := builder.build_reference(source, reference, document, 73129, 1.65, 1.0, {"water": water}, parameters)
	if not baseline["ok"]:
		push_error(str(baseline["message"]))
		quit(1)
		return
	var variants := {"level_height": 120.0, "mountain_scale": 2.5, "hill_scale": 1.5,
		"reference_strength": 0.0, "ridge_sharpness": 2.8, "smoothing": 1.2,
		"detail_strength": 0.09, "detail_scale": 1.5, "bank_width": 0.9,
		"erosion_passes": 0.0, "seed": 9901.0}
	_check(variants.size() == Parameters.geometry(parameters).size(), "All geometry parameters have sensitivity tests")
	for key in variants:
		var options := parameters.duplicate(true)
		options[key] = variants[key]
		var result := builder.build_reference(source, reference, document, 73129, 1.65, 1.0, {"water": water}, options)
		_check(result["ok"], "Build succeeds for " + key)
		if not result["ok"]:
			continue
		var artifact: AonwTerrainCompiledArtifact = result["artifact"]
		_check(artifact.base_image.get_data() != baseline["artifact"].base_image.get_data(), "Sample sensitivity: " + key)
		var mask: Image = result["water_mask"]
		for y in source.height:
			for x in source.width:
				if mask.get_pixel(x, y).r > 0.5:
					var pixel := Vector2i(x, y)
					_check(artifact.base_image.get_pixelv(pixel).r == 0.0 and artifact.maximum_at(pixel) == 0.0, "Water lock: " + key)
	parameters["camera_pitch"] = 70.0
	parameters["sun_energy"] = 2.0
	var appearance := builder.build_reference(source, reference, document, 73129, 1.65, 1.0, {"water": water}, parameters)
	_check(appearance["ok"] and appearance["workspace_key"] == baseline["workspace_key"], "Visual options reuse the same sculpt")
	_check(source.base_image.get_data() == original, "Source image is not mutated")
	var changed := document.duplicate(true)
	changed["tiles"][8]["height"] = 1
	var changed_result := builder.build_reference(source, reference, changed, 73129, 1.65, 1.0, {"water": water}, parameters)
	_check(changed_result["ok"] and changed_result["artifact"].generated_base_hash != baseline["artifact"].generated_base_hash, "JSON heights participate directly")
	changed["tiles"][8]["height"] = 6
	_check(not builder.build_reference(source, reference, changed)["ok"], "Reject invalid JSON heights")
	for failure in _failures:
		push_error(failure)
	print("Reference parameter effects: PASS" if _failures.is_empty() else "Reference parameter effects: FAIL")
	quit(0 if _failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
