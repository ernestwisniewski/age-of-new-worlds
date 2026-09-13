@tool
extends SubViewportContainer
## Shares the edited world; does not modify Godot's editor navigation camera.

var _viewport := SubViewport.new()
var _camera := Camera3D.new()
var _surface: Node3D

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 190.0)
	stretch = true
	_viewport.size = Vector2i(360, 220)
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	_viewport.add_child(_camera)
	_camera.current = true
	gui_input.connect(_navigate)
	set_process(true)

func bind_surface(surface: Node3D) -> void:
	_surface = surface
	if is_instance_valid(surface):
		_viewport.world_3d = surface.get_world_3d()
		_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	else:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_viewport.world_3d = null

func _process(_delta: float) -> void:
	if not is_instance_valid(_surface) or not _surface.is_inside_tree():
		if _viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED:
			bind_surface(null)
		return
	var source := _surface.get_node_or_null("PreviewCamera") as Camera3D
	if source == null:
		return
	_camera.global_transform = source.global_transform
	_camera.projection = source.projection
	_camera.fov = source.fov
	_camera.size = source.size
	_camera.near = source.near
	_camera.far = source.far

func _navigate(event: InputEvent) -> void:
	if not is_instance_valid(_surface):
		return
	var source := _surface.get_node_or_null("PreviewCamera")
	if source != null and source.call("navigate", event, size.y):
		_surface.call("record_camera_navigation")
		accept_event()
