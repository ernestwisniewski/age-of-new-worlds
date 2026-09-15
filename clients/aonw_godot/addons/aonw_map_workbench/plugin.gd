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
	_remember_preview(scene_root)

func _remember_preview(scene: Node) -> void:
	if scene == null or not scene.has_method("rebuild_reference"):
		return
	var configuration := ConfigFile.new()
	configuration.set_value("preview", "map_id", scene.get("source_map_id"))
	configuration.set_value("preview", "scene_path", scene.scene_file_path)
	var error := configuration.save("res://.godot/aonw_landscape_preview.cfg")
	if error != OK:
		push_warning("Cannot remember the preview map: " + error_string(error))

func _build() -> bool:
	var scene := EditorInterface.get_edited_scene_root()
	if scene == null or not scene.has_method("rebuild_reference"):
		return true
	if bool(scene.get("_opening")) or not bool(scene.get("preview_ready")):
		push_error("Wait for the landscape to finish generating before Play.")
		return false
	if scene.call("has_pending_geometry"):
		push_error("Apply or discard pending terrain changes before Play; the preview uses the applied recipe.")
		return false
	var saved: Dictionary = scene.call("save_draft")
	if not saved["ok"]:
		push_error("Cannot checkpoint the terrain for Play: " + str(saved["message"]))
		return false
	# Persist appearance/guide/camera resources as well as the native draft.
	if not scene.scene_file_path.is_empty() and EditorInterface.save_scene() != OK:
		push_error("Save the authoring scene before Play.")
		return false
	_remember_preview(scene)
	return true
