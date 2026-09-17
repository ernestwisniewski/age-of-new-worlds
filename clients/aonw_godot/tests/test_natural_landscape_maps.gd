extends SceneTree
## Test the fully generated shared scene for EVERY current map, including starter.
const Preview := preload("res://scenes/terrain_authoring/reference_terrain.tscn")
const City := preload("res://editor/map_authoring/infrastructure/terrain/city_hex_layout.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var maps := DirAccess.get_directories_at("res://assets/maps")
	maps.sort()
	var tested := 0
	for map_id in maps:
		if not FileAccess.file_exists("res://assets/maps/" + map_id + "/map.json"):
			continue
		var view := Preview.instantiate()
		view.source_map_id = map_id
		view.workspace_root = "user://natural-forest-validation"
		root.add_child(view)
		var opened: Dictionary = await view.ensure_reference_session()
		assert(opened["ok"], str(opened.get("message", "")))
		for i in 200:
			await create_timer(0.025).timeout
			if view.landscape_ready:
				break
		assert(view.landscape_ready, view.landscape_status)
		var values: Dictionary = view.parameter_values()
		assert(values["forest_distribution"] == 1.0)
		var source: AonwTerrainCompiledArtifact = view.artifact()
		assert(source.generator_version == "aonw-reference-terrain/4")
		assert(is_equal_approx(City.forest_parameters(source,values)["tree_height"] / (source.hex_radius_meters * 2.0), 8.0 / 240.0))
		assert(view.tree_count <= int(values["forest_tree_budget"]))
		var plan: Object = view.get("_surface_plan")
		var stats: Dictionary = plan.get("forest_statistics")
		assert(int(stats["candidate_cells"]) <= 240000)
		var masks: Dictionary = view.get("_masks")
		var wet: Image = masks["water"]
		var profile: Image = masks["water_profile"]
		assert(wet.get_size() == profile.get_size())
		for y in range(0, source.height, 7):
			for x in range(0, source.width, 7):
				var is_water := wet.get_pixel(x,y).r >= 0.5
				assert((profile.get_pixel(x,y).r >= 0.0) == is_water)
				if is_water:
					assert(absf(view.height_at(Vector2i(x,y))) < 0.0005)
		print("NATURAL MAP PASS ", map_id, " trees=", view.tree_count, " ", stats)
		root.remove_child(view)
		view.free()
		await process_frame
		tested += 1
	assert(tested >= 5, "All five existing bundles must be exercised")
	print("Natural landscape maps: PASS (", tested, " bundles)")
	quit(0)
