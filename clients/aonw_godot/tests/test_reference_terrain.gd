extends SceneTree
## Deterministic raster contracts. This suite never writes map assets or drafts.

const Builder := preload("res://editor/map_authoring/infrastructure/terrain/reference_terrain_builder.gd")
const Hydrology := preload("res://editor/map_authoring/infrastructure/terrain/reference_hydrology.gd")
const Artifact := preload("res://game/application/terrain/terrain_compiled_artifact.gd")
const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
var _failures := PackedStringArray()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var source := _fixture()
	var document := _document(source)
	var reference := Image.create(source.width, source.height, false, Image.FORMAT_RGBA8)
	reference.fill(Color(0.35, 0.48, 0.28))
	var original := source.base_image.get_data()
	var original_minimum := source.minimum_image.get_data()
	var original_maximum := source.maximum_image.get_data()
	var builder := Builder.new()
	var first := builder.build_reference(source, reference, document)
	if not _check(first["ok"], "Fixture builds"):
		_finish()
		return
	var result: AonwTerrainCompiledArtifact = first["artifact"]
	var again := builder.build_reference(source, reference, document)
	_check(again["ok"], "Repeated build succeeds")
	if again["ok"]:
		_check(result.base_image.get_data() == again["artifact"].base_image.get_data(), "Deterministic raster")
		_check(first["workspace_key"] == again["workspace_key"], "Deterministic draft identity")
	_check(source.base_image.get_data() == original, "Canonical base is unchanged")
	_check(source.minimum_image.get_data() == original_minimum, "Canonical minimum is unchanged")
	_check(source.maximum_image.get_data() == original_maximum, "Canonical maximum is unchanged")
	_check(result.map_content_hash == source.map_content_hash, "Gameplay identity is retained")
	_check(result.generator_version == Builder.REFERENCE_VERSION, "Presentation version is explicit")
	_check(first["changed_samples"] > 100, "Relief changes real geometry")
	_check(result.base_image.get_format() == Image.FORMAT_RF, "Float-metre output")
	_validate_envelope(result)
	var changed_seed := builder.build_reference(source, reference, document, 9901)
	_check(changed_seed["ok"], "Alternative seed builds")
	if changed_seed["ok"]:
		_check(first["workspace_key"] != changed_seed["workspace_key"], "Seed changes isolate drafts")
	# Water cuts straight through a mountain: erosion and envelopes must never fill it.
	var water := Image.create(source.width, source.height, false, Image.FORMAT_L8)
	water.fill(Color.BLACK)
	water.fill_rect(Rect2i(40, 0, 3, source.height), Color.WHITE)
	water.fill_rect(Rect2i(55, 25, 10, 9), Color.WHITE)
	var wet := builder.build_reference(source, reference, document, 73129, 1.65, 1.0, {"water": water})
	_check(wet["ok"], "River and lake mask builds")
	if wet["ok"]:
		_check(wet["water_samples"] > 100, "Water footprints survive rasterization")
		var artifact: AonwTerrainCompiledArtifact = wet["artifact"]
		var mask: Image = wet["water_mask"]
		for y in source.height:
			for x in source.width:
				if mask.get_pixel(x, y).r < 0.5:
					continue
				var pixel := Vector2i(x, y)
				_check(artifact.base_image.get_pixelv(pixel).r == 0.0, "Water stays exactly zero after erosion")
				_check(artifact.minimum_at(pixel) == 0.0 and artifact.maximum_at(pixel) == 0.0, "Water cannot be sculpted above zero")
		_validate_envelope(artifact)
	water.fill(Color.WHITE)
	var sea := builder.build_reference(source, reference, document, 73129, 1.65, 1.0, {"water": water})
	_check(sea["ok"], "All-water reconstruction builds")
	if sea["ok"]:
		_check(sea["water_samples"] == source.width * source.height, "No procedural islands in water")
	# Explicit image ridges move the geometry, not just the shader or a file hash.
	var ridge := Image.create(source.width, source.height, false, Image.FORMAT_L8)
	ridge.fill(Color.BLACK)
	var valley := builder.build_reference(source, reference, document, 73129, 1.65, 1.0, {"ridges": ridge})
	ridge.fill(Color.WHITE)
	var crest := builder.build_reference(source, reference, document, 73129, 1.65, 1.0, {"ridges": ridge})
	_check(valley["ok"] and crest["ok"], "Ridge guides build")
	if valley["ok"] and crest["ok"]:
		_check(crest["artifact"].base_image.get_pixel(48, 35).r > valley["artifact"].base_image.get_pixel(48, 35).r, "Reference crests control altitude")
		_check(crest["workspace_key"] != valley["workspace_key"], "Guide edits isolate drafts")
	reference.fill_rect(Rect2i(32, 20, 12, 30), Color(0.9, 0.9, 0.9))
	var illustrated := builder.build_reference(source, reference, document)
	_check(illustrated["ok"], "Illustrated ridge builds")
	if illustrated["ok"]:
		_check(illustrated["artifact"].generated_base_hash != result.generated_base_hash, "Reference texture changes mountain geometry")
	_check(not builder.build_reference(source, reference, document, 1, NAN)["ok"], "Reject NaN scale")
	_check(not builder.build_reference(source, reference, document, 2147483648)["ok"], "Reject overflowing seed")
	_check(not builder.build_reference(null, reference, document)["ok"], "Reject missing source")
	var invalid := document.duplicate(true)
	invalid["tiles"][1] = invalid["tiles"][0].duplicate(true)
	_check(not builder.build_reference(source, reference, invalid)["ok"], "Reject duplicate map coordinates")
	var wrong_size := Image.create(2, 2, false, Image.FORMAT_L8)
	_check(not builder.build_reference(source, reference, document, 1, 1.0, 1.0, {"water": wrong_size})["ok"], "Reject misaligned guides")
	source.base_image.set_pixel(0, 0, Color(INF, 0, 0))
	_check(not builder.build_reference(source, reference, document)["ok"], "Reject infinite source height")
	_test_hydrology()
	_finish()

func _test_hydrology() -> void:
	var hydrology := Hydrology.new()
	_check(hydrology.is_water_color(Color(0.1, 0.4, 0.6)), "Recognize blue water")
	_check(not hydrology.is_water_color(Color(0.9, 0.92, 0.95)), "Do not confuse snow and water")
	_check(not hydrology.is_water_color(Color(0.2, 0.5, 0.2)), "Do not confuse forest and water")
	var mask := PackedByteArray()
	mask.resize(25)
	mask[12] = 1
	var distance := hydrology.distance_to_water(mask, 5, 5)
	_check(distance[12] == 0.0, "Water distance is zero")
	_check(distance[11] == 1.0 and distance[7] == 1.0, "Banks are symmetric")
	_check(absf(distance[6] - sqrt(2.0)) < 0.00001, "Diagonal banks are not square")
	var source := _fixture()
	var document := _document(source)
	var reference := Image.create(source.width, source.height, false, Image.FORMAT_RGBA8)
	reference.fill(Color(0.2, 0.5, 0.2))
	reference.fill_rect(Rect2i(40, 10, 3, source.height - 20), Color(0.1, 0.4, 0.6))
	var original := source.base_image.get_data().to_float32_array()
	var unseeded := hydrology.sample(source, reference, original, document)
	_check(unseeded["ok"], "Unseeded reference samples")
	# All source heights are positive and all tags are land: blue paint by itself
	# must not be interpreted as a connected river or lake.
	if unseeded["ok"]:
		_check(unseeded["water"][35 * source.width + 41] == 0, "Unseeded blue shadows remain land")
	for tile in document["tiles"]:
		tile["terrainTags"] = ["river"]
	var seeded := hydrology.sample(source, reference, original, document)
	_check(seeded["ok"], "Seeded river samples")
	if seeded["ok"]:
		_check(seeded["water"][35 * source.width + 41] == 1, "Reference river crosses tile boundaries")
		_check(seeded["water"][35 * source.width + 30] == 0, "River tags do not flatten the whole hex")

func _validate_envelope(artifact: AonwTerrainCompiledArtifact) -> void:
	for y in artifact.height:
		for x in artifact.width:
			var p := Vector2i(x, y)
			var value := artifact.base_image.get_pixelv(p).r
			_check(is_finite(value) and value >= 0.0, "Finite non-negative terrain")
			_check(value >= artifact.minimum_at(p) and value <= artifact.maximum_at(p), "Continuous sculpt envelope encloses terrain")
			_check(artifact.maximum_at(p) <= artifact.max_terrain_height_meters, "Bounds include all summits")

func _fixture() -> AonwTerrainCompiledArtifact:
	var source := Artifact.new()
	source.map_id = "fixture"
	source.map_content_hash = "a".repeat(64)
	source.authoring_profile_hash = "b".repeat(64)
	source.generated_base_hash = "c".repeat(64)
	source.generator_version = "canonical-fixture/1"
	source.cols = 6
	source.rows = 4
	source.hex_radius_meters = 10.0
	var bounds := Geometry.new(source.cols, source.rows, source.hex_radius_meters).bounds()
	source.width = ceili(bounds.size.x) + 1
	source.height = ceili(bounds.size.y) + 1
	source.world_min_meters = bounds.position
	source.world_origin_meters = Vector3.ZERO
	source.reference_scale = Vector3.ONE
	source.sample_spacing_meters = 1.0
	source.max_terrain_height_meters = 20.0
	source.city_core_radius_meters = 4.0
	source.base_image = Image.create(source.width, source.height, false, Image.FORMAT_RF)
	source.base_image.fill(Color(4.0, 0, 0))
	source.base_image.fill_rect(Rect2i(18, 15, 60, 48), Color(18.0, 0, 0))
	source.minimum_image = source.base_image.duplicate()
	source.maximum_image = source.base_image.duplicate()
	return source

func _document(source: AonwTerrainCompiledArtifact) -> Dictionary:
	var tiles := []
	for row in source.rows:
		for col in source.cols:
			tiles.append({"col": col, "row": row, "height": 3, "terrainTags": ["plains"]})
	return {"mapName": source.map_id, "cols": source.cols, "rows": source.rows, "tiles": tiles}

func _check(condition: bool, message: String) -> bool:
	if not condition and not _failures.has(message):
		_failures.append(message)
	return condition

func _finish() -> void:
	for failure in _failures:
		push_error(failure)
	print("Reference terrain: PASS" if _failures.is_empty() else "Reference terrain: FAIL")
	quit(0 if _failures.is_empty() else 1)
