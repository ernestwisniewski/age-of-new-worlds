extends SceneTree
## Requires installed scans and the real Tree3D native addon; no gameplay engine.
const Library := preload("res://editor/map_authoring/presentation/reference_tree_library.gd")
const MaterialBuilder := preload("res://editor/map_authoring/presentation/reference_surface_material.gd")
const Forest := preload("res://editor/map_authoring/presentation/reference_forest.gd")
const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")

class FlatGround extends RefCounted:
	func get_height(_point: Vector3) -> float:
		return 0.0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var library := Library.load_library()
	assert(library["ok"], str(library.get("message", "")))
	assert(library["prototypes"].size() == 6)
	var candidates: Array = []
	for species in 3:
		for variant in 2:
			var prototype: Dictionary = library["prototypes"][species * 2 + variant]
			assert(prototype["parts"].size() == 2)
			assert(prototype["height"] > 0.0)
			candidates.append({"position": Vector3(8.0 + species * 10.0, 0.0, 12.0 + variant * 10.0),
				"species": species, "variant": variant, "yaw": 0.4, "scale": 1.0, "tint": Color.WHITE})
	var result := Forest.new().build(candidates, FlatGround.new(), 1.0, Parameters.defaults())
	assert(result["ok"] and result["count"] == 6)
	var forest: Node3D = result["root"]
	root.add_child(forest)
	assert(forest.owner == null, "Generated trees must not be serialized into hand-authored scenes")
	for batch in forest.get_children():
		assert(batch is MultiMeshInstance3D and batch.multimesh.use_custom_data)
		assert(batch.material_override != null)
	var ground := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	ground.fill(Color(0.4, 0.6, 0.0, 0.0))
	var detail := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	detail.fill(Color(0.0, 0.0, 0.0, 1.0))
	var reference := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	reference.fill(Color(0.3, 0.4, 0.2))
	var material := MaterialBuilder.build({"ground": ground, "detail": detail, "macro": reference},
		ImageTexture.create_from_image(reference), Vector2(48.0, 48.0), false)
	assert(material["ok"], str(material.get("message", "")))
	material["material"].set_shader_parameter("water_mask", ImageTexture.create_from_image(detail))
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(48.0, 48.0)
	plane.mesh = mesh
	plane.position = Vector3(24.0, -0.05, 24.0)
	plane.material_override = material["material"]
	root.add_child(plane)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.shadow_enabled = true
	root.add_child(sun)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(48.0, 36.0, 58.0)
	camera.look_at(Vector3(20.0, 3.0, 20.0))
	camera.current = true
	for frame in 12:
		await process_frame
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image != null and not image.is_empty())
	assert(image.save_png("res://reference-landscape-smoke.png") == OK)
	print("PASS native Tree3D prototypes, chunked forest, scanned PBR arrays and renderer smoke")
	quit(0)
