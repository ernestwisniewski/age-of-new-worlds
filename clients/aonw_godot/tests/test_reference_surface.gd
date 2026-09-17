extends SceneTree
const Plan := preload("res://editor/map_authoring/infrastructure/terrain/reference_surface_plan.gd")
const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
const Forest := preload("res://editor/map_authoring/presentation/reference_forest.gd")

class HeightField extends RefCounted:
	var incline := 0.0
	var invalid := false
	func get_height(point: Vector3) -> float:
		return NAN if invalid else 2.0 + point.x * incline

func _initialize() -> void:
	for tags in [[], ["forest"], ["desert"], ["snow"], ["mountain"], ["swamp"], ["tundra"], ["river"]]:
		var sum := 0.0
		for weight in Plan.biome_weights(tags):
			assert(weight >= 0.0)
			sum += weight
		assert(is_equal_approx(sum, 1.0), "Biome weights must be normalized")
	assert(Plan.biome_weights(["forest"])[1] > 0.8)
	assert(Plan.biome_weights(["snow"])[3] > 0.9)
	assert(Plan.canopy_probability(["plains"], Color.DARK_GREEN, true, 1.0) == 0.0)
	assert(Plan.canopy_probability(["forest", "desert"], Color.DARK_GREEN, true, 1.0) == 0.0)
	assert(Plan.canopy_probability(["forest"], Color(0.1, 0.3, 0.09), true, 1.0)
		> Plan.canopy_probability(["forest"], Color(0.85, 0.8, 0.6), true, 1.0))
	var source := AonwTerrainCompiledArtifact.new()
	source.map_id = "fixture"
	source.cols = 4
	source.rows = 4
	source.hex_radius_meters = 8.0
	source.width = 65
	source.height = 65
	source.sample_spacing_meters = 1.0
	source.world_min_meters = Vector2(-8.0, -7.0)
	var document := {"mapName": "fixture", "cols": 4, "rows": 4, "tiles": []}
	for row in 4:
		for col in 4:
			document["tiles"].append({"col": col, "row": row, "height": 1, "terrainTags": ["forest"]})
	var reference := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	reference.fill(Color(0.1, 0.3, 0.09))
	var water := Image.create(65, 65, false, Image.FORMAT_L8)
	water.fill(Color.BLACK)
	water.fill_rect(Rect2i(0, 0, 24, 65), Color.WHITE)
	var plan := Plan.new()
	assert(plan.configure(source, reference, document, water, true)["ok"])
	var values := Parameters.defaults()
	values["tree_density"] = 1.0
	values["tree_reference_strength"] = 0.0
	values["forest_distribution"] = 0.0
	var first := plan.forest_candidates(values)
	assert(not first.is_empty())
	assert(first == plan.forest_candidates(values), "Rebuild must retain deterministic placement")
	for entry in first:
		var local: Vector3 = entry["position"]
		assert(local.x > 24.0, "No tree root may enter the reconstructed water footprint")
	values["tree_density"] = 0.0
	assert(plan.forest_candidates(values).is_empty())
	assert(not Parameters.geometry(values).has("tree_density"), "Appearance must not alter the geometry recipe")
	var masks := plan.surface_masks()
	assert(masks["ground"].get_width() <= 512)
	var wrong := document.duplicate(true)
	wrong["mapName"] = "other_map"
	assert(not Plan.new().configure(source, reference, wrong, water, true)["ok"])
	var field := HeightField.new()
	assert(is_equal_approx(Forest.ground_sample(field, Vector3.ZERO, 1.0)["height"], 2.0))
	field.incline = 1.0
	assert(is_equal_approx(Forest.ground_sample(field, Vector3.ZERO, 1.0)["up"], cos(PI / 4.0)))
	field.invalid = true
	assert(not Forest.ground_sample(field, Vector3.ZERO, 1.0)["ok"])
	print("PASS reference surface: biomes, deterministic forest, water, slopes and appearance isolation")
	quit(0)
