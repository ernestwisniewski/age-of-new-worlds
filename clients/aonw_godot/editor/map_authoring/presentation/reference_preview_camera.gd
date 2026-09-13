@tool
extends Camera3D
## Authoring-camera presets and standalone F6 navigation; no gameplay input map.

const DISTANCE := 1400.0
const FRAME_MARGIN := 1.12
var _target := Vector3.ZERO
var _yaw := 0.0
var _elevation := PI / 3.0
var _framed := false

func _ready() -> void:
	# Navigation also works when Frame On Open is disabled for a saved camera.
	_target = position - basis.z * DISTANCE
	_yaw = atan2(basis.z.x, basis.z.z)
	_elevation = asin(clampf(basis.z.y, -1.0, 1.0))
	_framed = true
	set_process_unhandled_input(not Engine.is_editor_hint())

func frame_terrain(extent: Vector2, maximum_height: float, top_down: bool) -> void:
	_target = Vector3(extent.x * 0.5, maximum_height * 0.5, extent.y * 0.5)
	_yaw = 0.0
	_elevation = PI * 0.5 if top_down else PI / 3.0
	projection = Camera3D.PROJECTION_ORTHOGONAL
	keep_aspect = Camera3D.KEEP_HEIGHT
	near = 0.1
	far = 8000.0
	_update_transform()
	# Fit all eight bounds corners rather than assuming a 16:9 window.
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := maxf(viewport_size.x / maxf(viewport_size.y, 1.0), 0.01)
	var inverse := transform.affine_inverse()
	var horizontal := 0.0
	var vertical := 0.0
	for x in [0.0, extent.x]:
		for y in [0.0, maximum_height]:
			for z in [0.0, extent.y]:
				var point: Vector3 = inverse * Vector3(x, y, z)
				horizontal = maxf(horizontal, absf(point.x))
				vertical = maxf(vertical, absf(point.y))
	size = maxf(vertical, horizontal / aspect) * 2.0 * FRAME_MARGIN
	_framed = true

func _update_transform() -> void:
	var direction := Vector3(
		sin(_yaw) * cos(_elevation), sin(_elevation), cos(_yaw) * cos(_elevation),
	)
	position = _target + direction * DISTANCE
	# A top-down camera needs north, not world-up, as its screen-up vector.
	var up := Vector3.FORWARD if _elevation > PI * 0.499 else Vector3.UP
	var parent := get_parent_node_3d()
	look_at(parent.to_global(_target), parent.global_basis * up)

func _unhandled_input(event: InputEvent) -> void:
	if not _framed:
		return
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE or (
			event.button_mask & MOUSE_BUTTON_MASK_RIGHT and event.shift_pressed
		):
			_pan(event.relative)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_yaw -= event.relative.x * 0.006
			_elevation = clampf(_elevation + event.relative.y * 0.006, 0.15, 1.48)
			_update_transform()
		else:
			return
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			size = maxf(20.0, size / 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			size = minf(6000.0, size * 1.12)
		else:
			return
	elif event is InputEventPanGesture:
		_pan(event.delta * 12.0)
	elif event is InputEventMagnifyGesture:
		size = clampf(size / maxf(event.factor, 0.01), 20.0, 6000.0)
	else:
		return
	get_viewport().set_input_as_handled()

func _pan(delta: Vector2) -> void:
	var viewport_height := maxf(get_viewport().get_visible_rect().size.y, 1.0)
	var right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var up := Vector3(basis.y.x, 0.0, basis.y.z).normalized()
	_target += (-right * delta.x + up * delta.y) * size / viewport_height
	_update_transform()
