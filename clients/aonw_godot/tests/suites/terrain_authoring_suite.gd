extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const AuthoringStore := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_authoring_store.gd"
)
const CompositionRoot := preload(
	"res://editor/map_authoring/composition/map_authoring_composition_root.gd"
)
const MapAssetCatalog := preload(
	"res://editor/map_authoring/infrastructure/map_asset_catalog.gd"
)
const TerrainSpaceTransform := preload(
	"res://game/application/terrain/terrain_space_transform.gd"
)
const AuthoringSession := preload(
	"res://editor/map_authoring/application/terrain_authoring_session.gd"
)
const MemoryPersistence := preload(
	"res://tests/doubles/memory_terrain_authoring_persistence.gd"
)
const MapWorkbenchView := preload(
	"res://editor/map_authoring/presentation/map_workbench_view.gd"
)
const GeneratedDecorationPlanRepository := preload(
	"res://editor/map_authoring/infrastructure/generated_decoration_plan_repository.gd"
)

var _failures: Array[String]
var _test_root: String
var _camera: Camera3D
var _composition: AonwMapAuthoringCompositionRoot

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_root = "res://.godot/terrain_authoring_test/%s" % OS.get_process_id()
	_composition = CompositionRoot.new(
		_test_root.path_join("scenes"),
		_test_root.path_join("assets"),
		"res://.godot/terrain_compiled",
	)
	_camera = Camera3D.new()
	_camera.position = Vector3(40.0, 100.0, 40.0)
	Engine.get_main_loop().root.add_child(_camera)
	_camera.current = true
	await _test_workbench_sections_are_scrollable()
	await _test_every_content_map_opens_its_own_terrain()
	_test_authoring_scene_is_isolated_from_runtime_preview()
	var generation := _generate_scene()
	_check(generation["ok"], "Terrain3D authoring scene is generated")
	if generation["ok"]:
		await _test_authoring_session(generation["scene_path"])
	_camera.free()

func _test_workbench_sections_are_scrollable() -> void:
	var view := MapWorkbenchView.new()
	view._build_interface()
	Engine.get_main_loop().root.add_child(view)
	await Engine.get_main_loop().process_frame
	_check(view._sections.get_tab_count() == 3, "map workbench separates its three workflows")
	var tab_names: Array[String] = []
	var all_scrollable := true
	for child in view._sections.get_children():
		tab_names.append(child.name)
		all_scrollable = all_scrollable and child is ScrollContainer
	_check(
		all_scrollable
		and tab_names == ["New Map", "Logical Map", "Terrain3D"],
		"New Map, Logical Map and Terrain3D use independent scrollable sections",
	)
	view.queue_free()
	await Engine.get_main_loop().process_frame

func _test_every_content_map_opens_its_own_terrain() -> void:
	var composition := CompositionRoot.new(
		_test_root.path_join("all_maps/scenes"),
		_test_root.path_join("all_maps/assets"),
		"res://.godot/terrain_compiled",
	)
	var opened: Array[String] = []
	var content_map_count := 0
	for source in MapAssetCatalog.new().discover():
		if source.origin != "content":
			continue
		content_map_count += 1
		var generated := composition.generator().execute(source)
		_check(generated["ok"], "%s Terrain3D scene can be prepared" % source.map_id)
		if not generated["ok"]:
			continue
		var packed := ResourceLoader.load(
			generated["scene_path"],
			"PackedScene",
			ResourceLoader.CACHE_MODE_REPLACE_DEEP,
		) as PackedScene
		_check(packed != null, "%s Terrain3D scene can be loaded" % source.map_id)
		if packed == null:
			continue
		var root := packed.instantiate()
		var surface := root.find_child(
			"TerrainAuthoring", true, false
		) as AonwTerrainAuthoringSurface
		_check(surface != null, "%s has a Terrain3D authoring surface" % source.map_id)
		if surface == null:
			root.free()
			continue
		Engine.get_main_loop().root.add_child(root)
		surface.terrain().set_camera(_camera)
		var result: Dictionary = await composition.open_surface(surface)
		_check(
			result["ok"]
			and surface.source_map_id == source.map_id
			and surface.artifact().map_id == source.map_id,
			"%s opens only its own logical map and Terrain3D artifact" % source.map_id,
		)
		if result["ok"]:
			_check(
				surface.has_reference_texture()
				and surface.get_node("ReferenceTexture").mesh is ArrayMesh,
				"%s exposes its old-client texture as the editor reference" % source.map_id,
			)
			surface.reference_visible = false
			_check(
				not surface.get_node("ReferenceTexture").visible,
				"%s reference can be hidden directly from the Inspector" % source.map_id,
			)
			surface.reference_visible = true
			_check(
				surface.get_node("ReferenceTexture").visible,
				"%s reference can be shown directly from the Inspector" % source.map_id,
			)
			opened.append(source.map_id)
		root.queue_free()
		await Engine.get_main_loop().process_frame
	_check(
		content_map_count >= 5 and opened.size() == content_map_count,
		"every canonical map opens for Terrain3D authoring",
	)

func _test_authoring_scene_is_isolated_from_runtime_preview() -> void:
	var runtime_root := _test_root.path_join("runtime_scenes")
	var authoring_root := _test_root.path_join("isolated_authoring_scenes")
	var isolated_composition := CompositionRoot.new(
		authoring_root,
		_test_root.path_join("isolated_assets"),
		"res://.godot/terrain_compiled",
	)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(runtime_root))
	var root := Node3D.new()
	root.name = "aonw2_starter"
	var preview := Node3D.new()
	preview.name = "AonwMap3D"
	root.add_child(preview)
	preview.owner = root
	var legacy_scene := PackedScene.new()
	var error := legacy_scene.pack(root)
	if error == OK:
		error = ResourceSaver.save(
			legacy_scene,
			runtime_root.path_join("aonw2_starter.tscn"),
		)
	root.free()
	_check(error == OK, "runtime preview scene fixture can be saved")
	if error != OK:
		return
	var result := isolated_composition.generator().execute(_starter_source())
	_check(
		result["ok"] and result["scene_path"].begins_with(authoring_root),
		"Terrain3D authoring uses a dedicated scene directory",
	)
	if not result["ok"]:
		return
	var authored := ResourceLoader.load(
		result["scene_path"],
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	_check(authored != null, "isolated Terrain3D authoring scene can be loaded")
	if authored == null:
		return
	var authored_root := authored.instantiate()
	_check(
		authored_root.find_child("AonwMap3D", true, false) == null,
		"Terrain3D authoring scene contains no runtime preview artifacts",
	)
	_check(
		authored_root.find_child("TerrainAuthoring", true, false) != null,
		"isolated scene contains the Terrain3D authoring surface",
	)
	authored_root.free()
	var runtime_scene := ResourceLoader.load(
		runtime_root.path_join("aonw2_starter.tscn"),
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	_check(runtime_scene != null, "runtime preview scene remains readable")
	if runtime_scene != null:
		var runtime_root_node := runtime_scene.instantiate()
		_check(
			runtime_root_node.get_node_or_null("AonwMap3D") != null,
			"runtime preview scene remains unchanged",
		)
		runtime_root_node.free()

func _generate_scene() -> Dictionary:
	var source := _starter_source()
	var generator := _composition.generator()
	var result := generator.execute(source)
	if result["ok"]:
		_check(result["scene_created"], "Terrain3D authoring scene is created once")
		_add_authored_child(result["scene_path"])
		var regenerated := generator.execute(source)
		_check(
			regenerated["ok"] and not regenerated["scene_created"],
			"regeneration preserves the existing authored scene",
		)
		_check(
			_scene_has_authored_child(result["scene_path"]),
			"regeneration preserves manually authored children",
		)
		_check(
			not FileAccess.file_exists(
				_test_root.path_join("assets/aonw2_starter/terrain_authoring/reference_texture.res")
			),
			"reference texture is rebuilt from the canonical map bundle instead of persisted",
		)
	return result

func _starter_source() -> AonwMapSource:
	return MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	)

func _add_authored_child(scene_path: String) -> void:
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	_check(packed != null, "generated authoring scene can be loaded for manual editing")
	if packed == null:
		return
	var root := packed.instantiate()
	var authored := Node3D.new()
	authored.name = "AuthoredLandmark"
	root.add_child(authored)
	authored.owner = root
	var updated := PackedScene.new()
	var error := updated.pack(root)
	if error == OK:
		error = ResourceSaver.save(updated, scene_path)
	_check(error == OK, "manual authored child can be saved")
	root.free()

func _scene_has_authored_child(scene_path: String) -> bool:
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate()
	var found := root.find_child("AuthoredLandmark", true, false) != null
	root.free()
	return found

func _test_authoring_session(scene_path: String) -> void:
	var opened := await _open_surface(scene_path)
	_check(opened["ok"], "Terrain3D authoring session opens")
	if not opened["ok"]:
		return
	var root: Node = opened["root"]
	var surface: AonwTerrainAuthoringSurface = opened["surface"]
	var artifact := surface.artifact()
	await _test_persistence_port(artifact)
	_test_generated_decoration_repository(artifact)
	_check(surface.terrain() is Terrain3D, "authoring backend is Terrain3D")
	_check(
		surface.generated_world().name == "GeneratedWorld"
		and surface.manual_world().name == "ManualWorld"
		and surface.generated_world() != surface.manual_world(),
		"generated and manual world objects have separate scene lifecycles",
	)
	_check_approx(
		float(artifact.max_city_slope),
		0.35,
		"compiled maxCitySlope is retained as reserved authoring metadata",
	)
	_check_approx(
		artifact.max_terrain_height_meters,
		20.0,
		"compiled terrain retains the map-specific maximum height",
	)
	_check(
		surface.find_child("BaseTerrain", true, false) == null,
		"authoring scene has no alternative mesh terrain backend",
	)
	_check(
		surface.map_content_hash == artifact.map_content_hash
		and surface.authoring_profile_hash == artifact.authoring_profile_hash
		and surface.generated_base_hash == artifact.generated_base_hash,
		"authoring scene exposes exact compiled metadata",
	)

	var sample := Vector2i(20, 20)
	_check_approx(
		surface.height_at(sample),
		artifact.base_image.get_pixelv(sample).r,
		"Terrain3D imports the generated base raster",
	)
	_test_logical_map_cursor(surface, artifact)
	_test_generated_world_lifecycle(surface, artifact)
	_test_overlay_alignment(surface, artifact)
	_check(
		surface.get_node_or_null("MinimumHeightDebug") == null
		and surface.get_node_or_null("MaximumHeightDebug") == null,
		"hidden constraint overlays do not leave invalid empty MeshInstance3D nodes",
	)
	_test_overlay_controls(surface, artifact)
	await _test_incremental_overlay_refresh(surface, artifact)
	_test_regional_clamp_and_publish(surface, artifact)
	_test_undo_redo(surface, artifact)

	var manual_pixel := Vector2i(30, 30)
	var manual_height := artifact.maximum_at(manual_pixel) - 0.25
	surface.set_height(manual_pixel, manual_height)
	var revision_before_save := surface.terrain_revision
	var save_result := surface.save_draft()
	_check(
		save_result["ok"],
		"manual Terrain3D final is saved as a draft: %s" % save_result.get("message", ""),
	)
	var refresh_result := surface.refresh_generated_artifact()
	_check(
		refresh_result["ok"] and refresh_result["manual_final_preserved"],
		"generated base refresh explicitly preserves manual final terrain",
	)
	_check_approx(
		surface.height_at(manual_pixel),
		manual_height,
		"generated base refresh does not overwrite manual sculpting",
	)
	var publish_result := surface.publish()
	_check(
		publish_result["ok"],
		"valid Terrain3D final is published: %s" % publish_result.get("message", ""),
	)
	if publish_result["ok"]:
		_test_publish_manifest(publish_result["manifest_path"], surface)
		_test_artifact_identity(surface, artifact)
		var published_files := _directory_hashes(publish_result["data_directory"])
		var published_pointer_hash := FileAccess.get_sha256(publish_result["manifest_path"])
		manual_height = artifact.maximum_at(manual_pixel) - 0.75
		surface.set_height(manual_pixel, manual_height)
		revision_before_save = surface.terrain_revision
		var next_draft := surface.save_draft()
		_check(next_draft["ok"], "a newer Terrain3D draft can be saved after publish")
		if next_draft["ok"]:
			_check(
				next_draft["data_directory"] != publish_result["data_directory"],
				"draft and published terrain use separate immutable snapshots",
			)
			_check(
				_directory_hashes(publish_result["data_directory"]) == published_files,
				"saving revision N+1 leaves published revision N byte-for-byte unchanged",
			)
			_check(
				FileAccess.get_sha256(publish_result["manifest_path"])
				== published_pointer_hash,
				"saving a draft does not move the published terrain pointer",
			)
			_test_snapshot_integrity(surface, artifact, next_draft["data_directory"])
	surface.invalidate_reference_texture()
	surface.refresh_overlays()
	_check(
		not surface.has_reference_texture()
		and surface.get_node("ReferenceTexture").mesh == null
		and surface.get_node("HexGrid").mesh is ArrayMesh,
		"a stale reference can be disabled without disabling Terrain3D or the logical grid",
	)
	root.queue_free()
	await Engine.get_main_loop().process_frame

	var reopened := await _open_surface(scene_path)
	_check(reopened["ok"], "saved Terrain3D authoring session reopens")
	if reopened["ok"]:
		var reopened_surface: AonwTerrainAuthoringSurface = reopened["surface"]
		_check_approx(
			reopened_surface.height_at(manual_pixel),
			manual_height,
			"manual sculpting survives close and reopen",
		)
		_check(
			reopened_surface.terrain_revision == revision_before_save,
			"terrainRevision survives close and reopen",
		)
		reopened["root"].queue_free()
		await Engine.get_main_loop().process_frame

func _test_logical_map_cursor(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var geometry := AonwHexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	var space := TerrainSpaceTransform.new(artifact)
	var coordinate := Vector2i(2, 3)
	var local := space.logical_to_terrain_local(geometry.tile_center(coordinate))
	_check(
		surface.logical_hex_at_local_position(local) == coordinate,
		"logical authoring maps a Terrain3D position to the selected odd-q hex",
	)
	_check(
		surface.logical_hex_at_local_position(Vector3(-10000.0, 0.0, -10000.0))
		== AonwTerrainAuthoringSurface.INVALID_HEX,
		"logical authoring rejects a Terrain3D position outside the map",
	)
	surface.set_logical_paint_active(true)
	surface.set_logical_paint_cursor(coordinate)
	var cursor := surface.get_node("LogicalMapCursor") as MeshInstance3D
	_check(
		cursor.visible and cursor.mesh is ArrayMesh,
		"logical authoring displays a terrain-following hex cursor",
	)
	surface.set_logical_paint_active(false)
	_check(not cursor.visible and cursor.mesh == null, "Terrain3D mode clears the logical cursor")

func _test_generated_world_lifecycle(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var manual_landmark := Node3D.new()
	manual_landmark.name = "ManualLifecycleLandmark"
	surface.manual_world().add_child(manual_landmark)
	var terrain_sample := Vector2i(20, 20)
	var terrain_height := surface.height_at(terrain_sample)
	var geometry := AonwHexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	var tree_center := geometry.tile_center(Vector2i(2, 2))
	var rock_center := geometry.tile_center(Vector2i(3, 2))
	surface.present_generated_decorations([
		_decoration_fixture("tree_2_2_0", "tree", Vector2i(2, 2), tree_center),
		_decoration_fixture("rock_3_2_0", "rock", Vector2i(3, 2), rock_center),
	])
	_check(
		surface.generated_world().get_child_count() == 2
		and surface.generated_world().get_child(0) is MultiMeshInstance3D,
		"generated decoration plan builds batched 3D world objects",
	)
	var water_center := geometry.tile_center(Vector2i(1, 1))
	surface.present_generated_decorations([
		_decoration_fixture("water_1_1_0", "water", Vector2i(1, 1), water_center),
	])
	_check(
		surface.generated_world().get_child_count() == 1
		and surface.manual_world().get_node_or_null("ManualLifecycleLandmark") == manual_landmark
		and is_equal_approx(surface.height_at(terrain_sample), terrain_height),
		"refreshing GeneratedWorld never replaces ManualWorld",
	)
	surface.clear_generated_decorations()
	_check(
		surface.generated_world().get_child_count() == 0
		and surface.manual_world().get_node_or_null("ManualLifecycleLandmark") == manual_landmark
		and is_equal_approx(surface.height_at(terrain_sample), terrain_height),
		"clearing stale generated objects preserves manual authoring and Terrain3D",
	)
	manual_landmark.free()

func _test_generated_decoration_repository(
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var plan_root := _test_root.path_join("generated_plan")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(plan_root))
	var source := MapSource.new(
		artifact.map_id,
		plan_root.path_join("map.json"),
		"",
		"content",
	)
	var plan := {
		"sourceMapContentHash": artifact.map_content_hash,
		"generationSpecHash": "0".repeat(64),
		"generatorId": "continental",
		"generatorVersion": 1,
		"seed": "42",
		"placements": [
			_decoration_fixture("tree_0_0_0", "tree", Vector2i.ZERO, Vector2.ZERO),
		],
	}
	var plan_path := plan_root.path_join("generated_decorations.json")
	var file := FileAccess.open(plan_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(plan))
	file = null
	var repository := GeneratedDecorationPlanRepository.new()
	var loaded := repository.load_plan(source, artifact)
	_check(
		loaded["ok"] and loaded["placements"].size() == 1,
		"generated decoration adapter accepts a plan bound to the current map artifact: %s"
		% loaded.get("message", ""),
	)
	plan["sourceMapContentHash"] = "f".repeat(64)
	file = FileAccess.open(plan_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(plan))
	file = null
	_check(
		not repository.load_plan(source, artifact)["ok"],
		"generated decoration adapter rejects a stale map identity",
	)

func _decoration_fixture(
	identifier: String,
	kind: String,
	coordinate: Vector2i,
	logical_position: Vector2,
) -> Dictionary:
	return {
		"placementId": identifier,
		"kind": kind,
		"sourceCol": coordinate.x,
		"sourceRow": coordinate.y,
		"xMeters": logical_position.x,
		"yMeters": 0.0,
		"zMeters": logical_position.y,
		"rotationDegreesY": 0.0,
		"scale": 1.0,
	}

func _test_persistence_port(artifact: AonwTerrainCompiledArtifact) -> void:
	var terrain := Terrain3D.new()
	Engine.get_main_loop().root.add_child(terrain)
	await Engine.get_main_loop().process_frame
	terrain.vertex_spacing = artifact.sample_spacing_meters
	var persistence := MemoryPersistence.new()
	var session := AuthoringSession.new(terrain.data, artifact, persistence)
	var open_result := session.open()
	_check(open_result["ok"], "authoring session opens through its persistence port")
	if open_result["ok"]:
		_check(
			persistence.load_count == 1
			and persistence.last_identity.to_dictionary()
			== artifact.identity().to_dictionary(),
			"authoring session loads state through the injected persistence port",
		)
		_check(session.save_draft()["ok"], "authoring session saves through its port")
		_check(session.publish()["ok"], "authoring session publishes through its port")
		_check(
			persistence.draft_count == 1
			and persistence.publish_count == 1
			and persistence.last_artifact == artifact
			and persistence.last_revision == session.terrain_revision(),
			"persistence adapter receives the current artifact and revision",
		)
		var sample := _scaled_height_sample(artifact)
		_check(sample.x >= 0, "compiled terrain has a raised sample for height rescaling")
		if sample.x < 0:
			terrain.queue_free()
			await Engine.get_main_loop().process_frame
			return
		var manual_height := minf(
			artifact.base_image.get_pixelv(sample).r + 0.25,
			artifact.maximum_at(sample),
		)
		session.set_height(sample, manual_height)
		var previous_height := session.height_at(sample)
		var previous_revision := session.terrain_revision()
		var scaled_artifact := _scaled_height_artifact(artifact, 1.5)
		var expected_height := scaled_artifact.clamp_height(
			sample,
			scaled_artifact.base_image.get_pixelv(sample).r
			+ previous_height - artifact.base_image.get_pixelv(sample).r,
		)
		var rescale := session.rescale_generated_artifact(scaled_artifact)
		_check(
			rescale["ok"]
			and rescale["manual_delta_preserved"]
			and session.artifact() == scaled_artifact,
			"map height scale replaces the compiled artifact through Terrain3D",
		)
		_check_approx(
			session.height_at(sample),
			expected_height,
			"map height scale preserves the manual sculpting delta",
		)
		_check(
			session.terrain_revision() == previous_revision + 1,
			"map height scale records one terrain revision for the complete raster",
		)
		previous_height = session.height_at(sample)
		var next_artifact := _artifact_for_logical_revision(scaled_artifact)
		var refresh := session.refresh_logical_map_artifact(next_artifact)
		_check(
			refresh["ok"]
			and refresh["manual_final_preserved"]
			and session.artifact() == next_artifact,
			"logical map refresh accepts only a matching Terrain3D raster",
		)
		_check_approx(
			session.height_at(sample),
			previous_height,
			"logical map refresh preserves manual Terrain3D heights",
		)
	terrain.queue_free()
	await Engine.get_main_loop().process_frame

func _scaled_height_sample(artifact: AonwTerrainCompiledArtifact) -> Vector2i:
	for y in artifact.height:
		for x in artifact.width:
			var pixel := Vector2i(x, y)
			var base := artifact.base_image.get_pixelv(pixel).r
			if base > 0.01 and artifact.maximum_at(pixel) - base > 0.25:
				return pixel
	return Vector2i(-1, -1)

func _scaled_height_artifact(
	artifact: AonwTerrainCompiledArtifact,
	scale: float,
) -> AonwTerrainCompiledArtifact:
	var result := AonwTerrainCompiledArtifact.new()
	for field in [
		"directory", "map_id", "map_content_hash", "authoring_profile_hash",
		"generated_base_hash", "generator_version", "width", "height",
		"sample_spacing_meters", "world_min_meters", "world_origin_meters", "cols",
		"rows", "hex_radius_meters", "max_terrain_height_meters",
		"reference_translation_meters", "reference_rotation_degrees", "reference_scale",
		"city_core_radius_meters", "max_city_slope",
	]:
		result.set(field, artifact.get(field))
	result.authoring_profile_hash = "d".repeat(64)
	result.generated_base_hash = "e".repeat(64)
	result.max_terrain_height_meters *= scale
	result.base_image = _scaled_height_image(artifact.base_image, scale)
	result.minimum_image = _scaled_height_image(artifact.minimum_image, scale)
	result.maximum_image = _scaled_height_image(artifact.maximum_image, scale)
	return result

func _scaled_height_image(source: Image, scale: float) -> Image:
	var result: Image = source.duplicate()
	for y in result.get_height():
		for x in result.get_width():
			var value: float = result.get_pixel(x, y).r * scale
			result.set_pixel(x, y, Color(value, 0.0, 0.0, 1.0))
	return result

func _artifact_for_logical_revision(
	artifact: AonwTerrainCompiledArtifact,
) -> AonwTerrainCompiledArtifact:
	var result := AonwTerrainCompiledArtifact.new()
	for field in [
		"directory", "map_id", "map_content_hash", "authoring_profile_hash",
		"generated_base_hash", "generator_version", "width", "height",
		"sample_spacing_meters", "world_min_meters", "world_origin_meters", "cols",
		"rows", "hex_radius_meters", "max_terrain_height_meters",
		"reference_translation_meters", "reference_rotation_degrees", "reference_scale",
		"city_core_radius_meters", "max_city_slope", "base_image", "minimum_image",
		"maximum_image",
	]:
		result.set(field, artifact.get(field))
	result.map_content_hash = "a".repeat(64)
	result.authoring_profile_hash = "b".repeat(64)
	result.generated_base_hash = "c".repeat(64)
	return result

func _test_regional_clamp_and_publish(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var space := TerrainSpaceTransform.new(artifact)
	var first := Vector2i(10, 10)
	var second := Vector2i(20, 10)
	surface.terrain().data.set_height(
		space.raster_pixel_to_terrain_local(first),
		artifact.maximum_at(first) + 50.0,
	)
	surface.terrain().data.set_height(
		space.raster_pixel_to_terrain_local(second),
		artifact.maximum_at(second) + 50.0,
	)
	var revision_before_edit := surface.terrain_revision
	surface.terrain().data.maps_edited.emit(AABB(
		space.raster_pixel_to_terrain_local(first),
		Vector3(
			artifact.sample_spacing_meters,
			1.0,
			artifact.sample_spacing_meters,
		),
	))
	_check(
		surface.terrain_revision > revision_before_edit,
		"Terrain3D maps_edited triggers the regional authoring transaction",
	)
	_check_approx(
		surface.height_at(first),
		artifact.maximum_at(first),
		"regional clamp enforces the local maximum",
	)
	_check(
		surface.height_at(second) > artifact.maximum_at(second),
		"regional clamp does not scan or mutate an untouched pixel",
	)
	var blocked := surface.publish()
	_check(
		not blocked["ok"] and blocked.has("validation"),
		"independent full validator blocks an invalid publish",
	)
	surface.clamp_changed_region(Rect2i(second, Vector2i.ONE))
	_check(surface.validate_for_publish()["ok"], "full validator accepts the clamped terrain")

func _test_undo_redo(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var pixel := Vector2i(25, 25)
	var previous := surface.height_at(pixel)
	var requested := artifact.maximum_at(pixel) - 0.5
	var history := UndoRedo.new()
	_check(
		surface.change_height(history, pixel, requested),
		"Terrain3D height edit records an undoable action",
	)
	_check_approx(surface.height_at(pixel), requested, "Terrain3D edit is applied")
	history.undo()
	_check_approx(surface.height_at(pixel), previous, "Terrain3D edit is undone")
	history.redo()
	_check_approx(surface.height_at(pixel), requested, "Terrain3D edit is redone")
	history.clear_history(false)
	history.free()

func _test_overlay_controls(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	_check(
		surface.terrain().material.world_background
		== Terrain3DMaterial.WorldBackground.NONE,
		"authoring renders no Terrain3D world background outside the map",
	)
	surface.set_reference_visible(false)
	_check(not surface.get_node("ReferenceTexture").visible, "reference can be hidden")
	surface.set_reference_visible(true)
	surface.set_reference_opacity(0.4)
	var reference_material := (
		surface.get_node("ReferenceTexture").mesh.surface_get_material(0)
		as StandardMaterial3D
	)
	_check_approx(reference_material.albedo_color.a, 0.4, "reference opacity is editable")
	surface.set_grid_visible(false)
	_check(not surface.get_node("HexGrid").visible, "debug grid can be hidden")
	surface.set_grid_visible(true)
	var grid := surface.get_node("HexGrid") as MeshInstance3D
	var grid_material := grid.mesh.surface_get_material(0) as StandardMaterial3D
	_check(
		grid_material.albedo_color.r <= 0.01
		and grid_material.albedo_color.g <= 0.01
		and grid_material.albedo_color.b <= 0.01,
		"hex grid uses the requested black authoring color",
	)
	var grid_vertices: PackedVector3Array = grid.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var finite_grid := true
	for vertex in grid_vertices:
		finite_grid = finite_grid and vertex.is_finite()
	_check(finite_grid, "hex grid keeps finite boundary geometry")
	surface.set_constraints_visible(true)
	_check(
		surface.get_node("MinimumHeightDebug").visible
		and surface.get_node("MaximumHeightDebug").visible,
		"min and max debug envelopes can be shown",
	)
	var marker := surface.get_node("CityCoreMarker")
	_check(marker.mesh is CylinderMesh, "city-core scale marker is visible geometry")
	_check(
		marker.mesh.top_radius <= artifact.hex_radius_meters,
		"city-core marker fits within one authoring hex",
	)

func _test_overlay_alignment(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var pixel := Vector2i(artifact.width / 2, artifact.height / 2)
	var index := pixel.y * artifact.width + pixel.x
	var reference := surface.get_node("ReferenceTexture") as MeshInstance3D
	var reference_arrays := reference.mesh.surface_get_arrays(0)
	var reference_vertex: Vector3 = reference_arrays[Mesh.ARRAY_VERTEX][index]
	var transformed := reference.transform * reference_vertex
	_check(
		absf(
			transformed.y
			- surface.terrain().data.get_height(Vector3(transformed.x, 0.0, transformed.z))
		) <= 0.08,
		"reference mesh follows Terrain3D within overlay tolerance",
	)

	var grid := surface.get_node("HexGrid") as MeshInstance3D
	var grid_vertices: PackedVector3Array = grid.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var aligned_grid_vertex := false
	for vertex in grid_vertices:
		var terrain_height := surface.terrain().data.get_height(Vector3(vertex.x, 0.0, vertex.z))
		if not is_finite(terrain_height):
			continue
		if absf(vertex.y - terrain_height) <= 0.2:
			aligned_grid_vertex = true
			break
	_check(aligned_grid_vertex, "debug grid follows Terrain3D within overlay tolerance")

func _test_incremental_overlay_refresh(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var reference := surface.get_node("ReferenceTexture") as MeshInstance3D
	var grid := surface.get_node("HexGrid") as MeshInstance3D
	var minimum := surface.get_node("MinimumHeightDebug") as MeshInstance3D
	var maximum := surface.get_node("MaximumHeightDebug") as MeshInstance3D
	var marker := surface.get_node("CityCoreMarker") as MeshInstance3D
	var reference_mesh := reference.mesh
	var grid_mesh := grid.mesh
	var minimum_mesh := minimum.mesh
	var maximum_mesh := maximum.mesh
	var marker_mesh := marker.mesh
	var pixel := Vector2i(5, 5)
	var next_height := artifact.clamp_height(pixel, surface.height_at(pixel) + 0.5)
	var started_at := Time.get_ticks_usec()
	surface.set_height(pixel, next_height)
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	var elapsed_micros := Time.get_ticks_usec() - started_at
	_check(
		reference.mesh == reference_mesh and grid.mesh == grid_mesh,
		"terrain edits reuse reference and grid mesh topology",
	)
	_check(
		minimum.mesh == minimum_mesh and maximum.mesh == maximum_mesh,
		"terrain edits do not rebuild static constraint overlays",
	)
	_check(marker.mesh == marker_mesh, "distant terrain edits do not rebuild the city marker")
	var space := TerrainSpaceTransform.new(artifact)
	var marker_pixel := space.terrain_local_to_raster_pixel(marker.position)
	marker_mesh = marker.mesh
	surface.set_height(
		marker_pixel,
		artifact.clamp_height(marker_pixel, surface.height_at(marker_pixel) + 0.25),
	)
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	_check(marker.mesh != marker_mesh, "a terrain edit below the city marker refreshes it")
	_check(
		elapsed_micros < 250_000,
		"one incremental Terrain3D stroke stays within the headless smoke budget",
	)

func _test_publish_manifest(path: String, surface: AonwTerrainAuthoringSurface) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "published terrain manifest exists")
	if file == null:
		return
	var manifest: Dictionary = JSON.parse_string(file.get_as_text())
	_check(
		manifest["mapContentHash"] == surface.map_content_hash
		and manifest["authoringProfileHash"] == surface.authoring_profile_hash
		and manifest["generatedBaseHash"] == surface.generated_base_hash
		and int(manifest["rasterWidth"]) == surface.artifact().width
		and int(manifest["rasterHeight"]) == surface.artifact().height
		and is_equal_approx(
			float(manifest["sampleSpacingMeters"]),
			surface.artifact().sample_spacing_meters,
		)
		and int(manifest["terrainRevision"]) == surface.terrain_revision,
		"published terrain records all required identities and terrainRevision",
	)
	_check(
		str(manifest["terrainDataDirectory"]).contains("/published/"),
		"published pointer targets a dedicated immutable snapshot",
	)

func _test_artifact_identity(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var store := AuthoringStore.new(surface.authoring_root)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "generatedBaseHash", "0".repeat(64)),
		"requiresConstraintRefresh",
	)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "authoringProfileHash", "1".repeat(64)),
		"requiresConstraintRefresh",
	)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "generatorVersion", "future-generator/1"),
		"unsupportedGenerator",
	)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "rasterWidth", artifact.width + 1),
		"requiresMigration",
	)
	_assert_compatibility(
		store,
		_with_identity(artifact.identity(), "mapContentHash", "f".repeat(64)),
		"belongsToDifferentMap",
	)

func _assert_compatibility(
	store: AonwTerrainAuthoringStore,
	identity: AonwTerrainArtifactIdentity,
	expected: String,
) -> void:
	var result := store.load_revision(identity)
	_check(
		not result["ok"] and result.get("compatibility") == expected,
		"saved terrain reports explicit compatibility outcome: %s" % expected,
	)

func _with_identity(
	identity: AonwTerrainArtifactIdentity,
	field: String,
	value: Variant,
) -> AonwTerrainArtifactIdentity:
	var changed := identity.to_dictionary()
	changed[field] = value
	return AonwTerrainArtifactIdentity.new(changed)

func _directory_hashes(path: String) -> Dictionary:
	var result := {}
	var directory := DirAccess.open(ProjectSettings.globalize_path(path))
	if directory == null:
		return result
	var file_names := directory.get_files()
	file_names.sort()
	for file_name in file_names:
		result[file_name] = FileAccess.get_sha256(path.path_join(file_name))
	return result

func _test_snapshot_integrity(
	surface: AonwTerrainAuthoringSurface,
	artifact: AonwTerrainCompiledArtifact,
	directory: String,
) -> void:
	var region_path := directory.path_join("terrain3d_00_00.res")
	var original := FileAccess.get_file_as_bytes(region_path)
	var file := FileAccess.open(region_path, FileAccess.WRITE)
	if file == null:
		_check(false, "terrain snapshot region can be opened for integrity test")
		return
	file.store_buffer(original)
	file.store_8(0)
	file = null
	var result := AuthoringStore.new(surface.authoring_root).load_revision(artifact.identity())
	_check(not result["ok"], "snapshot hash validation rejects a modified Terrain3D region")
	file = FileAccess.open(region_path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(original)
	file = null

func _open_surface(scene_path: String) -> Dictionary:
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	if packed == null:
		return {"ok": false, "message": "authoring scene does not load"}
	var root := packed.instantiate()
	var surface := root.find_child("TerrainAuthoring", true, false) as AonwTerrainAuthoringSurface
	if surface == null:
		root.free()
		return {"ok": false, "message": "authoring surface is missing"}
	Engine.get_main_loop().root.add_child(root)
	surface.terrain().set_camera(_camera)
	var open_result: Dictionary = await _composition.open_surface(surface)
	await Engine.get_main_loop().process_frame
	if not open_result["ok"]:
		root.free()
		return open_result
	return {"ok": true, "root": root, "surface": surface}

func _check_approx(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) <= 0.001, "%s (%s != %s)" % [message, actual, expected])

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
