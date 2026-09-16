extends SceneTree
## Actual inherited map + native Terrain3D + Tree3D; requires installed visual assets.
const Scene := preload("res://scenes/terrain_authoring/reference_maps/dravonia.tscn")
const City := preload("res://editor/map_authoring/infrastructure/terrain/city_hex_layout.gd")
const Geometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const Space := preload("res://game/application/terrain/terrain_space_transform.gd")
const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var view = Scene.instantiate()
	root.add_child(view)
	assert(await _settle(view), "Landscape must finish loading before city checks")
	var source: AonwTerrainCompiledArtifact = view.artifact()
	var initial := _forest_hash(view)
	var tree_count: int = view.tree_count
	assert(tree_count > 0)
	var geometry_before := _heights(view, source)
	var workspace: String = view.authoring_root
	var coordinate := _find_site(view)
	assert(coordinate.x >= 0, "Dravonia must have a dry, gently sloping forest city site")
	view.set_city_marker_coordinate(coordinate)
	view.set_city_marker_visible(true)
	view.set_parameter_change({"key": "city_reserve_enabled", "value": 1.0})
	assert(await _settle(view))
	var site: Dictionary = view.city_site_layout()
	assert(site.get("ok", false), str(site.get("message", "")))
	assert(view.tree_count < tree_count, "Reserve must clear actual Tree3D instances, not just draw a ring")
	assert(view.authoring_root == workspace and _heights(view, source) == geometry_before)
	var city := view.get_node("CityHexPreview") as Node3D
	assert(city.owner == null and city.get_node_or_null("CityModelAnchor") != null)
	assert(city.get_node("FootprintGuides").visible)
	var packed := PackedScene.new()
	assert(packed.pack(view) == OK)
	var state := packed.get_state()
	for i in state.get_node_count():
		assert(not str(state.get_node_path(i)).contains("CityHexPreview"), "Derived guides are not serialized")
	view.set_reference_visible(true)
	view.set_reference_opacity(1.0)
	assert(not city.visible, "Full reference comparison must hide generated city objects")
	view.show_oblique_view()
	assert(city.visible)
	if "--capture" in OS.get_cmdline_user_args():
		var camera := view.get_node("PreviewCamera") as Camera3D
		var center: Vector3 = site["center"]
		camera.position = center + Vector3(1.6, 2.3, 2.1) * source.hex_radius_meters
		camera.look_at(center)
		for i in 8:
			await process_frame
			await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reference-captures")
		assert(root.get_texture().get_image().save_png("res://reference-captures/city-hex.png") == OK)
	view.set_parameter_change({"key": "city_reserve_enabled", "value": 0.0})
	assert(await _settle(view))
	assert(view.tree_count == tree_count and _forest_hash(view) == initial, "Disabling reservation restores the exact forest")
	view.set_parameter_change({"key": "city_reserve_enabled", "value": 1.0})
	view.set_city_marker_coordinate(Vector2i(-1, -1))
	assert(await _settle(view))
	assert(not view.city_site_layout().get("ok", false))
	assert(_forest_hash(view) == initial, "An invalid coordinate must not reserve a different tile")
	root.remove_child(view)
	view.free()
	await process_frame
	print("City hex native: PASS (actual crowns, restoration, guide, model anchor, no height/recipe writes)")
	quit(0)

func _settle(view: Node) -> bool:
	for i in 400:
		await create_timer(0.025).timeout
		if not str(view.get("preview_error")).is_empty():
			return false
		if bool(view.get("landscape_ready")):
			return true
	return false

func _find_site(view: Node) -> Vector2i:
	var source: AonwTerrainCompiledArtifact = view.call("artifact")
	var geometry := Geometry.new(source.cols, source.rows, source.hex_radius_meters)
	var space := Space.new(source)
	var values: Dictionary = view.call("parameter_values")
	values["city_reserve_enabled"] = 1.0
	var candidates: Array = view.get("_forest_candidates")
	var reconstruction: Dictionary = view.get("reconstruction")
	var inputs: Dictionary = view.get("_reference_inputs")
	var data: Object = view.call("terrain").data
	var visited := {}
	for candidate in candidates:
		var point: Vector3 = candidate["position"]
		var coordinate := geometry.tile_at_point(space.terrain_local_to_logical(point))
		if visited.has(coordinate):
			continue
		var site := City.prepare(source, coordinate, values, reconstruction["water_mask"], data, inputs["document"])
		if not site.get("ok", false):
			visited[coordinate] = true
			continue
		if City.vegetation_weight(site, point, 0.4) < 0.05:
			return coordinate
	return Vector2i(-1, -1)

func _forest_hash(view: Node) -> int:
	var snapshot := []
	for batch in view.get_node("ReferenceForest").get_children():
		snapshot.append([batch.position, batch.multimesh.buffer])
	return hash(snapshot)

func _heights(view: Node, source: AonwTerrainCompiledArtifact) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for y in range(0, source.height, 17):
		for x in range(0, source.width, 17):
			result.append(view.call("height_at", Vector2i(x, y)))
	return result
