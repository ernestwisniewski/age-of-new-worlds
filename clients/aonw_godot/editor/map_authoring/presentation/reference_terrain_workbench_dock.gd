@tool
extends "res://editor/map_authoring/presentation/map_workbench_dock.gd"
## Adapts the existing workbench, undo system and overlays to reference recipes.

const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
const ParameterPanel := preload("res://editor/map_authoring/presentation/terrain_parameter_panel.gd")
const StrategicPreview := preload("res://editor/map_authoring/presentation/terrain_strategic_preview.gd")

var _parameter_panel := ParameterPanel.new()
var _strategic_preview := StrategicPreview.new()
var _watched_surface: Node
var _sync_queued := false
var _view_buttons: Array[Button] = []

func _build_interface() -> void:
	super._build_interface()
	var description := get_child(1) as Label
	description.text = "JSON heights + terrain attributes + reference landscape → editable Terrain3D"
	_generate_button.text = "Generate / open landscape"
	var content := _sections.get_child(2).get_child(0)
	content.add_child(_parameter_panel)
	content.move_child(_parameter_panel, 3)
	var preview_label := Label.new()
	preview_label.text = "Live strategic preview · drag to orbit / pan"
	content.add_child(preview_label)
	content.add_child(_strategic_preview)
	var actions := HBoxContainer.new()
	for definition in [["Strategic", "show_oblique_view"], ["Reference top", "show_top_view"]]:
		var button := Button.new()
		button.text = definition[0]
		button.pressed.connect(_view_requested.bind(definition[1]))
		actions.add_child(button)
		_view_buttons.append(button)
	content.add_child(actions)
	_sections.current_tab = 2

func _connect_interface() -> void:
	super._connect_interface()
	_parameter_panel.parameter_changed.connect(_parameter_changed)
	_parameter_panel.apply_requested.connect(_reload_generated_base)
	_parameter_panel.discard_requested.connect(_discard_pending)
	_parameter_panel.preset_requested.connect(_choose_preset)

func _exit_tree() -> void:
	_watch(null)

func _is_reference(surface: Node) -> bool:
	return surface != null and surface.has_method("rebuild_reference")

func _current_surface() -> AonwTerrainAuthoringSurface:
	var surface := super._current_surface()
	var selected_id := _selected_map_id()
	if surface != null and not selected_id.is_empty() and surface.source_map_id != selected_id:
		return null # Never send a selected map's sliders to a different open map.
	return surface

func sync_from_edited_scene() -> void:
	var surface := super._current_surface()
	if surface != null:
		_select_source(surface.source_map_id, false)
	_watch(surface if _is_reference(surface) else null)
	super.sync_from_edited_scene()
	_sync_reference_controls()

func _watch(surface: Node) -> void:
	if is_instance_valid(_watched_surface) and _watched_surface.is_connected("preview_state_changed", _queue_sync):
		_watched_surface.disconnect("preview_state_changed", _queue_sync)
	_watched_surface = surface
	if is_instance_valid(surface):
		surface.connect("preview_state_changed", _queue_sync)

func _queue_sync() -> void:
	if _sync_queued:
		return
	_sync_queued = true
	_sync_controls_deferred.call_deferred()

func _sync_controls_deferred() -> void:
	_sync_queued = false
	if not is_inside_tree():
		return
	super.sync_from_edited_scene()
	_sync_reference_controls()

func _sync_reference_controls() -> void:
	var surface := _current_surface()
	var reference := _is_reference(surface)
	var ready := reference and surface.is_session_open() and not _busy and not bool(surface.get("_opening"))
	_parameter_panel.visible = reference
	_parameter_panel.show_values(surface.call("parameter_values") if reference else Parameters.defaults(), ready,
		bool(surface.call("has_pending_geometry")) if reference else false)
	_strategic_preview.bind_surface(surface if reference and surface.is_session_open() else null)
	for button in _view_buttons:
		button.disabled = not ready
	_publish_button.visible = not reference
	_reload_base_button.text = "Rebuild reference landscape" if reference else "Reload compiled base / constraints"
	_reload_base_button.tooltip_text = "Saves the old draft, then opens a versioned recipe; resets this scene's undo history." if reference else "Keeps the manually sculpted final terrain"
	_save_draft_button.text = "Save terrain + recipe + mask" if reference else "Save draft"
	if reference:
		_max_terrain_height.max_value = 1000.0
		_max_terrain_height.exp_edit = false
		_max_terrain_height.tooltip_text = "Presentation height of JSON level 5; Apply rebuilds without changing canonical JSON."
		for control in [_reference_toggle, _grid_toggle, _constraints_toggle, _city_marker_toggle, _reload_base_button, _save_draft_button]:
			control.disabled = not ready
		_reference_toggle.disabled = not ready or not surface.has_reference_texture()
		_reference_opacity.editable = ready and surface.has_reference_texture()
		_grid_opacity.editable = ready
		_city_col.editable = ready
		_city_row.editable = ready
		_logical_map_panel.set_editable(false)
		_logical_map_panel.tooltip_text = "Edit canonical JSON in the legacy workbench, recompile inputs, then rebuild this landscape."
		if not str(surface.get("preview_error")).is_empty():
			_status.text = "Error: " + str(surface.get("preview_error"))

func _selected_map_changed(index: int) -> void:
	super._selected_map_changed(index)
	super.sync_from_edited_scene()
	_sync_reference_controls()
	if not _busy:
		_generate_selected_map() # Use exactly the same workflow as the explicit button.

func _sync_selected_height_scale() -> void:
	var surface := _current_surface()
	if not _is_reference(surface):
		_max_terrain_height.max_value = 10000.0
		_max_terrain_height.exp_edit = true
		super._sync_selected_height_scale()
		return
	_height_scale_timer.stop()
	var values: Dictionary = surface.call("parameter_values")
	_max_terrain_height.set_value_no_signal(values["level_height"])
	_max_terrain_height.editable = surface.is_session_open() and not _busy
	_update_max_height_label()

func _max_height_value_changed(value: float) -> void:
	if _is_reference(_current_surface()):
		_update_max_height_label()
		_parameter_changed("level_height", value)
	else:
		super._max_height_value_changed(value)

func _apply_selected_height_scale() -> void:
	if _is_reference(_current_surface()):
		_parameter_changed("level_height", _max_terrain_height.value)
	else:
		super._apply_selected_height_scale()

func _parameter_changed(key: String, value: float) -> void:
	var surface := _current_surface()
	if not _is_reference(surface) or _busy:
		return
	var previous: Dictionary = surface.call("parameter_values")
	_commit_change("Change terrain " + key, &"set_parameter_change",
		{"key": key, "value": value}, {"key": key, "value": previous[key]}, UndoRedo.MERGE_ENDS)

func _choose_preset(name: String) -> void:
	var surface := _current_surface()
	if not _is_reference(surface) or _busy:
		return
	var previous: Dictionary = surface.call("parameter_values")
	var next := Parameters.preset(name, previous)
	var history := EditorInterface.get_editor_undo_redo()
	history.create_action("Apply terrain preset " + name, UndoRedo.MERGE_DISABLE, surface)
	for key in next:
		if next[key] != previous[key]:
			history.add_do_method(surface, "set_parameter_change", {"key": key, "value": next[key]})
			history.add_undo_method(surface, "set_parameter_change", {"key": key, "value": previous[key]})
	history.commit_action()

func _discard_pending() -> void:
	var surface := _current_surface()
	if _is_reference(surface) and not _busy:
		surface.call("discard_pending_parameters")

func _reload_generated_base() -> void:
	var surface := _current_surface()
	if not _is_reference(surface):
		super._reload_generated_base()
		return
	if _busy:
		return
	_set_busy(true)
	_status.text = "Reconstructing landscape; the current draft will be checkpointed…"
	await get_tree().process_frame
	if not is_instance_valid(surface) or surface != _current_surface():
		_set_busy(false)
		return
	var result: Dictionary = surface.call("rebuild_reference")
	_set_busy(false)
	if not result["ok"]:
		_show_error(result["message"])
		return
	if not result.get("unchanged", false):
		# Old brush undo actions point at the previous native session. They must not
		# be replayed against a different recipe. Other scenes keep their histories.
		var history := EditorInterface.get_editor_undo_redo()
		history.clear_history(history.get_object_history_id(surface))
		EditorInterface.mark_scene_as_unsaved()
	_status.text = "Reference landscape rebuilt. Previous sculpt is saved in its original recipe directory."
	sync_from_edited_scene()

func _logical_mode_available(surface: AonwTerrainAuthoringSurface) -> bool:
	return false if _is_reference(surface) else super._logical_mode_available(surface)

func _has_editable_surface(source: AonwMapSource) -> bool:
	# This predicate is used by the legacy canonical editor, not recipe controls.
	return false if _is_reference(_current_surface()) else super._has_editable_surface(source)

func _set_busy(value: bool) -> void:
	super._set_busy(value)
	_refresh_button.disabled = value
	_sync_reference_controls()
	if _is_reference(_current_surface()):
		_max_terrain_height.editable = not value and _current_surface().is_session_open()

func _view_requested(method: String) -> void:
	var surface := _current_surface()
	if _is_reference(surface):
		surface.call(method)
		EditorInterface.mark_scene_as_unsaved()
