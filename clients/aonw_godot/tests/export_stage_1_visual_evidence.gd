extends SceneTree

const PreviewScene := preload("res://scenes/map_preview.tscn")
const CAPTURE_SIZE := Vector2i(1280, 720)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 1:
		_fail("usage: export_stage_1_visual_evidence.gd <output-directory>")
		return
	var output_directory := arguments[0]
	var error := DirAccess.make_dir_recursive_absolute(output_directory)
	if error != OK:
		_fail("cannot create visual evidence directory: %s" % error_string(error))
		return

	root.size = CAPTURE_SIZE
	DisplayServer.window_set_size(CAPTURE_SIZE)
	var preview := PreviewScene.instantiate()
	root.add_child(preview)
	await _wait_for_rendering(12)
	var surface := preview.get_node("%MapSurface") as AonwMapSurface
	if surface == null or surface.projection() == null:
		_fail("Godot preview did not present the starter Terrain3D map")
		return
	var camera_rig := preview.get_node("OrbitCameraRig") as AonwOrbitCameraRig
	var world_size := surface.projection().world_size()
	var height_range: Vector2 = surface.terrain().data.get_height_range()
	camera_rig.frame_map(world_size, 0.82, height_range.y)
	var expected_center := Vector3(world_size.x * 0.5, 0.0, world_size.y * 0.5)
	if not camera_rig.global_position.is_equal_approx(expected_center):
		_fail("Godot preview camera is not centered over the Terrain3D map")
		return
	await _wait_for_rendering(4)

	surface.set_reference_visible(true)
	surface.set_reference_opacity(0.82)
	surface.set_grid_visible(true)
	await _wait_for_rendering(4)
	if not await _capture(
		output_directory.path_join("godot-reference-perspective.png")
	):
		return

	surface.set_reference_visible(false)
	surface.set_grid_opacity(1.0)
	var yaw := preview.get_node("OrbitCameraRig/Yaw") as Node3D
	var pitch := preview.get_node("OrbitCameraRig/Yaw/Pitch") as Node3D
	yaw.rotation.y = deg_to_rad(28.0)
	pitch.rotation.x = deg_to_rad(-68.0)
	await _wait_for_rendering(4)
	if not await _capture(output_directory.path_join("godot-terrain-grid.png")):
		return

	print("Godot stage 1 visual evidence: OK")
	preview.queue_free()
	await process_frame
	quit(0)

func _wait_for_rendering(frames: int) -> void:
	for _frame in frames:
		await process_frame

func _capture(path: String) -> bool:
	RenderingServer.force_draw(false)
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Godot returned an empty screenshot: %s" % path)
		return false
	var error := image.save_png(path)
	if error != OK:
		_fail("cannot save Godot screenshot: %s" % error_string(error))
		return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
