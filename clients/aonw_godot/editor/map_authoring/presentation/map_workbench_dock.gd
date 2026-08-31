@tool
extends "res://editor/map_authoring/presentation/map_workbench_view.gd"

const SceneSaveGuard := preload(
	"res://editor/map_authoring/presentation/scene_save_guard.gd"
)

const LOGICAL_MAP_TAB := 1

var _catalog: AonwMapSourceCatalog
var _scene_writer: AonwTerrainAuthoringSceneWriter
var _generator: AonwGenerateTerrainAuthoringMap
var _create_logical_map: AonwCreateLogicalMap
var _logical_map_editor: AonwLogicalMapEditor
var _terrain_profile_editor: AonwTerrainProfileEditor
var _sources: Array[AonwMapSource] = []
var _height_slider_dragging := false
var _busy := false
var _logical_drag_active := false
var _scene_save_guard := SceneSaveGuard.new()

func configure(
	catalog: AonwMapSourceCatalog,
	generator: AonwGenerateTerrainAuthoringMap,
	scene_writer: AonwTerrainAuthoringSceneWriter,
	create_logical_map: AonwCreateLogicalMap,
	logical_map_editor: AonwLogicalMapEditor,
	terrain_profile_editor: AonwTerrainProfileEditor,
) -> void:
	_catalog = catalog
	_generator = generator
	_scene_writer = scene_writer
	_create_logical_map = create_logical_map
	_logical_map_editor = logical_map_editor
	_terrain_profile_editor = terrain_profile_editor
	_logical_map_panel.configure(logical_map_editor)

func _ready() -> void:
	assert(_catalog != null, "Map source catalog is required")
	assert(_generator != null, "Terrain authoring generator is required")
	assert(_scene_writer != null, "Terrain authoring scene writer is required")
	assert(_create_logical_map != null, "Logical map creator is required")
	assert(_logical_map_editor != null, "Logical map editor is required")
	assert(_terrain_profile_editor != null, "Terrain profile editor is required")
	_build_interface()
	_connect_interface()
	_refresh_sources()

func _connect_interface() -> void:
	_refresh_button.pressed.connect(_refresh_sources)
	_new_map_panel.create_requested.connect(_create_new_map)
	_generate_button.pressed.connect(_generate_selected_map)
	_open_button.pressed.connect(_open_selected_scene)
	_map_picker.item_selected.connect(_selected_map_changed)
	_sections.tab_changed.connect(_workbench_tab_changed)
	_logical_map_panel.edit_persisted.connect(_logical_edit_persisted)
	_logical_map_panel.error_raised.connect(_show_error)
	_logical_map_panel.status_changed.connect(func(message: String) -> void:
		_status.text = message
	)
	_max_terrain_height.value_changed.connect(_max_height_value_changed)
	_max_terrain_height.drag_started.connect(_max_height_drag_started)
	_max_terrain_height.drag_ended.connect(_max_height_drag_ended)
	_height_scale_timer.timeout.connect(_apply_selected_height_scale)
	_reference_toggle.toggled.connect(_set_reference_visible)
	_reference_opacity.value_changed.connect(_set_reference_opacity)
	_grid_toggle.toggled.connect(_set_grid_visible)
	_grid_opacity.value_changed.connect(_set_grid_opacity)
	_constraints_toggle.toggled.connect(_set_constraints_visible)
	_city_marker_toggle.toggled.connect(_set_city_marker_visible)
	_city_col.value_changed.connect(_set_city_marker_coordinate)
	_city_row.value_changed.connect(_set_city_marker_coordinate)
	_reload_base_button.pressed.connect(_reload_generated_base)
	_save_draft_button.pressed.connect(_save_draft)
	_publish_button.pressed.connect(_publish)

func _create_new_map(
	map_id: String,
	cols: int,
	rows: int,
	default_zoom: float,
	hex_radius_meters: float,
	max_terrain_height_meters: float,
	seed: String,
	generator_id: StringName,
) -> void:
	_set_busy(true)
	_status.text = "Creating canonical map %s through Rust…" % map_id
	await get_tree().process_frame
	var created := _create_logical_map.execute(
		map_id,
		cols,
		rows,
		default_zoom,
		hex_radius_meters,
		max_terrain_height_meters,
		seed,
		generator_id,
	)
	if not created["ok"]:
		_set_busy(false)
		_show_error(created["message"])
		return
	var source: AonwMapSource = created["source"]
	EditorInterface.get_resource_filesystem().scan()
	_refresh_sources()
	_select_source(source.map_id)
	_set_busy(true)
	var terrain_result := _generator.execute(source)
	_set_busy(false)
	if not terrain_result["ok"]:
		_show_error(
			"map %s was created, but Terrain3D preparation failed: %s"
			% [source.map_id, terrain_result["message"]]
		)
		return
	_status.text = "%s map %s created and opened for Terrain3D authoring." % [
		str(generator_id).capitalize(),
		source.map_id,
	]
	EditorInterface.open_scene_from_path(terrain_result["scene_path"])

func _refresh_sources() -> void:
	var preferred_map_id := _selected_map_id()
	var surface := _current_surface()
	if surface != null:
		preferred_map_id = surface.source_map_id
	_sources = _catalog.discover()
	_map_picker.clear()
	for source in _sources:
		_map_picker.add_item(source.display_name())
	if _sources.is_empty():
		_status.text = "No maps found."
		_set_source_actions_enabled(false)
		return
	var preferred_index := _source_index(preferred_map_id)
	_map_picker.select(preferred_index if preferred_index >= 0 else 0)
	_set_source_actions_enabled(true)
	_status.text = "Available Terrain3D maps: %d." % _sources.size()
	_sync_selected_height_scale()
	_sync_logical_panel()
	_sync_logical_mode()

func _selected_map_changed(_index: int) -> void:
	_height_scale_timer.stop()
	_sync_selected_height_scale()
	_sync_logical_panel()
	_sync_logical_mode()

func _sync_logical_panel() -> void:
	var source := _selected_source()
	if source != null:
		_logical_map_panel.show_source(source, _has_editable_surface(source))

func _logical_edit_persisted(
	source: AonwMapSource,
	coordinates: Array[Vector2i],
) -> void:
	EditorInterface.get_resource_filesystem().scan()
	var surface := _current_surface()
	if surface == null or surface.source_map_id != source.map_id:
		_show_error("logical map changed without its Terrain3D authoring scene open")
		return
	var migration := surface.migrate_logical_map_artifact()
	if not migration["ok"]:
		_show_error(migration["message"])
		return
	surface.clear_generated_decorations()
	surface.invalidate_reference_texture()
	var saved := surface.save_draft()
	if not saved["ok"]:
		_show_error(saved["message"])
		return
	var scene_save := _save_edited_scene_safely()
	if not scene_save["ok"]:
		_show_error("logical map changed, but %s" % scene_save["message"])
		return
	_status.text = (
		"%d logical tile(s) updated by Rust; Terrain3D final preserved. "
		+ "The stale 2D reference was disabled."
	) % coordinates.size()

func handle_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	var surface := _current_surface()
	if not _logical_mode_available(surface):
		_finish_logical_drag()
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseMotion:
		var coordinate := surface.pick_logical_hex(camera, event.position)
		surface.set_logical_paint_cursor(coordinate)
		_logical_map_panel.preview_coordinate(coordinate)
		if _logical_drag_active and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_logical_map_panel.append_paint_coordinate(coordinate)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var coordinate := surface.pick_logical_hex(camera, event.position)
			surface.set_logical_paint_cursor(coordinate)
			_logical_map_panel.preview_coordinate(coordinate)
			if coordinate == AonwTerrainAuthoringSurface.INVALID_HEX:
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			if _logical_map_panel.is_inspect_tool():
				_logical_map_panel.inspect_coordinate(coordinate)
			else:
				_logical_drag_active = _logical_map_panel.begin_paint_stroke()
				if _logical_drag_active:
					_logical_map_panel.append_paint_coordinate(coordinate)
		else:
			_finish_logical_drag()
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _workbench_tab_changed(_tab: int) -> void:
	_finish_logical_drag()
	_sync_logical_mode()

func _finish_logical_drag() -> void:
	if not _logical_drag_active:
		return
	_logical_drag_active = false
	_logical_map_panel.end_paint_stroke()

func _logical_mode_available(surface: AonwTerrainAuthoringSurface) -> bool:
	var source := _selected_source()
	return (
		not _busy
		and _sections.current_tab == LOGICAL_MAP_TAB
		and surface != null
		and source != null
		and surface.source_map_id == source.map_id
		and surface.is_session_open()
	)

func _sync_logical_mode() -> void:
	var surface := _current_surface()
	if surface != null:
		surface.set_logical_paint_active(_logical_mode_available(surface))

func _has_editable_surface(source: AonwMapSource) -> bool:
	var surface := _current_surface()
	return (
		surface != null
		and surface.source_map_id == source.map_id
		and surface.is_session_open()
	)

func _sync_selected_height_scale() -> void:
	_height_scale_timer.stop()
	var source := _selected_source()
	if source == null:
		_max_terrain_height.editable = false
		return
	var result := _terrain_profile_editor.current_maximum(source)
	if not result["ok"]:
		_max_terrain_height.editable = false
		_status.text = "Error: %s" % result["message"]
		return
	_max_terrain_height.set_value_no_signal(result["max_terrain_height_meters"])
	_update_max_height_label()
	_max_terrain_height.editable = not _busy and _has_editable_surface(source)

func _max_height_value_changed(_value: float) -> void:
	_update_max_height_label()
	if not _height_slider_dragging and _max_terrain_height.editable:
		_height_scale_timer.start()

func _max_height_drag_started() -> void:
	_height_slider_dragging = true
	_height_scale_timer.stop()

func _max_height_drag_ended(value_changed: bool) -> void:
	_height_slider_dragging = false
	if value_changed and _max_terrain_height.editable:
		_height_scale_timer.start(0.05)

func _apply_selected_height_scale() -> void:
	var source := _selected_source()
	if source == null or not _has_editable_surface(source):
		_status.text = "Open this map's Terrain3D authoring scene before changing its height."
		return
	var surface := _current_surface()
	var current_artifact := surface.artifact()
	if (
		current_artifact != null
		and is_equal_approx(
			current_artifact.max_terrain_height_meters,
			_max_terrain_height.value,
		)
	):
		return
	_set_busy(true)
	_status.text = "Rescaling %s Terrain3D height and constraints…" % source.map_id
	await get_tree().process_frame
	var result := _terrain_profile_editor.update_maximum(
		source,
		_max_terrain_height.value,
	)
	if not result["ok"]:
		_set_busy(false)
		_show_error(result["message"])
		_sync_selected_height_scale()
		return
	EditorInterface.get_resource_filesystem().scan()
	var refresh_result := surface.rescale_generated_artifact()
	if not refresh_result["ok"]:
		_set_busy(false)
		_show_error(refresh_result["message"])
		return
	var save_result := surface.save_draft()
	if not save_result["ok"]:
		_set_busy(false)
		_show_error(save_result["message"])
		return
	var scene_save := _save_edited_scene_safely()
	_set_busy(false)
	_status.text = "Maximum Terrain3D height set to %.1f m for %s; %d samples rescaled.%s" % [
		result["max_terrain_height_meters"],
		source.map_id,
		int(refresh_result["rescaled_pixels"]),
		"" if scene_save["ok"] else " %s" % scene_save["message"],
	]

func _generate_selected_map() -> void:
	var source := _selected_source()
	if source == null:
		return
	_set_busy(true)
	_status.text = "Preparing Terrain3D authoring for %s…" % source.map_id
	await get_tree().process_frame
	var result := _generator.execute(source)
	_set_busy(false)
	if not result["ok"]:
		_show_error(result["message"])
		return
	EditorInterface.get_resource_filesystem().scan()
	if result["scene_created"]:
		_status.text = "Terrain3D authoring scene created."
	else:
		_status.text = "Existing Terrain3D scene kept; compiled inputs refreshed."
	EditorInterface.open_scene_from_path(result["scene_path"])

func _open_selected_scene() -> void:
	var source := _selected_source()
	if source == null:
		return
	var scene_path := _scene_writer.scene_path_for(source.map_id)
	if not ResourceLoader.exists(scene_path):
		_status.text = "Create the Terrain3D authoring scene first."
		return
	EditorInterface.open_scene_from_path(scene_path)

func _set_reference_visible(value: bool) -> void:
	_commit_change(
		"Toggle terrain reference",
		&"set_reference_visible",
		value,
		_current_value(&"reference_visible"),
		UndoRedo.MERGE_DISABLE,
	)

func _set_reference_opacity(value: float) -> void:
	_update_opacity_labels()
	_commit_change(
		"Change terrain reference opacity",
		&"set_reference_opacity",
		value,
		_current_value(&"reference_opacity"),
		UndoRedo.MERGE_ENDS,
	)

func _set_grid_visible(value: bool) -> void:
	_commit_change(
		"Toggle terrain hex grid",
		&"set_grid_visible",
		value,
		_current_value(&"grid_visible"),
		UndoRedo.MERGE_DISABLE,
	)

func _set_grid_opacity(value: float) -> void:
	_update_opacity_labels()
	_commit_change(
		"Change terrain grid opacity",
		&"set_grid_opacity",
		value,
		_current_value(&"grid_opacity"),
		UndoRedo.MERGE_ENDS,
	)

func _set_constraints_visible(value: bool) -> void:
	_commit_change(
		"Toggle terrain constraint envelopes",
		&"set_constraints_visible",
		value,
		_current_value(&"constraints_visible"),
		UndoRedo.MERGE_DISABLE,
	)

func _set_city_marker_visible(value: bool) -> void:
	_commit_change(
		"Toggle city-core marker",
		&"set_city_marker_visible",
		value,
		_current_value(&"city_marker_visible"),
		UndoRedo.MERGE_DISABLE,
	)

func _set_city_marker_coordinate(_value: float) -> void:
	var surface := _current_surface()
	if surface == null:
		return
	var coordinate := Vector2i(roundi(_city_col.value), roundi(_city_row.value))
	if coordinate == surface.city_marker_coordinate:
		return
	_commit_change(
		"Move city-core marker",
		&"set_city_marker_coordinate",
		coordinate,
		surface.city_marker_coordinate,
		UndoRedo.MERGE_ENDS,
	)

func _reload_generated_base() -> void:
	var surface := _current_surface()
	if surface == null:
		return
	var result := surface.refresh_generated_artifact()
	if not result["ok"]:
		_show_error(result["message"])
		return
	_status.text = "Compiled base and constraints reloaded; manual final terrain preserved."

func _save_draft() -> void:
	var surface := _current_surface()
	if surface == null:
		return
	var result := surface.save_draft()
	if not result["ok"]:
		_show_error(result["message"])
		return
	var scene_save := _save_edited_scene_safely()
	_status.text = (
		"Terrain3D draft and scene saved."
		if scene_save["ok"]
		else "Terrain3D draft saved, but %s" % scene_save["message"]
	)

func _publish() -> void:
	var surface := _current_surface()
	if surface == null:
		return
	var scene_save := _save_edited_scene_safely()
	if not scene_save["ok"]:
		_show_error("%s; terrain was not published" % scene_save["message"])
		return
	var result := surface.publish()
	if not result["ok"]:
		_show_error(result["message"])
		return
	_status.text = "Terrain3D final validated and published at revision %d." % surface.terrain_revision

func _save_edited_scene_safely() -> Dictionary:
	var validation := _scene_save_guard.validate(EditorInterface.get_edited_scene_root())
	if not validation["ok"]:
		return {
			"ok": false,
			"message": _scene_save_guard.first_problem_message(validation),
		}
	var scene_error := EditorInterface.save_scene()
	if scene_error != OK:
		return {
			"ok": false,
			"message": "the authoring scene could not be saved: %s" % error_string(scene_error),
		}
	return {"ok": true}

func sync_from_edited_scene() -> void:
	var surface := _current_surface()
	if surface != null:
		_select_source(surface.source_map_id, false)
	var enabled := surface != null
	for control in [
		_reference_toggle, _reference_opacity, _grid_toggle, _grid_opacity,
		_constraints_toggle, _city_marker_toggle, _city_col, _city_row,
		_reload_base_button, _save_draft_button, _publish_button,
	]:
		if control is BaseButton:
			control.disabled = not enabled
		else:
			control.editable = enabled
	if surface == null:
		_sync_selected_height_scale()
		_sync_logical_panel()
		return
	var reference_available := surface.has_reference_texture()
	_reference_toggle.disabled = not reference_available
	_reference_opacity.editable = reference_available
	_reference_toggle.set_pressed_no_signal(surface.reference_visible)
	_reference_opacity.set_value_no_signal(surface.reference_opacity)
	_grid_toggle.set_pressed_no_signal(surface.grid_visible)
	_grid_opacity.set_value_no_signal(surface.grid_opacity)
	_constraints_toggle.set_pressed_no_signal(surface.constraints_visible)
	_city_marker_toggle.set_pressed_no_signal(surface.city_marker_visible)
	var artifact := surface.artifact()
	if artifact != null:
		_city_col.max_value = maxf(0.0, float(artifact.cols - 1))
		_city_row.max_value = maxf(0.0, float(artifact.rows - 1))
	_city_col.set_value_no_signal(surface.city_marker_coordinate.x)
	_city_row.set_value_no_signal(surface.city_marker_coordinate.y)
	_update_opacity_labels()
	_sync_selected_height_scale()
	_sync_logical_panel()
	_sync_logical_mode()

func _commit_change(
	action_name: String,
	method: StringName,
	value: Variant,
	previous_value: Variant,
	merge_mode: UndoRedo.MergeMode,
) -> void:
	var surface := _current_surface()
	if surface == null or previous_value == null or value == previous_value:
		return
	var history := EditorInterface.get_editor_undo_redo()
	history.create_action(action_name, merge_mode, surface)
	history.add_do_method(surface, method, value)
	history.add_undo_method(surface, method, previous_value)
	history.commit_action()

func _current_value(property: StringName) -> Variant:
	var surface := _current_surface()
	return surface.get(property) if surface != null else null

func _current_surface() -> AonwTerrainAuthoringSurface:
	var root := EditorInterface.get_edited_scene_root()
	if root is AonwTerrainAuthoringSurface:
		return root
	if root == null:
		return null
	return root.find_child("TerrainAuthoring", true, false) as AonwTerrainAuthoringSurface

func _selected_source() -> AonwMapSource:
	var index := _map_picker.selected
	if index < 0 or index >= _sources.size():
		_status.text = "Select a map."
		return null
	return _sources[index]

func _select_source(map_id: String, sync_panels: bool = true) -> void:
	var index := _source_index(map_id)
	if index < 0:
		return
	_map_picker.select(index)
	if sync_panels:
		_sync_selected_height_scale()
		_sync_logical_panel()
		_sync_logical_mode()

func _source_index(map_id: String) -> int:
	for index in _sources.size():
		if _sources[index].map_id == map_id:
			return index
	return -1

func _selected_map_id() -> String:
	var index := _map_picker.selected
	return _sources[index].map_id if index >= 0 and index < _sources.size() else ""

func _set_busy(busy: bool) -> void:
	_busy = busy
	if busy:
		_height_scale_timer.stop()
	_new_map_panel.set_busy(busy)
	_generate_button.disabled = busy
	_open_button.disabled = busy
	_map_picker.disabled = busy
	var source := _selected_source()
	_max_terrain_height.editable = (
		not busy and source != null and _has_editable_surface(source)
	)
	_logical_map_panel.set_editable(not busy and source != null and _has_editable_surface(source))
	_sync_logical_mode()

func _set_source_actions_enabled(enabled: bool) -> void:
	_generate_button.disabled = not enabled
	_open_button.disabled = not enabled
	_map_picker.disabled = not enabled
	var source := _selected_source() if enabled else null
	_max_terrain_height.editable = (
		enabled and not _busy and source != null and _has_editable_surface(source)
	)
	if not enabled:
		_logical_map_panel.set_editable(false)

func _show_error(message: String) -> void:
	_status.text = "Error: %s" % message
	push_error("AoNW Terrain Workbench: %s" % message)
