@tool
extends EditorPlugin

const CompositionRoot := preload(
	"res://editor/map_authoring/composition/map_authoring_composition_root.gd"
)

var _dock: Control
var _composition: AonwMapAuthoringCompositionRoot

func _enter_tree() -> void:
	_composition = CompositionRoot.new()
	_dock = _composition.create_dock()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	set_input_event_forwarding_always_enabled()
	scene_changed.connect(_on_scene_changed)
	_compose_scene.call_deferred(EditorInterface.get_edited_scene_root())

func _exit_tree() -> void:
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if _dock == null:
		return
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
	var result: Dictionary = await _composition.open_scene(scene_root)
	if not result["ok"]:
		push_error("AoNW Terrain Workbench: %s" % result["message"])
	elif result.has("reference_warning"):
		push_warning(
			"AoNW Terrain Workbench: 2D reference disabled: %s"
			% result["reference_warning"]
		)
	if result.has("generated_warning"):
		push_warning(
			"AoNW Terrain Workbench: generated world disabled: %s"
			% result["generated_warning"]
		)
	if _dock != null:
		_dock.sync_from_edited_scene()
