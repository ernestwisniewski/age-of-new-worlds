extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const OpenMap := preload("res://game/application/map/open_map.gd")
const HexGridGeometry := preload("res://game/presentation/map/geometry/hex_grid_geometry.gd")
const HexMapProjection := preload("res://game/presentation/map/hex_map_projection.gd")
const TerrainSpaceTransform := preload(
	"res://game/application/terrain/terrain_space_transform.gd"
)
const OverlayBuilder := preload(
	"res://game/presentation/map/terrain_overlay_mesh_builder.gd"
)
const JsonMapRepository := preload("res://game/infrastructure/map/json_map_repository.gd")
const NativeLocalSession := preload("res://game/infrastructure/engine/native_local_session.gd")
const TextDocumentReader := preload(
	"res://game/infrastructure/filesystem/text_document_reader.gd"
)
const TileAtlasRepository := preload("res://game/infrastructure/map/tile_atlas_repository.gd")
const TerrainArtifactRepository := preload(
	"res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const MapSurface := preload("res://game/presentation/map/map_surface.gd")
const GEOMETRY_FIXTURE := "res://../../tests/fixtures/geometry/odd_q_flat_top.json"
const IDENTITY_FIXTURE := (
	"res://../../tests/fixtures/maps/aonw2_starter/map_view_identity.json"
)

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_geometry()
	await _test_map_projection()

func _test_geometry() -> void:
	_test_shared_geometry_vectors()
	var geometry := HexGridGeometry.new(25, 19)
	_check(
		geometry.corner_key(Vector2i(0, 0), 0) == geometry.corner_key(Vector2i(1, 0), 4)
		and geometry.corner_key(Vector2i(0, 0), 1) == geometry.corner_key(Vector2i(1, 0), 3),
		"adjacent odd-q hexes share exact corner keys",
	)
	var map_bounds := geometry.bounds().grow(0.001)
	for col in geometry.cols:
		for row in geometry.rows:
			var coordinate := Vector2i(col, row)
			_check(
				geometry.tile_at_point(geometry.tile_center(coordinate)) == coordinate,
				"world-to-hex round-trip preserves tile centers",
			)
			for corner in 6:
				_check(
					map_bounds.has_point(geometry.corner_position(coordinate, corner)),
					"map bounds contain every corner",
				)

func _test_shared_geometry_vectors() -> void:
	var fixture_file := FileAccess.open(
		ProjectSettings.globalize_path(GEOMETRY_FIXTURE),
		FileAccess.READ,
	)
	_check(fixture_file != null, "shared geometry fixture opens")
	if fixture_file == null:
		return
	var fixture: Variant = JSON.parse_string(fixture_file.get_as_text())
	_check(fixture is Dictionary, "shared geometry fixture parses")
	if fixture is not Dictionary:
		return
	var map: Dictionary = fixture["map"]
	var geometry := HexGridGeometry.new(
		int(map["cols"]),
		int(map["rows"]),
		float(fixture["radius"]),
	)
	for vector in fixture["centers"]:
		_check_vector(
			geometry.tile_center(_hex(vector["hex"])),
			vector["point"],
			"shared center vector matches",
		)
	for vector in fixture["corners"]:
		var coordinate := _hex(vector["hex"])
		for index in vector["points"].size():
			_check_vector(
				geometry.corner_position(coordinate, index),
				vector["points"][index],
				"shared corner vector matches",
			)
	var expected_bounds: Array = fixture["bounds"]
	var bounds := geometry.bounds()
	_check_vector(bounds.position, expected_bounds.slice(0, 2), "shared bounds origin matches")
	_check_vector(bounds.size, expected_bounds.slice(2, 4), "shared bounds size matches")
	for vector in fixture["neighbors"]:
		var expected: Array[Vector2i] = []
		for value in vector["hexes"]:
			expected.append(_hex(value))
		_check(
			geometry.neighbors(_hex(vector["hex"])) == expected,
			"shared neighbor vector matches",
		)
	for vector in fixture["picks"]:
		_check(
			geometry.tile_at_point(_point(vector["point"])) == _hex(vector["hex"]),
			"shared picking vector matches",
		)
	var texture_projection := preload(
		"res://game/presentation/map/geometry/map_texture_projection.gd"
	).new(geometry)
	for vector in fixture["uv"]:
		_check_vector(
			texture_projection.normalized_uv(_point(vector["point"])),
			vector["normalized"],
			"shared UV vector matches",
		)

func _test_map_projection() -> void:
	var result: Dictionary = _open_map().execute(MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	))
	_check(result["ok"], "projection fixture map opens")
	if not result["ok"]:
		return
	var map: AonwMapView = result["map"]
	var artifact: AonwTerrainCompiledArtifact = result["terrain_artifact"]
	_test_shared_map_identity(map)
	_test_bundle_content_identity(map)
	_configure_non_default_terrain_space(artifact)
	var camera := Camera3D.new()
	camera.current = true
	Engine.get_main_loop().root.add_child(camera)
	var surface := MapSurface.new()
	Engine.get_main_loop().root.add_child(surface)
	await Engine.get_main_loop().process_frame
	surface.present(map, artifact, result["reference_texture"])
	var projection: AonwHexMapProjection = surface.projection()
	_check(projection != null, "Terrain3D map projection is created")
	if projection == null:
		surface.free()
		camera.free()
		return
	_test_terrain_space_round_trip(projection, artifact)
	_test_transformed_reference(surface, projection, artifact)
	for coordinate in [Vector2i(0, 0), Vector2i(2, 3), Vector2i(4, 4)]:
		var center: Vector3 = projection.hex_center(coordinate)
		_check(
			projection.local_to_hex(center) == coordinate,
			"render projection preserves hex centers",
		)
		var picked := projection.ray_to_hex(
			center + Vector3(0.0, 10.0, 0.0),
			Vector3.DOWN,
		)
		_check(picked == coordinate, "vertical ray selects the expected hex")
	var slope_coordinate := Vector2i(4, 5)
	var slope_target := projection.hex_center(slope_coordinate).lerp(
		projection.hex_corner(slope_coordinate, 0),
		0.6,
	)
	var slope_origin := slope_target + Vector3(0.2, 5.0, 0.2)
	_check(
		projection.ray_to_hex(
			slope_origin,
			(slope_target - slope_origin).normalized(),
		) == slope_coordinate,
		"angled ray follows the rendered slope triangles",
	)
	_check(
		projection.ray_to_hex(Vector3.ZERO, Vector3.ZERO) == HexMapProjection.INVALID_HEX,
		"zero-length ray does not select a hex",
	)
	_check(surface.terrain() is Terrain3D, "runtime terrain backend is Terrain3D")
	_check(
		surface.find_child("BaseTerrain", true, false) == null,
		"runtime has no mesh terrain fallback",
	)
	surface.free()
	camera.free()

func _configure_non_default_terrain_space(artifact: AonwTerrainCompiledArtifact) -> void:
	var origin_shift := Vector3(125.0, 0.0, -75.0)
	artifact.world_origin_meters += origin_shift
	artifact.world_min_meters += Vector2(origin_shift.x, origin_shift.z)
	artifact.reference_translation_meters = Vector3(2.5, 0.05, -1.75)
	artifact.reference_rotation_degrees = Vector3(0.0, 8.0, 0.0)
	artifact.reference_scale = Vector3(0.96, 1.0, 1.04)

func _test_terrain_space_round_trip(
	projection: AonwHexMapProjection,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var space := TerrainSpaceTransform.new(artifact)
	var logical := projection.geometry().tile_center(Vector2i(3, 4))
	var local := space.logical_to_terrain_local(logical)
	var world := space.terrain_local_to_world(local)
	var expected_local := logical - projection.geometry().bounds().position
	_check(
		space.terrain_local_to_logical(local).is_equal_approx(logical),
		"non-zero world origin preserves logical-to-local round-trip",
	)
	_check(
		Vector2(local.x, local.z).is_equal_approx(expected_local),
		"non-zero world origin cancels when logical geometry enters Terrain3D local space",
	)
	_check(
		Vector2(world.x, world.z).is_equal_approx(
			logical + Vector2(
				artifact.world_origin_meters.x,
				artifact.world_origin_meters.z,
			)
		),
		"absolute world coordinates include the authored world origin",
	)
	var projected_center := projection.hex_center(Vector2i(3, 4))
	_check(
		Vector2(projected_center.x, projected_center.z).is_equal_approx(expected_local),
		"rendered hex geometry uses Terrain3D local coordinates at non-zero origin",
	)
	var pixel := Vector2i(17, 23)
	_check(
		space.terrain_local_to_raster_pixel(
			space.raster_pixel_to_terrain_local(pixel)
		) == pixel,
		"raster pixel and Terrain3D local coordinates round-trip",
	)

func _test_transformed_reference(
	surface: AonwMapSurface,
	projection: AonwHexMapProjection,
	artifact: AonwTerrainCompiledArtifact,
) -> void:
	var reference := surface.get_node("ReferenceTexture") as MeshInstance3D
	_check(
		reference.transform.is_equal_approx(Transform3D.IDENTITY),
		"reference transform is baked before Terrain3D height sampling",
	)
	var pixel := Vector2i(artifact.width / 2, artifact.height / 2)
	var index := pixel.y * artifact.width + pixel.x
	var arrays := reference.mesh.surface_get_arrays(0)
	var vertex: Vector3 = arrays[Mesh.ARRAY_VERTEX][index]
	var uv: Vector2 = arrays[Mesh.ARRAY_TEX_UV][index]
	var space := TerrainSpaceTransform.new(artifact)
	var source := space.raster_pixel_to_terrain_local(pixel)
	var transformed := space.reference_to_terrain_local(source)
	var terrain_height := surface.terrain().data.get_height(
		Vector3(transformed.x, 0.0, transformed.z)
	)
	var expected_height := terrain_height + transformed.y + OverlayBuilder.REFERENCE_OFFSET
	_check(
		Vector2(vertex.x, vertex.z).is_equal_approx(Vector2(transformed.x, transformed.z)),
		"reference translation, rotation and scale select the sampled Terrain3D position",
	)
	_check(
		is_equal_approx(vertex.y, expected_height),
		"transformed reference follows Terrain3D at its final position",
	)
	_check(
		uv.is_equal_approx(
			space.terrain_local_to_reference_uv(source, projection.geometry().bounds())
		),
		"reference UV remains anchored to logical map space",
	)

func _test_shared_map_identity(map: AonwMapView) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(IDENTITY_FIXTURE), FileAccess.READ)
	_check(file != null, "shared MapView identity fixture opens")
	if file == null:
		return
	var identity: Variant = JSON.parse_string(file.get_as_text())
	_check(identity is Dictionary, "shared MapView identity fixture parses")
	if identity is not Dictionary:
		return
	_check(
		map.map_id() == StringName(identity["mapId"])
		and map.content_hash() == identity["contentHash"]
		and map.grid_layout() == StringName(identity["gridLayout"])
		and map.cols() == int(identity["cols"])
		and map.rows() == int(identity["rows"]),
		"Godot MapView matches the shared client identity",
	)

func _test_bundle_content_identity(map: AonwMapView) -> void:
	var source_path := ProjectSettings.globalize_path(
		"res://assets/maps/aonw2_starter/map_texture_manifest.json"
	)
	var source_file := FileAccess.open(source_path, FileAccess.READ)
	_check(source_file != null, "starter bundle manifest opens")
	if source_file == null:
		return
	var manifest: Dictionary = JSON.parse_string(source_file.get_as_text())
	var wrong_bounds := manifest.duplicate(true)
	wrong_bounds["worldHeight"] = 727.4613391789285
	_check(
		"world bounds do not match" in TileAtlasRepository.new()._manifest_error(
			wrong_bounds,
			map,
		),
		"bundle with clipped odd-q world bounds is rejected",
	)
	var outside_page := manifest.duplicate(true)
	outside_page["pages"][0]["destination"][0] = -10.0
	_check(
		"outside the atlas" in TileAtlasRepository.new()._manifest_error(outside_page, map),
		"bundle page outside the atlas gutter is rejected",
	)
	var overlapping_pages := manifest.duplicate(true)
	var duplicate_page: Dictionary = overlapping_pages["pages"][0].duplicate(true)
	duplicate_page["file"] = "page_01.jpg"
	duplicate_page["asset"] = "assets/runtime/maps/aonw2_starter/page_01.jpg"
	overlapping_pages["pages"].append(duplicate_page)
	_check(
		"overlap excessively" in TileAtlasRepository.new()._manifest_error(
			overlapping_pages,
			map,
		),
		"overlapping bundle pages are rejected",
	)
	var gapped_pages := manifest.duplicate(true)
	gapped_pages["pages"][0]["pixelWidth"] = 1300
	gapped_pages["pages"][0]["destination"][2] = 650.0
	_check(
		"coverage has a gap" in TileAtlasRepository.new()._manifest_error(
			gapped_pages,
			map,
		),
		"bundle page coverage gaps are rejected",
	)
	var excessive_budget := manifest.duplicate(true)
	excessive_budget["pageSizeLimit"] = 10000
	excessive_budget["pages"][0]["pixelWidth"] = 10000
	excessive_budget["pages"][0]["pixelHeight"] = 10000
	excessive_budget["pages"][0]["destination"] = [-1.0, -1.0, 5000.0, 5000.0]
	_check(
		"pixel budget" in TileAtlasRepository.new()._manifest_error(excessive_budget, map),
		"bundle decoded pixel budget is bounded",
	)
	var missing_average := manifest.duplicate(true)
	missing_average["averageColors"].erase("0,0")
	_check(
		"averageColors do not cover" in TileAtlasRepository.new()._manifest_error(
			missing_average,
			map,
		),
		"bundle average colors must cover every map tile",
	)
	manifest["mapContentHash"] = "0".repeat(64)
	var invalid_directory := ProjectSettings.globalize_path("user://invalid-map-bundle")
	DirAccess.make_dir_recursive_absolute(invalid_directory)
	var invalid_manifest_path := invalid_directory.path_join("map_texture_manifest.json")
	var invalid_file := FileAccess.open(invalid_manifest_path, FileAccess.WRITE)
	_check(invalid_file != null, "invalid bundle fixture can be written")
	if invalid_file == null:
		return
	invalid_file.store_string(JSON.stringify(manifest))
	invalid_file.close()
	var result := TileAtlasRepository.new().load_atlas(map, invalid_directory)
	_check(
		not result["ok"] and "map content hash does not match" in result["message"],
		"bundle for a different map content hash is rejected",
	)
	DirAccess.remove_absolute(invalid_manifest_path)
	DirAccess.remove_absolute(invalid_directory)

func _open_map():
	return OpenMap.new(
		JsonMapRepository.new(NativeLocalSession.new(), TextDocumentReader.new()),
		TileAtlasRepository.new(),
		TerrainArtifactRepository.new(),
	)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _hex(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _check_vector(actual: Vector2, expected: Array, message: String) -> void:
	_check(
		actual.is_equal_approx(_point(expected)),
		"%s: %s != %s" % [message, actual, expected],
	)
