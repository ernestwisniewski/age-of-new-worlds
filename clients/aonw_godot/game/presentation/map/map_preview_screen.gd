extends Node3D

const OpenMap := preload("res://game/application/map/open_map.gd")
const PackagedMapCatalog := preload(
	"res://game/application/map/packaged_map_catalog.gd"
)
const ACTION_FOCUS_LEFT := &"aonw_map_focus_left"
const ACTION_FOCUS_RIGHT := &"aonw_map_focus_right"
const ACTION_FOCUS_UP := &"aonw_map_focus_up"
const ACTION_FOCUS_DOWN := &"aonw_map_focus_down"
const ACTION_ACCEPT := &"aonw_map_accept"
const ACTION_END_TURN := &"aonw_end_turn"
const ACTION_TOGGLE_GRID := &"aonw_toggle_grid"
const EXPORT_SMOKE_ARGUMENT := "--aonw-export-smoke"
const EXPORT_SMOKE_OPENED := "Godot packaged session lifecycle: opened"
const EXPORT_SMOKE_TURN_COMPLETED := "Godot packaged local turn: completed"
const EXPORT_SMOKE_CLOSED := "Godot packaged session lifecycle: closed"

@onready var _surface: AonwMapSurface = %MapSurface
@onready var _interaction: AonwMapInteractionController = %MapInteraction
@onready var _unit_layer: Node3D = %UnitLayer
@onready var _camera_rig: AonwOrbitCameraRig = %OrbitCameraRig
@onready var _map_picker: OptionButton = %MapCatalog
@onready var _grid_toggle: CheckButton = %GridToggle
@onready var _confirm_move: Button = %ConfirmMove
@onready var _turn_hud: AonwTurnHud = %TurnHud
@onready var _status: Label = %Status

var _open_map: AonwOpenMap
var _local_match: AonwLocalMatchWorkflow
var _map_catalog: PackagedMapCatalog
var _current_map: AonwMapView
var _selected_unit_id := ""
var _reachable_hexes: Dictionary = {}
var _route: AonwLocalMatchViewModels.RouteView
var _map_load_generation := 0
var _projection_ready := false
var _resyncing := false
var _resync_retry_available := false

func configure(
	open_map: AonwOpenMap,
	local_match: AonwLocalMatchWorkflow,
	map_catalog: PackagedMapCatalog,
) -> void:
	assert(_open_map == null, "Map preview dependencies are already configured")
	assert(open_map != null, "Open map use case is required")
	assert(local_match != null, "Local match workflow is required")
	assert(map_catalog != null, "Packaged map catalog is required")
	_open_map = open_map
	_local_match = local_match
	_map_catalog = map_catalog

func _ready() -> void:
	assert(_open_map != null, "Map preview composition is required")
	assert(_local_match != null, "Map preview session workflow is required")
	assert(_map_catalog != null, "Packaged map catalog is required")
	_surface.map_presented.connect(_on_map_presented)
	_interaction.hex_selected.connect(_on_hex_selected)
	_map_picker.item_selected.connect(_on_map_selected)
	_local_match.projection_invalidated.connect(_on_projection_invalidated)
	for index in range(_map_catalog.count()):
		_map_picker.add_item(_map_catalog.label_at(index))
	_map_picker.select(0)
	_open_source(_map_catalog.source_at(0))

func _exit_tree() -> void:
	if not _local_match.is_open():
		return
	var closed: Dictionary = _local_match.close()
	if not _is_export_smoke():
		return
	if closed.get("ok", false):
		print(EXPORT_SMOKE_CLOSED)
	else:
		push_error("Godot packaged session lifecycle close failed: %s" % closed.get(
			"message",
			"unknown native session error",
		))

func _unhandled_input(event: InputEvent) -> void:
	if _resyncing:
		return
	if not _projection_ready:
		if _resync_retry_available and event.is_action_pressed(ACTION_ACCEPT):
			_resync_projection()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.shift_pressed:
		return
	if event.is_action_pressed(ACTION_ACCEPT):
		if _route != null:
			_on_confirm_move_pressed()
		else:
			_interaction.select_focused()
		get_viewport().set_input_as_handled()
		return
	var focus_direction := Vector2.ZERO
	if event.is_action_pressed(ACTION_FOCUS_LEFT):
		focus_direction = Vector2.LEFT
	elif event.is_action_pressed(ACTION_FOCUS_RIGHT):
		focus_direction = Vector2.RIGHT
	elif event.is_action_pressed(ACTION_FOCUS_UP):
		focus_direction = Vector2.UP
	elif event.is_action_pressed(ACTION_FOCUS_DOWN):
		focus_direction = Vector2.DOWN
	if not focus_direction.is_zero_approx():
		if _interaction.move_focus(focus_direction):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(ACTION_TOGGLE_GRID):
		_grid_toggle.button_pressed = not _grid_toggle.button_pressed
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(ACTION_END_TURN):
		if _turn_hud.can_request_end_turn():
			_on_end_turn_pressed()
			get_viewport().set_input_as_handled()

func _on_grid_toggled(enabled: bool) -> void:
	_surface.set_grid_visible(enabled)

func _on_map_selected(index: int) -> void:
	_open_source(_map_catalog.source_at(index))

func _open_source(source: AonwMapSource) -> void:
	_map_load_generation += 1
	var generation := _map_load_generation
	_projection_ready = false
	_resync_retry_available = false
	_map_picker.disabled = true
	_status.text = "Loading map…"
	var result := await _open_map.execute_async(source)
	if generation != _map_load_generation:
		return
	if not result["ok"]:
		_status.text = "Error: %s" % result["message"]
		_report_export_smoke_failure(_status.text)
		_map_picker.disabled = _map_catalog.count() == 1
		return

	_current_map = result["map"]
	_surface.present(
		_current_map,
		result["terrain_artifact"],
		result["reference_texture"],
	)
	_interaction.present(_surface.projection())
	_status.text = "%s · %d×%d" % [
		_current_map.map_id(),
		_current_map.cols(),
		_current_map.rows(),
	]
	await _setup_local_session(source)
	if generation == _map_load_generation:
		_map_picker.disabled = _map_catalog.count() == 1

func _on_map_presented(world_size: Vector2, maximum_height: float) -> void:
	_camera_rig.frame_map(world_size, _current_map.default_zoom(), maximum_height)

func _on_hex_selected(coordinate: Vector2i) -> void:
	if not _projection_ready:
		return
	var unit_id: String = _unit_layer.unit_at(coordinate)
	if not unit_id.is_empty():
		_select_unit(unit_id, coordinate)
		return
	if not _selected_unit_id.is_empty() and _reachable_hexes.has(coordinate):
		_preview_selected_route(coordinate)
		return
	_clear_movement_selection()
	_status.text = "%s · hex %d,%d" % [_current_map.map_id(), coordinate.x, coordinate.y]

func _setup_local_session(source: AonwMapSource) -> void:
	_projection_ready = false
	_resync_retry_available = false
	_interaction.set_input_enabled(false)
	_selected_unit_id = ""
	_reachable_hexes.clear()
	_route = null
	_confirm_move.visible = false
	_turn_hud.present(null)
	_turn_hud.set_input_blocked(true)
	var opened: Dictionary = await _local_match.open(
		source,
		_current_map,
		"preview-player",
	)
	if not opened["ok"]:
		_status.text += " · Engine: %s" % opened["message"]
		_report_export_smoke_failure(_status.text)
		_present_empty_unit_layer()
		_interaction.clear_focus()
		return
	var projection: AonwLocalMatchViewModels.ProjectionView = opened["value"]
	_present_projection(projection)
	if _is_export_smoke():
		print(EXPORT_SMOKE_OPENED)
		await _run_export_smoke_turn()

func _is_export_smoke() -> bool:
	return EXPORT_SMOKE_ARGUMENT in OS.get_cmdline_user_args()

func _report_export_smoke_failure(message: String) -> void:
	if _is_export_smoke():
		push_error("Godot packaged session lifecycle failed: %s" % message)

func _run_export_smoke_turn() -> void:
	var previous_revision := _local_match.revision()
	await _on_end_turn_pressed()
	var turn := _turn_hud.current()
	if (
		turn != null
		and _local_match.revision() == previous_revision + 1
		and turn.number == 2
	):
		print(EXPORT_SMOKE_TURN_COMPLETED)
	else:
		_report_export_smoke_failure("local turn did not complete")
	get_tree().quit()

func _resync_projection() -> bool:
	if _resyncing:
		return false
	if not _local_match.is_open():
		_projection_ready = false
		_resync_retry_available = false
		_interaction.set_input_enabled(false)
		_turn_hud.set_input_blocked(true)
		_status.text = "Resync unavailable: local session is closed"
		return false
	_resyncing = true
	_projection_ready = false
	_resync_retry_available = false
	_clear_movement_selection()
	_interaction.set_input_enabled(false)
	_turn_hud.set_input_blocked(true)
	_status.text = "Resynchronizing projection…"
	var synchronized: Dictionary = await _local_match.resync()
	_resyncing = false
	if not synchronized["ok"]:
		_resync_retry_available = true
		_status.text = "Resync failed: %s · press Enter/A to retry" % synchronized["message"]
		_report_export_smoke_failure(_status.text)
		_present_empty_unit_layer()
		_interaction.clear_focus()
		return false
	var value: AonwLocalMatchViewModels.ProjectionView = synchronized["value"]
	_present_projection(value)
	_status.text = "%s · projection resynchronized at revision %d" % [
		_current_map.map_id(),
		value.revision,
	]
	return true

func _present_projection(value: AonwLocalMatchViewModels.ProjectionView) -> void:
	_unit_layer.present(_interaction.projection(), value.units)
	_turn_hud.present(value.turn)
	_turn_hud.set_input_blocked(false)
	_projection_ready = true
	_resync_retry_available = false
	_interaction.set_input_enabled(true)
	if _interaction.focused_hex() != AonwMapInteractionController.INVALID_HEX:
		return
	var coordinate := Vector2i.ZERO
	if not value.units.is_empty():
		coordinate = value.units[0].coordinate
	_interaction.focus_hex(coordinate)

func _present_empty_unit_layer() -> void:
	var units: Array[AonwLocalMatchViewModels.UnitView] = []
	_unit_layer.present(_interaction.projection(), units)

func _on_projection_invalidated() -> void:
	_projection_ready = false
	_resync_retry_available = false
	_clear_movement_selection()
	_interaction.clear_focus()
	_interaction.set_input_enabled(false)
	_present_empty_unit_layer()
	_turn_hud.present(null)
	_turn_hud.set_input_blocked(true)

func _select_unit(unit_id: String, coordinate: Vector2i) -> void:
	if not _projection_ready:
		return
	_clear_route_preview()
	_selected_unit_id = unit_id
	_reachable_hexes.clear()
	_interaction.set_reachable_hexes([])
	var reachable: Dictionary = await _local_match.reachable_async(unit_id)
	if _selected_unit_id != unit_id or _interaction.selected_hex() != coordinate:
		return
	if not reachable["ok"]:
		if reachable.get("code", "") == "stale_session_response":
			return
		if reachable.get("code", "") == "recipient_resync_required":
			await _resync_projection()
			return
		_status.text = "Engine: %s" % reachable["message"]
		return
	var coordinates: Array[Vector2i] = []
	var reachable_view: AonwLocalMatchViewModels.ReachableView = reachable["value"]
	for tile in reachable_view.tiles:
		var target := tile.coordinate
		_reachable_hexes[target] = true
		coordinates.append(target)
	_interaction.set_reachable_hexes(coordinates)
	_status.text = "%s · unit %s · reachable hexes: %d" % [
		_current_map.map_id(), unit_id, coordinates.size(),
	]
	if _interaction.selected_hex() != coordinate:
		push_error("movement selection is inconsistent with the picked hex")

func _preview_selected_route(target: Vector2i) -> void:
	if not _projection_ready:
		return
	_clear_route_preview()
	var requested_unit_id := _selected_unit_id
	var planned: Dictionary = await _local_match.route_plan_async(
		requested_unit_id,
		target,
	)
	if (
		_selected_unit_id != requested_unit_id
		or _interaction.selected_hex() != target
	):
		return
	if not planned["ok"]:
		if planned.get("code", "") == "stale_session_response":
			return
		if planned.get("code", "") == "recipient_resync_required":
			await _resync_projection()
			return
		_status.text = "Engine: %s" % planned["message"]
		return
	var route: AonwLocalMatchViewModels.RouteView = planned["value"]
	if (
		route.unit_id != requested_unit_id
		or route.target != target
		or not _current_map.contains(route.destination)
		or _unit_layer.unit_at(route.steps[0].coordinate) != _selected_unit_id
	):
		_status.text = "Engine returned a route for another request"
		return
	_route = route
	var coordinates: Array[Vector2i] = []
	for step in route.steps:
		if not _current_map.contains(step.coordinate):
			_status.text = "Engine returned an out-of-map route"
			_clear_route_preview()
			return
		coordinates.append(step.coordinate)
	_interaction.set_route_hexes(coordinates)
	_confirm_move.visible = true
	_confirm_move.disabled = false
	_status.text = "%s · route %s → %d,%d · cost %d · remaining %d" % [
		_current_map.map_id(),
		_selected_unit_id,
		route.destination.x,
		route.destination.y,
		route.total_cost_units,
		route.remaining_movement_units,
	]

func _on_confirm_move_pressed() -> void:
	if _route == null or _selected_unit_id.is_empty() or _confirm_move.disabled:
		return
	_confirm_move.disabled = true
	_move_selected_unit(_route.target)

func _move_selected_unit(target: Vector2i) -> void:
	var moved: Dictionary = await _local_match.move_unit_async(
		_selected_unit_id,
		target,
	)
	if not moved["ok"]:
		_confirm_move.disabled = false
		if moved.get("code", "") == "recipient_resync_required":
			await _resync_projection()
			return
		_status.text = "Engine: %s" % moved["message"]
		return
	var value: AonwLocalMatchViewModels.CommandResult = moved["value"]
	if not value.accepted:
		_confirm_move.disabled = false
		_status.text = "Engine: %s" % value.rejection
		return
	_unit_layer.apply_transition(value.unit_transition)
	_turn_hud.present(value.turn)
	var selected := _selected_unit_id
	_clear_movement_selection()
	if value.unit_transition.movement_steps.is_empty():
		_status.text = "%s · command accepted for %s" % [
			_current_map.map_id(), selected,
		]
	else:
		_status.text = "%s · moved %s → %d,%d" % [
			_current_map.map_id(), selected, target.x, target.y,
		]

func _on_end_turn_pressed() -> void:
	if not _turn_hud.begin_command():
		return
	_clear_movement_selection()
	var completed: Dictionary = await _local_match.end_turn_async()
	if not completed["ok"]:
		if completed.get("code", "") == "recipient_resync_required":
			await _resync_projection()
			return
		else:
			_turn_hud.cancel_command()
		_status.text = "Engine: %s" % completed["message"]
		return
	var value: AonwLocalMatchViewModels.CommandResult = completed["value"]
	if not value.accepted:
		_turn_hud.present(value.turn)
		_status.text = "Engine: %s" % value.rejection
		return
	_unit_layer.apply_transition(value.unit_transition)
	_turn_hud.present(value.turn)
	_status.text = "%s · turn advanced to %d" % [
		_current_map.map_id(), value.turn.number,
	]

func _clear_movement_selection() -> void:
	_local_match.cancel_movement_queries()
	_clear_route_preview()
	_selected_unit_id = ""
	_reachable_hexes.clear()
	_interaction.set_reachable_hexes([])
	_interaction.clear_selection()

func _clear_route_preview() -> void:
	_route = null
	_interaction.set_route_hexes([])
	_confirm_move.visible = false
	_confirm_move.disabled = false
