@tool
extends SubViewportContainer
## Shares the edited world; renders only dirty snapshots, at most ten per second.
## In particular a visible, idle dock must not render a second forest every frame.

var _viewport := SubViewport.new()
var _camera := Camera3D.new()
var _poll := Timer.new()
var _surface: Node3D
var _dirty := true
var _camera_state: Array = []
var render_requests := 0

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 190.0)
	stretch = true
	stretch_shrink = 2
	_viewport.size = Vector2i(360, 220)
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	_viewport.add_child(_camera)
	_camera.current = true
	_poll.wait_time = 0.1
	_poll.timeout.connect(_refresh_if_dirty)
	add_child(_poll)
	_poll.start()
	gui_input.connect(_navigate)
	visibility_changed.connect(_visibility_changed)
	resized.connect(request_refresh)
	set_process(false)

func bind_surface(surface: Node3D) -> void:
	if is_instance_valid(surface) and surface == _surface:
		return # UI synchronization must not invalidate an unchanged preview.
	_disconnect_surface()
	_surface = surface
	_camera_state.clear()
	_dirty = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if is_instance_valid(surface) and surface.is_inside_tree():
		_viewport.world_3d = surface.get_world_3d()
		if surface.has_signal("preview_state_changed"):
			surface.connect("preview_state_changed", request_refresh)
		surface.tree_exiting.connect(_surface_exiting)
	else:
		_surface = null
		_viewport.world_3d = null

func _exit_tree() -> void:
	_disconnect_surface()
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_surface = null

func _disconnect_surface() -> void:
	if not is_instance_valid(_surface):
		return
	if _surface.is_connected("preview_state_changed", request_refresh):
		_surface.disconnect("preview_state_changed", request_refresh)
	if _surface.tree_exiting.is_connected(_surface_exiting):
		_surface.tree_exiting.disconnect(_surface_exiting)

func _surface_exiting() -> void:
	bind_surface(null)

func request_refresh() -> void:
	_dirty = true

func _visibility_changed() -> void:
	if not is_visible_in_tree():
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	request_refresh()

func _preview_visible() -> bool:
	if not is_visible_in_tree():
		return false
	var rect := get_global_rect()
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			rect = rect.intersection(ancestor.get_global_rect())
			if not rect.has_area():
				return false
		ancestor = ancestor.get_parent()
	return true

func _refresh_if_dirty() -> void:
	if not is_instance_valid(_surface) or not _surface.is_inside_tree():
		bind_surface(null)
		return
	if not _preview_visible():
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var source := _surface.get_node_or_null("PreviewCamera") as Camera3D
	if source == null:
		return
	var state := [source.global_transform, source.projection, source.fov,
		source.size, source.near, source.far, source.keep_aspect, size]
	if not _dirty and state == _camera_state:
		return
	_camera_state = state
	_camera.global_transform = source.global_transform
	_camera.projection = source.projection
	_camera.fov = source.fov
	_camera.size = source.size
	_camera.near = source.near
	_camera.far = source.far
	_camera.keep_aspect = source.keep_aspect
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_dirty = false
	render_requests += 1

func _navigate(event: InputEvent) -> void:
	if not is_instance_valid(_surface):
		return
	var source := _surface.get_node_or_null("PreviewCamera")
	if source != null and source.call("navigate", event, size.y):
		_surface.call("record_camera_navigation")
		request_refresh()
		accept_event()
