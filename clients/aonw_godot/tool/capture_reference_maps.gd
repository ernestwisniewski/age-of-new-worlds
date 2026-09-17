extends SceneTree
## Render the real authoring scenes, not a separate flat material demonstration.
const Scene := preload("res://scenes/terrain_authoring/reference_terrain.tscn")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var output := "res://reference-captures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var ids := OS.get_cmdline_user_args()
	if ids.is_empty():
		for map_id in DirAccess.get_directories_at("res://assets/maps"):
			if FileAccess.file_exists("res://assets/maps/" + map_id + "/map.json"):
				ids.append(map_id)
		ids.sort()
	for id in ids:
		var preview := Scene.instantiate()
		preview.source_map_id = id
		preview.workspace_root = "user://reference-render-validation"
		root.add_child(preview)
		var opened: Dictionary = await preview.ensure_reference_session()
		if not opened["ok"]:
			push_error("Cannot render %s: %s" % [id, opened.get("message", "")])
			quit(1)
			return
		preview.get_node("PreviewHUD").hide()
		preview.show_oblique_view()
		await create_timer(0.5).timeout
		if not preview.landscape_ready or preview.get("_water_surface") == null:
			push_error("Landscape assets did not become ready for " + id + ": " + preview.landscape_status)
			quit(1)
			return
		for _frame in 1:
			await process_frame
			await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.save_png(output.path_join(id + "-landscape.png")) != OK:
			quit(1)
			return
		preview.show_top_view()
		for _frame in 1:
			await process_frame
			await RenderingServer.frame_post_draw
		image = root.get_texture().get_image()
		image.save_png(output.path_join(id + "-reference.png"))
		preview.set_reference_visible(false)
		preview.set_parameter_change({"key": "relief_lighting", "value": 1.0})
		for _frame in 1:
			await process_frame
			await RenderingServer.frame_post_draw
		image = root.get_texture().get_image()
		image.save_png(output.path_join(id + "-landscape-top.png"))
		var masks: Dictionary = preview.get("_masks")
		masks["canopy"].save_png(output.path_join(id + "-canopy.png"))
		preview.reconstruction["water_mask"].save_png(output.path_join(id + "-water.png"))
		print("RENDERED ", id, " trees=", preview.tree_count, " sampling=", preview.get("_surface_plan").forest_statistics)
		root.remove_child(preview)
		preview.free()
		await process_frame
	quit(0)
