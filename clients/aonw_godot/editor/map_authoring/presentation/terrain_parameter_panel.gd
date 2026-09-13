@tool
extends VBoxContainer

const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
signal parameter_changed(key: String, value: float)
signal apply_requested
signal discard_requested
signal preset_requested(name: String)

var ranges: Dictionary = {}
var _labels: Dictionary = {}
var _apply := Button.new()
var _discard := Button.new()
var _preset := OptionButton.new()
var _status := Label.new()

func _ready() -> void:
	_preset.add_item("Choose a terrain preset…")
	for preset in ["Reference faithful", "Strategic natural", "Rugged"]:
		_preset.add_item(preset)
	_preset.item_selected.connect(_choose_preset)
	add_child(_preset)
	var previous_stage := ""
	for field in Parameters.FIELDS:
		var key: String = field[0]
		if key == "level_height":
			continue # The original metric-height slider remains the single control.
		if field[6] != previous_stage:
			var header := Label.new()
			header.text = {"terrain": "Landscape · apply to rebuild", "appearance": "Material and light · live", "camera": "Strategic camera · live"}[field[6]]
			add_child(HSeparator.new())
			add_child(header)
			previous_stage = field[6]
		var line := HBoxContainer.new()
		var label := Label.new()
		label.text = field[1]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_child(label)
		var value_label := Label.new()
		line.add_child(value_label)
		_labels[key] = value_label
		add_child(line)
		var range_control: Range = SpinBox.new() if key == "seed" else HSlider.new()
		range_control.min_value = field[2]
		range_control.max_value = field[3]
		range_control.step = field[4]
		range_control.value = field[5]
		range_control.tooltip_text = field[7]
		range_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		range_control.value_changed.connect(_value_changed.bind(key))
		ranges[key] = range_control
		add_child(range_control)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	_apply.text = "Apply / rebuild landscape"
	_apply.pressed.connect(func() -> void: apply_requested.emit())
	add_child(_apply)
	_discard.text = "Discard pending geometry settings"
	_discard.pressed.connect(func() -> void: discard_requested.emit())
	add_child(_discard)

func show_values(values: Dictionary, enabled: bool, pending: bool) -> void:
	for key in ranges:
		var range_control: Range = ranges[key]
		range_control.set_value_no_signal(values.get(key, Parameters.descriptor(key)[5]))
		range_control.set("editable", enabled)
		_labels[key].text = str(int(range_control.value)) if key == "seed" else "%.2f" % range_control.value
	_apply.disabled = not enabled
	_discard.disabled = not enabled or not pending
	_preset.disabled = not enabled
	_status.text = "Pending geometry changes. Apply saves the current draft before switching recipes." if pending else "No pending numeric geometry settings. Apply also reloads image guides and source data; appearance and camera are live."

func _value_changed(value: float, key: String) -> void:
	_labels[key].text = str(int(value)) if key == "seed" else "%.2f" % value
	parameter_changed.emit(key, value)

func _choose_preset(index: int) -> void:
	if index > 0:
		preset_requested.emit(_preset.get_item_text(index))
	_preset.select(0)
