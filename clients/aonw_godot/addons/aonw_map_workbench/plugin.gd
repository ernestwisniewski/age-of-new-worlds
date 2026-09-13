@tool
extends EditorPlugin

const CompositionRoot := preload("res://editor/map_authoring/composition/reference_map_authoring_composition_root.gd")

var _dock: Control
var _composition: AonwMapAuthoringCompositionRoot
var _scene_request := 0

func _enter_tree() -> void:
	_composition = CompositionRoot.new()
	_dock = _composition.create_dock()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	set_input_event_forwarding_always_enabled()
	scene_changed.connect(_on_scene_changed)
	_compose_scene.call_deferred(EditorInterface.get_edited_scene_root())

func _exit_tree() -> void:
	_scene_request += 1
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.free()
		_dock = null
	_composition = null

func _on_scene_changed(scene_root: Node) -> void:
	_compose_scene(scene_root)

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if _dock == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	return _dock.handle_3d_gui_input(camera, event)

func _compose_scene(scene_root: Node) -> void:
	if _composition == null:
		return
	_scene_request += 1
	var request := _scene_request
	var result: Dictionary = await _composition.open_scene(scene_root)
	if not is_instance_valid(self):
		return
	if request != _scene_request or not is_instance_valid(_dock):
		return
	if EditorInterface.get_edited_scene_root() != scene_root:
		return
	if not result["ok"]:
		push_error("AoNW Terrain Workbench: %s" % result["message"])
	for warning_key in ["reference_warning", "generated_warning", "warning"]:
		if result.has(warning_key) and not str(result[warning_key]).is_empty():
			push_warning("AoNW Terrain Workbench: %s" % result[warning_key])
	# Only sync after the self-opening reference surface has an actual session.
	_dock.sync_from_edited_scene()
