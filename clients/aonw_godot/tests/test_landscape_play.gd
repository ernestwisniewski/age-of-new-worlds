extends SceneTree
## Exercise the exact F5 entry scene with native Terrain3D and installed visual assets.
const Launcher := preload("res://scenes/terrain_authoring/landscape_play.tscn")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/terrain_authoring/landscape_play.tscn")
	var launcher := Launcher.instantiate()
	launcher.initial_map_id = "aonw2_starter"
	root.add_child(launcher)
	for _frame in 120:
		await process_frame
		var current: Node = launcher.get("_preview")
		if current != null and bool(current.get("preview_ready")):
			break
	await create_timer(0.6).timeout
	var preview: Node = launcher.get("_preview")
	assert(preview != null and preview.get("preview_ready"))
	assert(preview.get("source_map_id") == "aonw2_starter")
	assert(preview.get("landscape_ready"), str(preview.get("landscape_status")))
	assert(not preview.get_node("Terrain3D").visible, "Do not draw coincident native and PBR surfaces")
	assert(preview.get_node("ReferenceWater").visible)
	preview.call("show_top_view")
	assert(not preview.get_node("ReferenceWater").visible)
	assert(not preview.get_node("ReferenceForest").visible)
	preview.call("show_oblique_view")
	assert(preview.get_node("ReferenceWater").visible)
	# The brush fast path bypasses refresh_overlays: its override must re-seat trees.
	preview.set("_pending_changed_pixels", Rect2i(1, 1, 2, 2))
	preview.call("_refresh_overlays_deferred")
	var timer: Timer = preview.get("_forest_timer")
	assert(not timer.is_stopped(), "Native brush edits schedule forest re-seating")
	await create_timer(0.4).timeout
	assert(preview.get("landscape_ready"))
	var before: Object = preview.call("artifact")
	var invalid_guide := ImageTexture.create_from_image(Image.create(3, 3, false, Image.FORMAT_L8))
	preview.set("forest_guide", invalid_guide)
	var rejected: Dictionary = preview.call("rebuild_reference")
	assert(not rejected["ok"] and preview.call("artifact") == before, "Reject misaligned guides without replacing terrain")
	root.remove_child(launcher)
	launcher.free()
	await process_frame
	print("PASS F5 launcher: selected map, native/PBR visibility, reference comparison, brush re-seating")
	quit(0)
