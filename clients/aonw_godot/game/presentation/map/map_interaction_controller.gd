class_name AonwMapInteractionController
extends Node

signal hex_hovered(coordinate: Vector2i)
signal hex_focused(coordinate: Vector2i)
signal hex_selected(coordinate: Vector2i)

const INVALID_HEX := Vector2i(-1, -1)

@onready var _surface: AonwMapSurface = %MapSurface
@onready var _overlay: AonwMapOverlayLayer = %MapOverlay
@onready var _camera: Camera3D = %Camera

var _projection: AonwHexMapProjection
var _hovered := INVALID_HEX
var _focused := INVALID_HEX
var _selected := INVALID_HEX
var _input_enabled := true

func present(projection: AonwHexMapProjection) -> void:
	_projection = projection
	_hovered = INVALID_HEX
	_focused = INVALID_HEX
	_selected = INVALID_HEX
	_input_enabled = true
	_overlay.present(_projection)

func selected_hex() -> Vector2i:
	return _selected

func hovered_hex() -> Vector2i:
	return _hovered

func focused_hex() -> Vector2i:
	return _focused

func is_input_enabled() -> bool:
	return _input_enabled

func projection() -> AonwHexMapProjection:
	return _projection

func set_reachable_hexes(coordinates: Array) -> void:
	_overlay.set_reachable(coordinates)

func set_route_hexes(coordinates: Array) -> void:
	_overlay.set_route(coordinates)

func clear_selection() -> void:
	_selected = INVALID_HEX
	_overlay.set_selected(INVALID_HEX)

func clear_focus() -> void:
	_set_focused(INVALID_HEX)

func set_input_enabled(value: bool) -> void:
	_input_enabled = value

func focus_hex(coordinate: Vector2i) -> bool:
	if not _input_enabled or _projection == null or not _projection.contains(coordinate):
		return false
	_set_focused(coordinate)
	return true

func move_focus(direction: Vector2) -> bool:
	if not _input_enabled or _projection == null or direction.is_zero_approx():
		return false
	if not _projection.contains(_focused):
		return focus_hex(Vector2i.ZERO)
	var geometry := _projection.geometry()
	var origin := geometry.tile_center(_focused)
	var desired := direction.normalized()
	var best := INVALID_HEX
	var best_alignment := -INF
	for candidate in geometry.neighbors(_focused):
		if not _projection.contains(candidate):
			continue
		var candidate_direction := (geometry.tile_center(candidate) - origin).normalized()
		var alignment := candidate_direction.dot(desired)
		if alignment > best_alignment:
			best = candidate
			best_alignment = alignment
	if best == INVALID_HEX or best_alignment <= 0.0:
		return false
	_set_focused(best)
	return true

func select_focused() -> bool:
	if not _input_enabled or _projection == null or not _projection.contains(_focused):
		return false
	_selected = _focused
	_overlay.set_selected(_selected)
	hex_selected.emit(_selected)
	return true

func pick_screen_position(screen_position: Vector2) -> Vector2i:
	if _projection == null:
		return INVALID_HEX
	var inverse := _surface.global_transform.affine_inverse()
	var local_origin := inverse * _camera.project_ray_origin(screen_position)
	var local_direction := (
		inverse.basis * _camera.project_ray_normal(screen_position)
	).normalized()
	return _surface.pick_ray(local_origin, local_direction)

func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if event is InputEventMouseMotion:
		_set_hovered(pick_screen_position(event.position))
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		var coordinate := pick_screen_position(event.position)
		if coordinate != INVALID_HEX:
			_set_focused(coordinate)
			_selected = coordinate
			_overlay.set_selected(coordinate)
			hex_selected.emit(coordinate)
			get_viewport().set_input_as_handled()

func _set_hovered(coordinate: Vector2i) -> void:
	if coordinate == _hovered:
		return
	_hovered = coordinate
	_overlay.set_hovered(coordinate)
	hex_hovered.emit(coordinate)

func _set_focused(coordinate: Vector2i) -> void:
	if coordinate == _focused:
		return
	_focused = coordinate
	_overlay.set_focused(coordinate)
	hex_focused.emit(coordinate)
