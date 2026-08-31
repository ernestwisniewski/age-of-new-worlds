@tool
class_name AonwLogicalMapPanel
extends VBoxContainer

signal edit_persisted(source: AonwMapSource, coordinates: Array[Vector2i])
signal error_raised(message: String)
signal status_changed(message: String)

enum Brush {
	INSPECT,
	TERRAIN,
	RESOURCES,
	HEIGHT,
}

const INVALID_HEX := Vector2i(-1, -1)

var _editor: AonwLogicalMapEditor
var _source: AonwMapSource
var _editable := false
var _busy := false
var _selected_coordinate := Vector2i.ZERO
var _stroke_active := false
var _stroke_coordinates: Array[Vector2i] = []
var _stroke_seen := {}
var _stroke_brush := Brush.INSPECT
var _stroke_value: Variant
var _stroke_source: AonwMapSource
var _cursor_label := Label.new()
var _selected_label := Label.new()
var _brush := OptionButton.new()
var _terrain := OptionButton.new()
var _resources := ItemList.new()
var _height := SpinBox.new()
var _reload := Button.new()

func _ready() -> void:
	_build_interface()
	_reload.pressed.connect(refresh)
	_apply_enabled()

func configure(editor: AonwLogicalMapEditor) -> void:
	assert(editor != null, "Logical map editor is required")
	_editor = editor

func show_source(source: AonwMapSource, editable: bool) -> void:
	_source = source
	_editable = editable
	_selected_coordinate = Vector2i.ZERO
	cancel_paint_stroke()
	_apply_enabled()
	refresh()

func set_editable(value: bool) -> void:
	_editable = value
	if not value:
		cancel_paint_stroke()
	_apply_enabled()

func can_interact() -> bool:
	return _can_edit() and not _busy

func is_inspect_tool() -> bool:
	return _brush.selected == Brush.INSPECT

func preview_coordinate(coordinate: Vector2i) -> void:
	_cursor_label.text = (
		"Cursor: outside map"
		if coordinate == INVALID_HEX
		else "Cursor: (%d, %d)" % [coordinate.x, coordinate.y]
	)

func inspect_coordinate(coordinate: Vector2i) -> void:
	if not can_interact() or coordinate == INVALID_HEX:
		return
	_selected_coordinate = coordinate
	refresh()

func begin_paint_stroke() -> bool:
	if not can_interact() or is_inspect_tool():
		return false
	var value_result := _current_brush_value()
	if not value_result["ok"]:
		error_raised.emit(value_result["message"])
		return false
	_stroke_active = true
	_stroke_coordinates.clear()
	_stroke_seen.clear()
	_stroke_brush = _brush.selected
	_stroke_value = value_result["value"]
	_stroke_source = _source
	return true

func append_paint_coordinate(coordinate: Vector2i) -> void:
	if not _stroke_active or coordinate == INVALID_HEX or _stroke_seen.has(coordinate):
		return
	_stroke_seen[coordinate] = true
	_stroke_coordinates.append(coordinate)

func end_paint_stroke() -> void:
	if not _stroke_active:
		return
	_stroke_active = false
	if _stroke_coordinates.is_empty():
		_clear_stroke()
		return
	_set_busy(true)
	status_changed.emit(
		"Applying %d logical tile edit(s) through Rust and recompiling Terrain3D…"
		% _stroke_coordinates.size()
	)
	_apply_stroke.call_deferred()

func cancel_paint_stroke() -> void:
	if _busy:
		return
	_stroke_active = false
	_clear_stroke()

func refresh() -> void:
	if _editor == null or _source == null:
		return
	var result := _editor.inspect_tile(_source, _selected_coordinate)
	if not result["ok"]:
		error_raised.emit(result["message"])
		return
	_apply_snapshot(result["snapshot"])

func _build_interface() -> void:
	if get_child_count() > 0:
		return
	var help := Label.new()
	help.text = (
		"Choose a brush, then click or drag over hexes in the 3D viewport. "
		+ "Rust remains the canonical map writer."
	)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)
	_cursor_label.text = "Cursor: outside map"
	add_child(_cursor_label)
	_selected_label.text = "Selected hex: (0, 0)"
	add_child(_selected_label)
	_configure_brushes()
	add_child(_labeled_control("Viewport tool", _brush))
	_reload.text = "Reload selected hex"
	add_child(_reload)
	add_child(HSeparator.new())
	add_child(_labeled_control("Terrain brush", _terrain))
	_resources.select_mode = ItemList.SELECT_MULTI
	_resources.allow_reselect = true
	_resources.custom_minimum_size.y = 112.0
	add_child(_labeled_control("Resource brush", _resources))
	_height.min_value = 0.0
	_height.max_value = 5.0
	_height.step = 1.0
	add_child(_labeled_control("Logical height brush", _height))

func _configure_brushes() -> void:
	for label in ["Select / inspect", "Paint terrain", "Paint resources", "Paint height"]:
		_brush.add_item(label)
	_brush.select(Brush.INSPECT)

func _apply_stroke() -> void:
	await get_tree().process_frame
	var coordinates: Array[Vector2i] = _stroke_coordinates.duplicate()
	var source := _stroke_source
	var result: Dictionary
	match _stroke_brush:
		Brush.TERRAIN:
			result = _editor.paint_tiles_terrain(
				source,
				coordinates,
				StringName(_stroke_value),
			)
		Brush.RESOURCES:
			var resources: Array[StringName] = []
			for resource in _stroke_value:
				resources.append(StringName(resource))
			result = _editor.paint_tiles_resources(source, coordinates, resources)
		Brush.HEIGHT:
			result = _editor.paint_tiles_height(source, coordinates, int(_stroke_value))
		_:
			result = {"ok": false, "message": "logical paint brush is unsupported"}
	_complete_stroke(result, source, coordinates)

func _complete_stroke(
	result: Dictionary,
	source: AonwMapSource,
	coordinates: Array[Vector2i],
) -> void:
	_set_busy(false)
	if not result["ok"]:
		_clear_stroke()
		error_raised.emit(result["message"])
		return
	if _source == source:
		_apply_snapshot(result["update"]["snapshot"])
	_clear_stroke()
	edit_persisted.emit(source, coordinates)

func _current_brush_value() -> Dictionary:
	match _brush.selected:
		Brush.TERRAIN:
			if _terrain.selected < 0:
				return _failure("select a terrain brush")
			return {"ok": true, "value": _terrain.get_item_metadata(_terrain.selected)}
		Brush.RESOURCES:
			var values: Array[StringName] = []
			for index in _resources.get_selected_items():
				values.append(StringName(_resources.get_item_metadata(index)))
			return {"ok": true, "value": values}
		Brush.HEIGHT:
			return {"ok": true, "value": roundi(_height.value)}
	return _failure("select a paint brush")

func _apply_snapshot(snapshot: Dictionary) -> void:
	_selected_coordinate = Vector2i(snapshot["tile"]["col"], snapshot["tile"]["row"])
	_selected_label.text = "Selected hex: (%d, %d)" % [
		_selected_coordinate.x,
		_selected_coordinate.y,
	]
	_terrain.clear()
	var selected_terrain := 0
	for terrain_name in snapshot["terrainOptions"]:
		_terrain.add_item(str(terrain_name).capitalize())
		var terrain_index := _terrain.item_count - 1
		_terrain.set_item_metadata(terrain_index, terrain_name)
		if terrain_name == snapshot["tile"]["displayTerrain"]:
			selected_terrain = terrain_index
	_terrain.select(selected_terrain)
	_resources.clear()
	for resource_name in snapshot["resourceOptions"]:
		_resources.add_item(str(resource_name).capitalize())
		var resource_index := _resources.item_count - 1
		_resources.set_item_metadata(resource_index, resource_name)
		if resource_name in snapshot["tile"]["resources"]:
			_resources.select(resource_index, false)
	_height.set_value_no_signal(snapshot["tile"]["height"])

func _can_edit() -> bool:
	return _editor != null and _source != null and _editable

func _set_busy(busy: bool) -> void:
	_busy = busy
	_apply_enabled()

func _apply_enabled() -> void:
	var enabled := _can_edit() and not _busy
	_brush.disabled = not enabled
	_height.editable = enabled
	_terrain.disabled = not enabled
	_resources.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	_resources.modulate = Color.WHITE if enabled else Color(1.0, 1.0, 1.0, 0.5)
	_reload.disabled = not enabled

func _clear_stroke() -> void:
	_stroke_coordinates.clear()
	_stroke_seen.clear()
	_stroke_brush = Brush.INSPECT
	_stroke_value = null
	_stroke_source = null

func _labeled_control(text: String, control: Control) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = text
	container.add_child(label)
	container.add_child(control)
	return container

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
