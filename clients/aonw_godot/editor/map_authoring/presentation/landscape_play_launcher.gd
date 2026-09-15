extends Node
## F5 entry point for this authoring branch. F6 still runs each reference scene directly.
const Template := preload("res://scenes/terrain_authoring/reference_terrain.tscn")
const Catalog := preload("res://editor/map_authoring/infrastructure/map_asset_catalog.gd")
@export var initial_map_id := ""
var _preview: Node3D
var _maps := OptionButton.new()
var _status := Label.new()
var _busy := false
var _scene_path := ""
var _remembered_id := ""
var _buttons: Array[Button] = []

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(14.0, 14.0)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	row.add_child(_maps)
	for source in Catalog.new().discover():
		_maps.add_item(source.map_id)
	_maps.item_selected.connect(_select_map)
	for definition in [["Landscape", "show_oblique_view"], ["Reference", "show_top_view"], ["Compare", "toggle_reference"], ["Grid", "toggle_grid"]]:
		var button := Button.new()
		button.text = definition[0]
		button.pressed.connect(_view.bind(definition[1]))
		row.add_child(button)
		_buttons.append(button)
	_status.custom_minimum_size.x = 610.0
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)
	var hint := Label.new()
	hint.text = "Right drag: orbit · Middle / Shift-right: pan · Wheel / pinch: zoom · 1 / 2: reference / landscape"
	column.add_child(hint)
	var config := ConfigFile.new()
	if config.load("res://.godot/aonw_landscape_preview.cfg") == OK:
		_remembered_id = str(config.get_value("preview", "map_id", ""))
		_scene_path = str(config.get_value("preview", "scene_path", ""))
	if not initial_map_id.is_empty():
		_remembered_id = initial_map_id
		_scene_path = ""
	var selected := 0
	for index in _maps.item_count:
		if _maps.get_item_text(index) == _remembered_id or (_remembered_id.is_empty() and _maps.get_item_text(index) == "dravonia"):
			selected = index
	if _maps.item_count == 0:
		_status.text = "No maps found in the AoNW map catalog."
		return
	_maps.select(selected)
	_select_map.call_deferred(selected)

func _select_map(index: int) -> void:
	if _busy:
		return
	_busy = true
	_set_enabled(false)
	var id := _maps.get_item_text(index)
	_status.text = "Generating " + id + " — reading the reference, terrain and visual assets…"
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_preview):
		remove_child(_preview)
		_preview.free()
	var packed: PackedScene = Template
	if id == _remembered_id and _scene_path.begins_with("res://scenes/terrain_authoring/") and ResourceLoader.exists(_scene_path):
		var saved := load(_scene_path) as PackedScene
		if saved != null:
			packed = saved
	_preview = packed.instantiate() as Node3D
	if _preview == null or not _preview.has_method("ensure_reference_session"):
		if _preview != null:
			_preview.free()
		_preview = Template.instantiate()
	_preview.set("source_map_id", id)
	add_child(_preview)
	var opened: Dictionary = await _preview.call("ensure_reference_session")
	if opened["ok"]:
		_preview.get_node("PreviewHUD").hide()
		_preview.call("show_oblique_view")
		_preview.connect("preview_state_changed", _refresh_status)
		_refresh_status()
	else:
		_status.text = "Cannot render " + id + ": " + str(opened.get("message", "Unknown error"))
	_busy = false
	_set_enabled(true)

func _refresh_status() -> void:
	if is_instance_valid(_preview):
		_status.text = str(_preview.get("source_map_id")) + " · " + str(_preview.get("landscape_status"))

func _view(method: String) -> void:
	if not _busy and is_instance_valid(_preview):
		_preview.call(method)

func _set_enabled(enabled: bool) -> void:
	_maps.disabled = not enabled
	for button in _buttons:
		button.disabled = not enabled
