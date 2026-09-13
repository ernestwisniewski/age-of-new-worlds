extends SceneTree
## Schema/UI signal and perspective-camera contracts; no Terrain3D extension needed.

const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
const ParameterPanel := preload("res://editor/map_authoring/presentation/terrain_parameter_panel.gd")
const Camera := preload("res://editor/map_authoring/presentation/reference_preview_camera.gd")
var _failures := PackedStringArray()
var _events: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var values := Parameters.defaults(25.0)
	_check(Parameters.validate(values).is_empty(), "Defaults are valid")
	_check(not Parameters.validate({"seed": 1.25}).is_empty(), "Fractional seeds are rejected")
	_check(not Parameters.validate({"sun_energy": NAN}).is_empty(), "NaN is rejected")
	_check(not Parameters.validate({"unknown": 1.0}).is_empty(), "Unknown options are rejected")
	var panel := ParameterPanel.new()
	root.add_child(panel)
	panel.parameter_changed.connect(func(key: String, value: float) -> void: _events.append([key, value]))
	panel.show_values(values, true, false)
	_check(_events.is_empty(), "Initial UI synchronization emits no changes")
	_check(panel.ranges.size() == Parameters.FIELDS.size() - 1, "Every schema field has one control except the existing height slider")
	for field in Parameters.FIELDS:
		var key: String = field[0]
		if key == "level_height":
			continue
		var control: Range = panel.ranges[key]
		_check(control.min_value == field[2] and control.max_value == field[3], "Control range: " + key)
		_check(control.step == field[4], "Control step: " + key)
		var previous_count := _events.size()
		control.value = field[3] if control.value != field[3] else field[2]
		_check(_events.size() == previous_count + 1, "One signal per edit: " + key)
		_check(_events.back()[0] == key and _events.back()[1] == control.value, "Correct signal destination: " + key)
	var count := _events.size()
	panel.show_values(values, false, false)
	_check(_events.size() == count, "Read-only synchronization emits no edits")
	for control in panel.ranges.values():
		_check(not control.get("editable"), "Disabled panels cannot edit")
	panel.queue_free()
	var generation := Parameters.geometry(values)
	values["sun_energy"] = 2.0
	values["camera_pitch"] = 60.0
	_check(generation == Parameters.geometry(values), "Presentation changes do not alter the terrain recipe")
	for preset in ["Reference faithful", "Strategic natural", "Rugged"]:
		_check(Parameters.validate(Parameters.preset(preset, values)).is_empty(), "Valid preset: " + preset)
	var parent := Node3D.new()
	root.add_child(parent)
	var camera := Camera.new()
	parent.add_child(camera)
	camera.configure_view(52.0, 0.0, 1.0, 38.0)
	camera.frame_terrain(Vector2(600, 500), 80.0, false)
	_check(camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Strategic camera is perspective")
	var initial := camera.position.distance_to(Vector3(300, 20, 250))
	camera.configure_view(52.0, 0.0, 2.0, 38.0)
	_check(camera.position.distance_to(Vector3(300, 20, 250)) < initial, "Zoom moves the camera")
	var before := camera.position
	camera.configure_view(35.0, 40.0, 2.0, 50.0)
	_check(camera.position != before and camera.fov == 50.0, "Pitch, heading and FOV affect projection")
	camera.frame_terrain(Vector2(600, 500), 80.0, true)
	_check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Reference top view is orthographic")
	_check(camera.transform.is_finite(), "Top-view transform is finite")
	parent.queue_free()
	for failure in _failures:
		push_error(failure)
	print("Reference parameters: PASS" if _failures.is_empty() else "Reference parameters: FAIL")
	quit(0 if _failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
