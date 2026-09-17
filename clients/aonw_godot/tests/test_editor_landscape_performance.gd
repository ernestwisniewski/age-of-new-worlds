extends SceneTree
## Structural performance guards: no machine-specific FPS pass/fail threshold.
const Quality := preload("res://editor/map_authoring/presentation/editor_landscape_quality.gd")
const Preview := preload("res://editor/map_authoring/presentation/terrain_strategic_preview.gd")
const Normals := preload("res://editor/map_authoring/presentation/reference_mesh_normals.gd")
const Forest := preload("res://editor/map_authoring/presentation/reference_forest.gd")
const Library := preload("res://editor/map_authoring/presentation/reference_tree_library.gd")

class Surface extends Node3D:
	signal preview_state_changed

class Ground extends RefCounted:
	var calls := 0
	func get_height(point: Vector3) -> float:
		calls += 1
		return point.x * 0.03

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_normals()
	_test_buffers_and_cache()
	await _test_preview()
	print("Editor performance: PASS (on-demand viewport, bulk buffers, draw budget, cache and partial normals)")
	quit(0)

func _test_normals() -> void:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices := PackedVector3Array()
	for z in 16:
		for x in 16:
			vertices.append(Vector3(x, 0, z))
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 16, 1])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	assert(Normals.update(mesh, 16, 16) == 256)
	arrays = mesh.surface_get_arrays(0)
	vertices[5 * 16 + 5].y = 1.0
	arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	assert(Normals.update(mesh, 16, 16, Rect2i(5, 5, 1, 1)) == 9)
	var incremental: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	Normals.update(mesh, 16, 16)
	var complete: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for i in complete.size():
		assert(incremental[i].is_equal_approx(complete[i]))

func _test_buffers_and_cache() -> void:
	var shader := Shader.new()
	shader.code = "shader_type spatial; void vertex() { VERTEX.x += sin(TIME) * 0.01; } void fragment() { ALBEDO = vec3(0.2, 0.6, 0.1); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	var mesh := BoxMesh.new()
	var prototype := {"height": 4.0, "base_y": -0.5, "parts": [
		{"mesh": mesh, "transform": Transform3D(Basis.IDENTITY, Vector3(0.5, 0.4, 0.1)), "material": material},
		{"mesh": mesh, "transform": Transform3D.IDENTITY, "material": material}]}
	var old_library := Library._prototypes
	Library._prototypes = {0: prototype}
	var candidates: Array = []
	for i in 100:
		candidates.append({"position": Vector3(5 + i * 3, 0, 8), "species": 0, "variant": 0,
			"yaw": 0.3, "scale": 0.8, "tint": Color(0.7, 0.8, 0.9, 1), "priority": float((i * 37) % 101)})
	var packed := Forest.instance_buffer(candidates, prototype, prototype["parts"][0], Vector3(4, 0, 0), 2.0)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	multi.mesh = mesh
	multi.instance_count = candidates.size()
	multi.buffer = packed
	var p: Vector3 = candidates[0]["position"] - Vector3(4, 0, 0)
	p.y += 0.2
	var expected: Transform3D = Transform3D(Basis(Vector3.UP, 0.3).scaled(Vector3.ONE * 0.4), p) * prototype["parts"][0]["transform"]
	assert(is_equal_approx(packed[3], expected.origin.x) and is_equal_approx(packed[7], expected.origin.y))
	if DisplayServer.get_name() != "headless":
		assert(multi.get_instance_transform(0).is_equal_approx(expected), "Buffer must preserve rotation, offset and scale")
		var actual := multi.get_instance_custom_data(0)
		var wanted: Color = candidates[0]["tint"]
		# Compatibility stores custom data at half-float precision.
		for component in 4:
			assert(absf(actual[component] - wanted[component]) < 0.001)
	var renderer := Forest.new()
	var data := Ground.new()
	var settings := {"tree_height": 2.0, "tree_max_slope": 38.0, "tree_draw_distance": 3000.0}
	var result := renderer.build(candidates, data, 1.0, settings)
	assert(result["ok"] and result["count"] == 100)
	assert(data.calls == 500)
	var forest: Node3D = result["root"]
	var buffers: Array = []
	for batch in forest.get_children():
		buffers.append(batch.multimesh.buffer)
	assert(Quality.apply_forest(forest, true, 17) == 17)
	var drawn := 0
	for group in forest.get_meta("forest_groups"):
		drawn += group["nodes"][0].multimesh.visible_instance_count
		for batch in group["nodes"]:
			assert(batch.multimesh.visible_instance_count == group["nodes"][0].multimesh.visible_instance_count)
			assert(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
			assert(not batch.material_override.shader.code.contains("TIME"))
	assert(drawn == 17)
	assert(shader.code.contains("TIME"), "Shared full-quality shader must stay untouched")
	assert(Quality.apply_forest(forest, false, 17) == 100)
	for i in forest.get_child_count():
		var batch := forest.get_child(i) as MultiMeshInstance3D
		assert(batch.multimesh.visible_instance_count == -1)
		assert(batch.multimesh.buffer == buffers[i])
		assert(batch.material_override == material)
	forest.free()
	data.calls = 0
	result = renderer.build(candidates, data, 1.0, settings)
	assert(data.calls == 0, "City/display rebuilds must reuse unchanged native samples")
	result["root"].free()
	renderer.invalidate_ground(Rect2i(5, 8, 1, 1), 1.0)
	result = renderer.build(candidates, data, 1.0, settings)
	assert(data.calls == 5, "Local brush must not resample the entire forest")
	result["root"].free()
	Library._prototypes = old_library

func _test_preview() -> void:
	var surface := Surface.new()
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	surface.add_child(camera)
	root.add_child(surface)
	var preview := Preview.new()
	preview.size = Vector2(360, 220)
	root.add_child(preview)
	preview._poll.stop() # Drive ticks deterministically; production uses 10 Hz.
	preview.bind_surface(surface)
	await process_frame
	preview._refresh_if_dirty()
	var first: int = preview.render_requests
	assert(first == 1)
	for i in 120:
		preview.bind_surface(surface)
		preview._refresh_if_dirty()
	assert(preview.render_requests == first, "Idle/same-surface synchronization must not redraw")
	assert(not preview.is_processing())
	surface.preview_state_changed.emit()
	preview._refresh_if_dirty()
	assert(preview.render_requests == first + 1)
	camera.position.x = 2.0
	preview._refresh_if_dirty()
	assert(preview.render_requests == first + 2)
	preview.hide()
	surface.preview_state_changed.emit()
	preview._refresh_if_dirty()
	assert(preview.render_requests == first + 2)
	assert(preview._viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED)
	preview.show()
	preview._refresh_if_dirty()
	assert(preview.render_requests == first + 3)
	surface.free()
	preview._refresh_if_dirty()
	assert(preview._viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED)
	preview.free()
