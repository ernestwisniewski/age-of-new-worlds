class_name AonwOrbitCameraRig
extends Node3D

@export_range(0.002, 0.02, 0.001) var orbit_sensitivity := 0.006
@export_range(0.1, 3.0, 0.1) var zoom_sensitivity := 0.9
@export_range(0.1, 5.0, 0.1) var pan_speed := 1.5

@onready var _yaw: Node3D = %Yaw
@onready var _pitch: Node3D = %Pitch
@onready var _camera: Camera3D = %Camera

var _distance := 12.0
var _minimum_distance := 2.0
var _maximum_distance := 80.0
var _orbiting := false
var _panning := false

func _ready() -> void:
	_yaw.rotation.y = deg_to_rad(-18.0)
	_pitch.rotation.x = deg_to_rad(-52.0)
	_update_distance()

func _process(delta: float) -> void:
	if not Input.is_key_pressed(KEY_SHIFT):
		return
	var movement := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"),
	)
	if movement.is_zero_approx():
		return
	var speed := pan_speed * _distance * 0.12 * delta
	var right := _yaw.global_basis.x
	var forward := -_yaw.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	global_position += (right.normalized() * movement.x + forward.normalized() * movement.y) * speed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = event.pressed
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-zoom_sensitivity)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(zoom_sensitivity)
	if event is InputEventMouseMotion and _orbiting:
		_yaw.rotation.y -= event.relative.x * orbit_sensitivity
		_pitch.rotation.x = clampf(
			_pitch.rotation.x - event.relative.y * orbit_sensitivity,
			deg_to_rad(-82.0),
			deg_to_rad(-25.0),
		)
	if event is InputEventMouseMotion and _panning:
		var scale := _distance * 0.0015
		global_position += _yaw.global_basis.x * -event.relative.x * scale
		var forward := -_yaw.global_basis.z
		forward.y = 0.0
		global_position += forward.normalized() * event.relative.y * scale

func frame_map(world_size: Vector2, zoom_hint: float = 1.0, maximum_height: float = 0.0) -> void:
	global_position = Vector3(world_size.x * 0.5, 0.0, world_size.y * 0.5)
	_minimum_distance = maxf(1.5, minf(world_size.x, world_size.y) * 0.25)
	_maximum_distance = maxf(world_size.x, world_size.y) * 5.0
	_distance = clampf(maxf(world_size.x, world_size.y) * 1.35 / zoom_hint, _minimum_distance, _maximum_distance)
	_camera.far = maxf(300.0, _maximum_distance * 2.0 + maximum_height + 10.0)
	_update_distance()

func _zoom(amount: float) -> void:
	_distance = clampf(_distance * (1.0 + amount * 0.12), _minimum_distance, _maximum_distance)
	_update_distance()

func _update_distance() -> void:
	_camera.position = Vector3(0.0, 0.0, _distance)
