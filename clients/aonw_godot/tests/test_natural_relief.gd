extends SceneTree
## Pure raster tests. No native terrain mutation, draft writes or gameplay calls.

const Builder := preload("res://editor/map_authoring/infrastructure/terrain/natural_relief_builder.gd")
const Artifact := preload("res://game/application/terrain/terrain_compiled_artifact.gd")
var _failures := PackedStringArray()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var builder := Builder.new()
	var source := _fixture()
	var reference := Image.create(source.width, source.height, false, Image.FORMAT_RGBA8)
	reference.fill(Color(0.4, 0.4, 0.4, 1.0))
	var original := source.base_image.get_data()
	var original_minimum := source.minimum_image.get_data()
	var original_maximum := source.maximum_image.get_data()
	var first := builder.build(source, reference)
	if not _check(first["ok"], "Relief fixture builds"):
		_finish()
		return
	var result: AonwTerrainCompiledArtifact = first["artifact"]
	var again := builder.build(source, reference)
	_check(again["ok"], "Repeated relief build succeeds")
	if again["ok"]:
		_check(result.base_image.get_data() == again["artifact"].base_image.get_data(), "Same recipe is deterministic")
		_check(first["workspace_key"] == again["workspace_key"], "Same recipe restores the same draft")
	var next_seed := builder.build(source, reference, 8821)
	_check(next_seed["ok"], "Alternative seed builds")
	if next_seed["ok"]:
		_check(result.generated_base_hash != next_seed["artifact"].generated_base_hash, "Seed changes summit geometry")
		_check(first["workspace_key"] != next_seed["workspace_key"], "Other recipes never overwrite this draft")
	_check(source.base_image.get_data() == original, "Canonical base is untouched")
	_check(source.minimum_image.get_data() == original_minimum, "Canonical minimum is untouched")
	_check(source.maximum_image.get_data() == original_maximum, "Canonical maximum is untouched")
	_check(source.generator_version == "aonw-map-compiler/1", "Canonical identity is untouched")
	_check(result.map_content_hash == source.map_content_hash, "Gameplay map identity is preserved")
	_check(result.sample_spacing_meters == 1.0, "Raster remains metre-scaled")
	_check(result.generator_version == Builder.VERSION, "Presentation generator is identified explicitly")
	_check(result.base_image.get_format() == Image.FORMAT_RF, "Terrain3D receives float metre heights")
	var varied_plateau_samples := 0
	var relaxed_hex_limits := 0
	var highest := 0.0
	for y in source.height:
		for x in source.width:
			var p := Vector2i(x, y)
			var before := source.base_image.get_pixelv(p).r
			var after := result.base_image.get_pixelv(p).r
			highest = maxf(highest, after)
			_check(is_finite(after), "No NaN/Infinity heights")
			_check(after >= result.minimum_at(p) and after <= result.maximum_at(p), "Sculpt envelope encloses the generated height")
			if before == 0.0:
				_check(after == before, "Water is not raised or eroded into")
				_check(result.minimum_at(p) == 0.0 and result.maximum_at(p) == 0.0, "Water constraints stay locked")
			if before == 18.5 and x > 0:
				if absf(after - result.base_image.get_pixel(x - 1, y).r) > 0.01:
					varied_plateau_samples += 1
				if result.minimum_at(p) < source.minimum_at(p):
					relaxed_hex_limits += 1
	_check(varied_plateau_samples > 100, "Flat mountain interiors become slopes and ridges")
	_check(relaxed_hex_limits > 0, "Old hex-wise lower bounds do not recreate plateaus")
	_check(highest > 1.0, "Heights are NOT incorrectly clamped to 0..1")
	_check(result.max_terrain_height_meters >= highest, "Camera bounds include the new summits")
	_check(first["changed_samples"] > 100, "The heightmap, not only the shader, changes")
	reference.fill_rect(Rect2i(48, 35, 12, 10), Color.WHITE)
	var guided := builder.build(source, reference)
	_check(guided["ok"] and guided["artifact"].generated_base_hash != result.generated_base_hash, "Local reference detail affects mountain geometry")
	var sea := _fixture()
	sea.base_image.fill(Color(0, 0, 0))
	var sea_result := builder.build(sea, reference)
	_check(sea_result["ok"], "All-water input is valid")
	if sea_result["ok"]:
		_check(sea_result["changed_samples"] == 0, "No procedural islands on an all-water map")
	_check(not builder.build(source, reference, 7, NAN)["ok"], "Reject non-finite scale")
	_check(not builder.build(source, reference, 7, 1.0, -1.0)["ok"], "Reject invalid image-detail strength")
	source.base_image.set_pixel(0, 0, Color(NAN, 0, 0))
	_check(not builder.build(source, reference)["ok"], "Reject non-finite source heights")
	_test_raster_kernels(builder)
	_finish()

func _test_raster_kernels(builder: Builder) -> void:
	var flat := PackedFloat32Array()
	flat.resize(25)
	flat.fill(12.0)
	_check(builder._smooth(flat, 5, 5, 2, 3) == flat, "Smoothing preserves a constant field")
	var spike := flat.duplicate()
	spike[12] = 24.0
	var dry := flat.duplicate()
	dry.fill(1.0)
	var relaxed: PackedFloat32Array = builder._relax_talus(spike, dry, 5, 5, 1.3)
	var total_before := 0.0
	var total_after := 0.0
	for index in spike.size():
		total_before += spike[index]
		total_after += relaxed[index]
	_check(absf(total_before - total_after) < 0.001, "Talus transfer conserves material")
	_check(relaxed[12] < spike[12], "Excessively steep tips shed material")
	dry.fill(0.0)
	_check(builder._relax_talus(spike, dry, 5, 5, 1.3) == spike, "Protected samples do not erode")

func _fixture() -> AonwTerrainCompiledArtifact:
	var source := Artifact.new()
	source.directory = "res://test-fixture"
	source.map_id = "dravonia"
	source.map_content_hash = "a".repeat(64)
	source.authoring_profile_hash = "b".repeat(64)
	source.generated_base_hash = "c".repeat(64)
	source.generator_version = "aonw-map-compiler/1"
	source.cols = 8
	source.rows = 5
	source.width = 126
	source.height = 97
	source.hex_radius_meters = 10.0
	source.sample_spacing_meters = 1.0
	source.world_min_meters = Vector2(-10, -sqrt(3.0) * 5.0)
	source.world_origin_meters = Vector3.ZERO
	source.reference_scale = Vector3.ONE
	source.max_terrain_height_meters = 18.5
	source.city_core_radius_meters = 4.0
	source.base_image = Image.create(source.width, source.height, false, Image.FORMAT_RF)
	source.minimum_image = Image.create(source.width, source.height, false, Image.FORMAT_RF)
	source.maximum_image = Image.create(source.width, source.height, false, Image.FORMAT_RF)
	for y in source.height:
		for x in source.width:
			var height_value := 0.0
			if x > 8 and y > 8 and x < source.width - 9 and y < source.height - 9:
				height_value = 3.7
			if x > 24 and y > 22 and x < source.width - 24 and y < source.height - 22:
				height_value = 18.5
			source.base_image.set_pixel(x, y, Color(height_value, 0, 0))
			source.minimum_image.set_pixel(x, y, Color(height_value - 1.85, 0, 0))
			source.maximum_image.set_pixel(x, y, Color(height_value + 3.7, 0, 0))
	return source

func _check(condition: bool, message: String) -> bool:
	if not condition and not _failures.has(message):
		_failures.append(message)
	return condition

func _finish() -> void:
	for failure in _failures:
		push_error(failure)
	print("Natural relief: PASS" if _failures.is_empty() else "Natural relief: FAIL")
	quit(0 if _failures.is_empty() else 1)
