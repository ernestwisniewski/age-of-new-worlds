extends SceneTree
const Patches := preload("res://editor/map_authoring/infrastructure/terrain/forest_patch_field.gd")
const Plan := preload("res://editor/map_authoring/infrastructure/terrain/reference_surface_plan.gd")
const Profile := preload("res://editor/map_authoring/infrastructure/terrain/water_surface_profile.gd")
const Migration := preload("res://editor/map_authoring/application/landscape_profile_migration.gd")
const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
const City := preload("res://editor/map_authoring/infrastructure/terrain/city_hex_layout.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var p := Parameters.defaults()
	assert(p["forest_distribution"] == 1.0)
	var old := {"tree_density": 0.8, "city_tree_height": 12.0, "city_tree_spacing": 10.0, "city_hex_diameter": 160.0, "camera_zoom": 4.0}
	var migrated := Migration.migrate(old)
	assert(migrated["city_tree_height"] == 8.0 and migrated["city_hex_diameter"] == 240.0)
	assert(migrated["camera_zoom"] == 4.0 and old["city_tree_height"] == 12.0)
	old["city_tree_height"] = 17.0
	assert(Migration.migrate(old)["city_tree_height"] == 17.0, "Preserve customized settings")
	assert(Migration.migrate(migrated) == migrated)
	var context := Image.create(64, 64, false, Image.FORMAT_L8)
	context.fill(Color.WHITE)
	var mask := Patches.build(context, Vector2(128, 128), 10.0, 1234, p)
	assert(mask.get_data() == Patches.build(context, Vector2(128, 128), 10.0, 1234, p).get_data())
	assert(mask.get_data() != Patches.build(context, Vector2(128, 128), 10.0, 4321, p).get_data())
	assert(mask.get_data().count(0) > 100 and mask.get_data().count(255) > 100, "Dense cores and clearings, not uniform random thinning")
	for key in ["forest_patch_size", "forest_patch_coverage", "forest_edge_softness"]:
		var alternative := p.duplicate(true)
		alternative[key] = Parameters.descriptor(key)[2]
		assert(mask.get_data() != Patches.build(context, Vector2(128, 128), 10.0, 1234, alternative).get_data(), key)
	context.fill(Color.BLACK)
	context.fill_rect(Rect2i(15, 15, 5, 5), Color.WHITE)
	var blocks := Patches.active_blocks(context, Vector2(128, 128), 10.0)
	assert(Patches.grid_cells(blocks, 0.5) < 128 * 128, "Do not spend grid budget on empty map")
	var visited := {}
	for block in blocks:
		for y in range(ceili(block.position.y / 1.3), ceili(block.end.y / 1.3)):
			for x in range(ceili(block.position.x / 1.3), ceili(block.end.x / 1.3)):
				assert(not visited.has(Vector2i(x,y)), "No duplicated grid cells across blocks")
				visited[Vector2i(x,y)] = true
	var source := AonwTerrainCompiledArtifact.new()
	source.map_id = "woods"
	source.cols = 4
	source.rows = 4
	source.width = 81
	source.height = 81
	source.hex_radius_meters = 10.0
	source.sample_spacing_meters = 1.0
	source.world_min_meters = Vector2(-10, -8.660254)
	var doc := {"mapName": "woods", "cols": 4, "rows": 4, "tiles": []}
	for y in 4:
		for x in 4:
			doc["tiles"].append({"col": x, "row": y, "height": 1, "terrainTags": ["forest"]})
	var water := Image.create(81, 81, false, Image.FORMAT_L8)
	water.fill(Color.BLACK)
	water.fill_rect(Rect2i(0,0,12,81), Color.WHITE)
	var reference := Image.create(100, 100, false, Image.FORMAT_RGBA8)
	reference.fill(Color(0.08,0.22,0.05))
	var plan := Plan.new()
	assert(plan.configure(source, reference, doc, water, true)["ok"])
	plan.surface_masks(p)
	var resolved := City.forest_parameters(source, p)
	var first := plan.forest_candidates(resolved)
	assert(not first.is_empty())
	reference.fill(Color(0.8,0.7,0.5))
	var other := Plan.new()
	assert(other.configure(source, reference, doc, water, true)["ok"])
	other.surface_masks(p)
	assert(first == other.forest_candidates(resolved), "Natural positions AND tints ignore painted woodland")
	for tree in first:
		assert(tree["position"].x >= 12.0, "Exclude river and shoreline trees")
	assert(plan.forest_statistics["candidate_cells"] <= Plan.MAX_CANDIDATES)
	p["forest_tree_budget"] = 1000.0
	assert(plan.forest_candidates(City.forest_parameters(source,p)).size() <= 1000)
	# Signed shore distances preserve narrow channels and dry islands, in metres.
	var channel := Image.create(9,9,false,Image.FORMAT_L8)
	channel.fill(Color.BLACK)
	channel.fill_rect(Rect2i(4,0,1,9),Color.WHITE)
	var before := channel.get_data()
	var profile := Profile.build(channel, 2.0)
	assert(profile.get_pixel(4,4).r == 1.0 and profile.get_pixel(3,4).r == -1.0)
	assert(profile.get_pixel(4,4).a == 1.0)
	assert(channel.get_data() == before)
	channel.fill(Color.WHITE)
	channel.set_pixel(4,4,Color.BLACK)
	profile = Profile.build(channel, 0.5)
	assert(profile.get_pixel(4,4).r < 0.0 and profile.get_pixel(4,3).r > 0.0)
	for y in 9:
		for x in 9:
			var pixel := profile.get_pixel(x,y)
			assert(is_finite(pixel.r) and is_finite(pixel.g) and is_finite(pixel.b) and is_finite(pixel.a))
	print("Forest/water generation: PASS (migration, procedural clusters, active budgets, image independence, metric shore profiles)")
	quit(0)
