@tool
class_name AonwMapWorkbenchView
extends VBoxContainer

const LogicalMapPanel := preload(
	"res://editor/map_authoring/presentation/logical_map_panel.gd"
)
const NewMapPanel := preload(
	"res://editor/map_authoring/presentation/new_map_panel.gd"
)

var _new_map_panel := NewMapPanel.new()
var _map_picker := OptionButton.new()
var _generate_button := Button.new()
var _open_button := Button.new()
var _refresh_button := Button.new()
var _logical_map_panel := LogicalMapPanel.new()
var _sections := TabContainer.new()
var _max_terrain_height := HSlider.new()
var _max_terrain_height_value := Label.new()
var _height_scale_timer := Timer.new()
var _save_draft_button := Button.new()
var _publish_button := Button.new()
var _reload_base_button := Button.new()
var _status := Label.new()
var _reference_toggle := CheckButton.new()
var _reference_opacity := HSlider.new()
var _reference_opacity_value := Label.new()
var _grid_toggle := CheckButton.new()
var _grid_opacity := HSlider.new()
var _grid_opacity_value := Label.new()
var _constraints_toggle := CheckButton.new()
var _city_marker_toggle := CheckButton.new()
var _city_col := SpinBox.new()
var _city_row := SpinBox.new()

func _build_interface() -> void:
	name = "AoNW Map"
	custom_minimum_size = Vector2(300.0, 0.0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "AoNW Terrain Workbench"
	title.add_theme_font_size_override("font_size", 17)
	add_child(title)

	var description := Label.new()
	description.text = "Compiled AoNW height constraints → Terrain3D authoring"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	add_child(HSeparator.new())

	add_child(_section_label("Source map"))
	add_child(_map_picker)
	var source_actions := HBoxContainer.new()
	_refresh_button.text = "Refresh"
	_generate_button.text = "Create / open Terrain3D"
	_generate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	source_actions.add_child(_refresh_button)
	source_actions.add_child(_generate_button)
	add_child(source_actions)
	_open_button.text = "Open saved scene"
	add_child(_open_button)

	_sections.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sections.custom_minimum_size.y = 240.0
	add_child(_sections)

	var new_map_content := _scrollable_tab("New Map")
	new_map_content.add_child(_new_map_panel)

	var logical_map_content := _scrollable_tab("Logical Map")
	logical_map_content.add_child(_logical_map_panel)

	var terrain_content := _scrollable_tab("Terrain3D")
	terrain_content.add_child(_section_label("Map height scale"))
	_max_terrain_height.min_value = 0.5
	_max_terrain_height.max_value = 10000.0
	_max_terrain_height.step = 0.5
	_max_terrain_height.exp_edit = true
	_max_terrain_height.tooltip_text = (
		"Metric height assigned to logical level 5; releasing the slider rescales Terrain3D"
	)
	terrain_content.add_child(_height_control())
	terrain_content.add_child(HSeparator.new())

	terrain_content.add_child(_section_label("Reference"))
	_reference_toggle.text = "Show reference texture"
	_reference_toggle.button_pressed = true
	terrain_content.add_child(_reference_toggle)
	_configure_opacity(_reference_opacity, 0.65)
	terrain_content.add_child(
		_opacity_control("Reference opacity", _reference_opacity, _reference_opacity_value)
	)

	terrain_content.add_child(_section_label("Debug overlays"))
	_grid_toggle.text = "Show hex grid"
	_grid_toggle.button_pressed = true
	terrain_content.add_child(_grid_toggle)
	_configure_opacity(_grid_opacity, 0.72)
	terrain_content.add_child(_opacity_control("Grid opacity", _grid_opacity, _grid_opacity_value))
	_constraints_toggle.text = "Show min / max envelopes"
	terrain_content.add_child(_constraints_toggle)

	terrain_content.add_child(_section_label("City scale marker"))
	_city_marker_toggle.text = "Show city-core footprint"
	_city_marker_toggle.button_pressed = true
	terrain_content.add_child(_city_marker_toggle)
	var marker_coordinates := HBoxContainer.new()
	_configure_coordinate(_city_col, "Col")
	_configure_coordinate(_city_row, "Row")
	marker_coordinates.add_child(_labeled_control("Col", _city_col))
	marker_coordinates.add_child(_labeled_control("Row", _city_row))
	terrain_content.add_child(marker_coordinates)
	terrain_content.add_child(HSeparator.new())

	_reload_base_button.text = "Reload compiled base / constraints"
	_reload_base_button.tooltip_text = "Keeps the manually sculpted final Terrain3D data"
	terrain_content.add_child(_reload_base_button)
	var persistence_actions := HBoxContainer.new()
	_save_draft_button.text = "Save draft"
	_save_draft_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_publish_button.text = "Validate & publish"
	_publish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	persistence_actions.add_child(_save_draft_button)
	persistence_actions.add_child(_publish_button)
	terrain_content.add_child(persistence_actions)

	_status.text = "Select a map with a compiled terrain profile."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.y = 42.0
	add_child(_status)
	_height_scale_timer.one_shot = true
	_height_scale_timer.wait_time = 0.35
	add_child(_height_scale_timer)
	_update_max_height_label()
	_update_opacity_labels()

func _scrollable_tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sections.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return content

func _height_control() -> VBoxContainer:
	var container := VBoxContainer.new()
	var header := HBoxContainer.new()
	var label := Label.new()
	label.text = "Maximum height of logical level 5"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_max_terrain_height_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_max_terrain_height_value.custom_minimum_size.x = 72.0
	header.add_child(label)
	header.add_child(_max_terrain_height_value)
	container.add_child(header)
	container.add_child(_max_terrain_height)
	return container

func _configure_opacity(slider: HSlider, value: float) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value

func _configure_coordinate(spin_box: SpinBox, tooltip: String) -> void:
	spin_box.min_value = 0.0
	spin_box.max_value = 0.0
	spin_box.step = 1.0
	spin_box.tooltip_text = tooltip
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label

func _labeled_control(text: String, control: Control) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = text
	container.add_child(label)
	container.add_child(control)
	return container

func _opacity_control(text: String, slider: HSlider, value_label: Label) -> VBoxContainer:
	var container := VBoxContainer.new()
	var header := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 48.0
	header.add_child(label)
	header.add_child(value_label)
	container.add_child(header)
	container.add_child(slider)
	return container

func _update_opacity_labels() -> void:
	_reference_opacity_value.text = "%d%%" % roundi(_reference_opacity.value * 100.0)
	_grid_opacity_value.text = "%d%%" % roundi(_grid_opacity.value * 100.0)

func _update_max_height_label() -> void:
	_max_terrain_height_value.text = "%.1f m" % _max_terrain_height.value
