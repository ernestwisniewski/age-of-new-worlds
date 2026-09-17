@tool
extends Node
## Run this scene with and without --editor, using -- --performance-contract.
## Keep the normal editor main loop: --editor --script with a custom SceneTree
## leaks editor-owned resources at shutdown even for an otherwise empty test.
const Scene := preload("res://scenes/terrain_authoring/reference_maps/dravonia.tscn")

func _ready() -> void:
	if "--performance-contract" in OS.get_cmdline_user_args():
		_run.call_deferred()

func _run() -> void:
	var root := get_tree().root
	var view = Scene.instantiate()
	view.workspace_root = "user://editor-performance-validation"
	root.add_child(view)
	var opened: Dictionary = await view.ensure_reference_session()
	assert(opened["ok"], str(opened.get("message", "")))
	assert(await _settle(view), view.landscape_status)
	var forest: Node3D = view.get_node("ReferenceForest")
	var identity := forest.get_instance_id()
	var generation: int = view.forest_generation_count
	var samples: int = view._forest_renderer.height_sample_calls
	var total: int = view.tree_count
	assert(total > 0)
	if Engine.is_editor_hint():
		assert(view.editor_visible_tree_count == mini(total, view.editor_tree_budget))
		for batch in forest.get_children():
			assert(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	else:
		assert(view.editor_visible_tree_count == total, "Play must not inherit the editor draw budget")
	view.set_editor_fast_preview(false)
	assert(view.editor_visible_tree_count == total)
	for batch in forest.get_children():
		assert(batch.multimesh.visible_instance_count == -1)
		assert(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	view.set_editor_fast_preview(true)
	assert(forest.get_instance_id() == identity, "Quality changes must reuse buffers, not rebuild the forest")
	view.set_parameter_change({"key": "tree_draw_distance", "value": 1500.0})
	view.set_parameter_change({"key": "sun_energy", "value": 0.9})
	view.set_parameter_change({"key": "camera_zoom", "value": 1.5})
	assert(view.landscape_ready)
	assert(view._forest_timer.is_stopped())
	assert(view.forest_generation_count == generation)
	assert(view._forest_renderer.height_sample_calls == samples)
	for batch in forest.get_children():
		assert(batch.visibility_range_end == 1500.0)
	view.set_city_marker_coordinate(Vector2i(-1, -1))
	assert(await _settle(view))
	assert(view.forest_generation_count == generation, "A city marker must not regenerate candidates")
	assert(view._forest_renderer.height_sample_calls == samples, "Marker changes reuse height samples")
	print("EDITOR NATIVE PERFORMANCE PASS editor=", Engine.is_editor_hint(),
		" generated=", total, " drawn=", view.editor_visible_tree_count,
		" generation_passes=", generation, " native_height_samples=", samples)
	root.remove_child(view)
	view.free()
	await get_tree().process_frame
	get_tree().quit(0)

func _settle(view: Node) -> bool:
	for i in 400:
		await get_tree().create_timer(0.025).timeout
		if bool(view.get("landscape_ready")):
			return true
	return false
