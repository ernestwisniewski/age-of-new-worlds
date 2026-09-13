extends SceneTree
## Run in the fully imported project with its native Engine and Terrain3D builds.
## Writes checkpoints ONLY under a unique user:// test directory, never map assets.

const Template := preload("res://scenes/terrain_authoring/reference_terrain.tscn")
var _failures := PackedStringArray()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var surface = Template.instantiate()
	surface.workspace_root = "user://reference-tests/%d" % Time.get_ticks_usec()
	surface.frame_on_open = false
	root.add_child(surface)
	var opened: Dictionary = await surface.ensure_reference_session()
	if not opened["ok"]:
		push_error(opened["message"])
		surface.queue_free()
		quit(1)
		return
	var reference := surface.get_node("ReferenceTexture") as MeshInstance3D
	var material := reference.material_override as ShaderMaterial
	_check(material != null, "Reference uses the new material")
	surface.set_reference_opacity(0.17)
	_check(is_equal_approx(material.get_shader_parameter("reference_opacity"), 0.17), "Reference opacity reaches active shader")
	surface.set_reference_visible(false)
	_check(not material.get_shader_parameter("reference_visible"), "Reference toggle reaches active shader")
	_check(reference.visible, "Reference off preserves the semantic ground material")
	surface.set_reference_visible(true)
	_check(material.get_shader_parameter("reference_visible"), "Reference can be re-enabled")
	surface.set_grid_visible(true)
	surface.set_grid_opacity(0.23)
	var grid := surface.get_node("HexGrid") as MeshInstance3D
	_check(grid.visible, "Grid toggle reaches mesh")
	var grid_material := grid.mesh.surface_get_material(0) as StandardMaterial3D
	_check(is_equal_approx(grid_material.albedo_color.a, 0.23), "Grid opacity reaches material")
	surface.set_constraints_visible(true)
	_check(surface.get_node("MinimumHeightDebug").visible and surface.get_node("MaximumHeightDebug").visible, "Both envelopes respond")
	surface.set_constraints_visible(false)
	surface.set_city_marker_visible(true)
	surface.set_city_marker_coordinate(Vector2i(10, 10))
	_check(surface.city_marker_coordinate == Vector2i(10, 10), "City marker coordinates update")
	for key in ["relief_lighting", "rock_slope"]:
		surface.set_parameter_change({"key": key, "value": 0.31})
		_check(is_equal_approx(material.get_shader_parameter(key), 0.31), "Live shader parameter: " + key)
	surface.set_parameter_change({"key": "sun_energy", "value": 1.4})
	_check(is_equal_approx(surface.get_node("Sun").light_energy, 1.4), "Sun intensity is live")
	surface.set_parameter_change({"key": "ambient_energy", "value": 0.3})
	_check(is_equal_approx(surface.get_node("WorldEnvironment").environment.ambient_light_energy, 0.3), "Ambient intensity is live")
	surface.show_oblique_view()
	var camera := surface.get_node("PreviewCamera") as Camera3D
	_check(camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Strategic projection is perspective")
	var before: String = surface.artifact().generated_base_hash
	var old_session: RefCounted = surface.get("_session")
	surface.set_parameter_change({"key": "mountain_scale", "value": 2.7})
	_check(surface.has_pending_geometry() and surface.artifact().generated_base_hash == before, "Dragging a geometry slider only stages the recipe")
	var rebuilt: Dictionary = surface.rebuild_reference()
	_check(rebuilt["ok"], "Explicit rebuild succeeds")
	if rebuilt["ok"]:
		_check(surface.artifact().generated_base_hash != before, "Apply rebuilds native geometry")
		_check(not surface.has_pending_geometry(), "Apply clears pending state")
		for connection in surface.terrain().data.maps_edited.get_connections():
			_check(connection["callable"].get_object() != old_session, "Old session no longer constrains the new terrain")
		var mask: Image = surface.reconstruction["water_mask"]
		for y in range(0, mask.get_height(), 9):
			for x in range(0, mask.get_width(), 9):
				if mask.get_pixel(x, y).r > 0.5:
					_check(absf(surface.height_at(Vector2i(x, y))) < 0.0005, "Native water remains zero")
	var saved: Dictionary = surface.save_draft()
	_check(saved["ok"], "Native checkpoint and companions save")
	for failure in _failures:
		push_error(failure)
	print("Reference native controls: PASS" if _failures.is_empty() else "Reference native controls: FAIL")
	surface.queue_free()
	quit(0 if _failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition and not _failures.has(message):
		_failures.append(message)
