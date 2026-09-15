extends SceneTree
const Classifier := preload("res://editor/map_authoring/infrastructure/terrain/reference_feature_classifier.gd")
const Plan := preload("res://editor/map_authoring/infrastructure/terrain/reference_surface_plan.gd")
const Water := preload("res://editor/map_authoring/presentation/reference_water_surface.gd")
const Hydrology := preload("res://editor/map_authoring/infrastructure/terrain/reference_hydrology.gd")
const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")

func _initialize() -> void:
	var prior := PackedFloat32Array([0.4, 0.6, 0.0, 0.0, 0.0, 0.0])
	var dark := Color(0.12, 0.22, 0.06)
	var light := Color(0.7, 0.68, 0.25)
	var forest := Classifier.classify(prior, dark, dark, 1.0, 0.3, 1.0)
	var clearing := Classifier.classify(prior, light, light, 1.0, 0.3, 1.0)
	assert(forest["canopy"] > clearing["canopy"] + 0.3)
	assert(Classifier.classify(prior, dark, dark, 1.0, 0.3, 0.0)["weights"] == prior)
	for color in [dark, light, Color.WHITE, Color.BLACK, Color(0.05, 0.3, 0.6)]:
		var classified := Classifier.classify(prior, color, color, 0.5, 0.3, 0.85)
		var sum := 0.0
		for weight in classified["weights"]:
			assert(is_finite(weight) and weight >= 0.0)
			sum += weight
		assert(is_equal_approx(sum, 1.0))
	var source := AonwTerrainCompiledArtifact.new()
	source.map_id = "features"
	source.cols = 2
	source.rows = 2
	source.hex_radius_meters = 10.0
	source.width = 36
	source.height = 45
	source.world_min_meters = Vector2(-10, -8.660254)
	source.sample_spacing_meters = 1.0
	var document := {"mapName": "features", "cols": 2, "rows": 2, "tiles": []}
	for y in 2:
		for x in 2:
			document["tiles"].append({"col": x, "row": y, "height": 1, "terrainTags": ["forest"]})
	var image := Image.create(100, 100, false, Image.FORMAT_RGBA8)
	image.fill(dark)
	var water := Image.create(36, 45, false, Image.FORMAT_L8)
	water.fill(Color.BLACK)
	water.fill_rect(Rect2i(10, 10, 16, 20), Color.WHITE)
	var plan := Plan.new()
	assert(plan.configure(source, image, document, water, true)["ok"])
	var masks := plan.surface_masks(Parameters.defaults())
	assert(masks["shore_distance"].get_pixel(0, 0).r == 0.0, "Dry land has no water depth")
	assert(masks["shore_distance"].get_pixel(17, 18).r > masks["shore_distance"].get_pixel(10, 18).r)
	assert(masks["water"].get_data() == water.get_data(), "Rendering must not mutate hydrology")
	var node := Water.build(masks, Vector2(35, 44), true)
	Water.apply(node, Parameters.defaults())
	assert(node.owner == null)
	assert(node.mesh.size == Vector2(35, 44))
	assert(node.position == Vector3(17.5, 0.09, 22.0))
	assert(node.material_override.get_shader_parameter("water_depth") == 8.0)
	node.free()
	# Myranth regression: blue shadows touching the ocean flooded snowy mountains.
	image.fill(Color(0.1, 0.4, 0.6))
	for tile in document["tiles"]:
		tile["terrainTags"] = ["ocean"] if tile["col"] == 0 else ["snow", "mountain"]
	var heights := PackedFloat32Array()
	heights.resize(source.width * source.height)
	heights.fill(1.0)
	var hydro := Hydrology.new().sample(source, image, heights, document)
	assert(hydro["ok"] and hydro["water"][26 * source.width + 25] == 0, "Ocean-connected snow shadows must remain dry")
	var guide := Image.create(100, 100, false, Image.FORMAT_L8)
	guide.fill(Color.WHITE)
	var override := Hydrology.new().sample(source, image, heights, document, {"water": guide})
	assert(override["ok"] and override["water"][26 * source.width + 25] == 1, "An explicit water guide remains authoritative")
	print("PASS reference features: canopy evidence, normalized weights, water depth, separate surface")
	quit(0)
