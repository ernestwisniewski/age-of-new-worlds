@tool
class_name AonwNewMapPanel
extends VBoxContainer

signal create_requested(
	map_id: String,
	cols: int,
	rows: int,
	default_zoom: float,
	hex_radius_meters: float,
	max_terrain_height_meters: float,
	seed: String,
	generator_id: StringName,
)

var _generator := OptionButton.new()
var _map_id := LineEdit.new()
var _cols := SpinBox.new()
var _rows := SpinBox.new()
var _default_zoom := SpinBox.new()
var _hex_radius := SpinBox.new()
var _max_height := SpinBox.new()
var _seed := LineEdit.new()
var _create := Button.new()

func _ready() -> void:
	_build_interface()
	_create.pressed.connect(_request_creation)
	_generator.item_selected.connect(_generator_selected)

func set_busy(busy: bool) -> void:
	_map_id.editable = not busy
	_seed.editable = not busy
	_generator.disabled = busy
	for value in [_cols, _rows, _default_zoom, _hex_radius, _max_height]:
		value.editable = not busy
	_create.disabled = busy

func _build_interface() -> void:
	if get_child_count() > 0:
		return
	var help := Label.new()
	help.text = "Rust creates the canonical map, terrain profile, and generated world plan."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)
	_add_generator("Blank authoring canvas", &"blank")
	_add_generator("Procedural continent", &"continental")
	_generator.select(0)
	add_child(_labeled_control("Generator", _generator))
	_map_id.placeholder_text = "new_europe"
	_map_id.max_length = 64
	_map_id.tooltip_text = "Lowercase map identifier, for example new_europe"
	add_child(_labeled_control("Map ID", _map_id))
	var dimensions := HBoxContainer.new()
	_configure_integer(_cols, 5.0, 40.0, 7.0)
	_configure_integer(_rows, 5.0, 30.0, 7.0)
	dimensions.add_child(_labeled_control("Columns", _cols))
	dimensions.add_child(_labeled_control("Rows", _rows))
	add_child(dimensions)
	_default_zoom.min_value = 0.1
	_default_zoom.max_value = 10.0
	_default_zoom.step = 0.05
	_default_zoom.value = 1.0
	add_child(_labeled_control("Default zoom", _default_zoom))
	var metric_scale := HBoxContainer.new()
	_hex_radius.min_value = 0.5
	_hex_radius.max_value = 10000.0
	_hex_radius.step = 0.5
	_hex_radius.value = 10.0
	_hex_radius.suffix = " m"
	_max_height.min_value = 0.5
	_max_height.max_value = 10000.0
	_max_height.step = 0.5
	_max_height.value = 20.0
	_max_height.suffix = " m"
	metric_scale.add_child(_labeled_control("Hex radius", _hex_radius))
	metric_scale.add_child(_labeled_control("Level 5 height", _max_height))
	add_child(metric_scale)
	_seed.text = "0"
	_seed.tooltip_text = "Decimal unsigned 64-bit seed retained for procedural generation"
	add_child(_labeled_control("Generation seed", _seed))
	_update_create_label()
	add_child(_create)

func _request_creation() -> void:
	create_requested.emit(
		_map_id.text.strip_edges(),
		roundi(_cols.value),
		roundi(_rows.value),
		_default_zoom.value,
		_hex_radius.value,
		_max_height.value,
		_seed.text.strip_edges(),
		StringName(_generator.get_item_metadata(_generator.selected)),
	)

func _add_generator(label: String, generator_id: StringName) -> void:
	_generator.add_item(label)
	_generator.set_item_metadata(_generator.item_count - 1, generator_id)

func _generator_selected(_index: int) -> void:
	_update_create_label()

func _update_create_label() -> void:
	var generator_id := str(_generator.get_item_metadata(_generator.selected))
	_create.text = (
		"Generate procedural Terrain3D map"
		if generator_id == "continental"
		else "Create blank Terrain3D map"
	)

func _configure_integer(control: SpinBox, minimum: float, maximum: float, value: float) -> void:
	control.min_value = minimum
	control.max_value = maximum
	control.step = 1.0
	control.value = value
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _labeled_control(text: String, control: Control) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = text
	container.add_child(label)
	container.add_child(control)
	return container
