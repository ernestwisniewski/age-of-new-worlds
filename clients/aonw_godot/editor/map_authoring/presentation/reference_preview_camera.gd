@tool
extends Camera3D
## Strategic perspective with real dolly zoom, plus an orthographic reference view.

var _target := Vector3.ZERO
var _extent := Vector2.ONE
var _maximum_height := 1.0
var _yaw := 0.0
var _elevation := deg_to_rad(52.0)
var _zoom := 1.0
var _fov := 38.0
var _distance := 1.0
var _top_down := false
var _framed := false

func _ready() -> void:
	set_process_unhandled_input(not Engine.is_editor_hint())

func configure_view(pitch: float, heading: float, zoom: float, field_of_view: float) -> void:
	_elevation = deg_to_rad(clampf(pitch, 25.0, 80.0))
	_yaw = deg_to_rad(heading)
	_zoom = clampf(zoom, 0.5, 8.0)
	_fov = clampf(field_of_view, 20.0, 65.0)
	_top_down = false
	if _framed:
		_update_transform()

func frame_terrain(extent: Vector2, maximum_height: float, top_down: bool) -> void:
	_extent = extent
	_maximum_height = maximum_height
	_target = Vector3(extent.x * 0.5, maximum_height * 0.25, extent.y * 0.5)
	_top_down = top_down
	_framed = true
	_update_transform()

func _update_transform() -> void:
	if not is_inside_tree():
		return
	keep_aspect = Camera3D.KEEP_HEIGHT
	near = 0.1
	fov = _fov
	var pitch := PI * 0.5 if _top_down else _elevation
	var direction := Vector3(sin(_yaw) * cos(pitch), sin(pitch), cos(_yaw) * cos(pitch))
	# A bounding sphere remains framed at every heading and in narrow dock previews.
	var radius := Vector3(_extent.x, _maximum_height, _extent.y).length() * 0.5
	_distance = maxf(10.0, radius / sin(deg_to_rad(_fov) * 0.5) * 1.12 / _zoom)
	projection = Camera3D.PROJECTION_ORTHOGONAL if _top_down else Camera3D.PROJECTION_PERSPECTIVE
	size = maxf(_extent.x, _extent.y) * 1.12 / _zoom
	far = maxf(8000.0, _distance + radius * 4.0)
	position = _target + direction * _distance
	var up := Vector3.FORWARD if _top_down else Vector3.UP
	look_at(get_parent_node_3d().to_global(_target), get_parent_node_3d().global_basis * up)

func navigate(event: InputEvent, viewport_height: float = 720.0) -> bool:
	if not _framed:
		return false
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE or (event.button_mask & MOUSE_BUTTON_MASK_RIGHT and event.shift_pressed):
			var span := size if _top_down else 2.0 * _distance * tan(deg_to_rad(fov) * 0.5)
			var right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
			var up := Vector3(basis.y.x, 0.0, basis.y.z).normalized()
			_target += (-right * event.relative.x + up * event.relative.y) * span / maxf(viewport_height, 1.0)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_yaw -= event.relative.x * 0.006
			_elevation = clampf(_elevation + event.relative.y * 0.006, deg_to_rad(25.0), deg_to_rad(80.0))
			_top_down = false
		else:
			return false
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom * 1.12, 0.5, 8.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom / 1.12, 0.5, 8.0)
		else:
			return false
	elif event is InputEventMagnifyGesture:
		_zoom = clampf(_zoom * maxf(event.factor, 0.01), 0.5, 8.0)
	elif event is InputEventPanGesture:
		var span := size if _top_down else 2.0 * _distance * tan(deg_to_rad(fov) * 0.5)
		_target += (-basis.x * event.delta.x + Vector3(basis.y.x, 0.0, basis.y.z).normalized() * event.delta.y) * span / maxf(viewport_height, 1.0) * 12.0
	else:
		return false
	_update_transform()
	return true

func view_parameters() -> Dictionary:
	return {"camera_pitch": rad_to_deg(_elevation), "camera_yaw": wrapf(rad_to_deg(_yaw), -180.0, 180.0), "camera_zoom": _zoom, "camera_fov": _fov}

func _unhandled_input(event: InputEvent) -> void:
	if navigate(event, get_viewport().get_visible_rect().size.y):
		get_viewport().set_input_as_handled()
