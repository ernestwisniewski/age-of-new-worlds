extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const OpenMap := preload("res://game/application/map/open_map.gd")
const JsonMapRepository := preload("res://game/infrastructure/map/json_map_repository.gd")
const NativeLocalSession := preload("res://game/infrastructure/engine/native_local_session.gd")
const TextDocumentReader := preload(
	"res://game/infrastructure/filesystem/text_document_reader.gd"
)
const MapAssetCatalog := preload(
	"res://editor/map_authoring/infrastructure/map_asset_catalog.gd"
)
const TileAtlasRepository := preload("res://game/infrastructure/map/tile_atlas_repository.gd")
const TerrainArtifactRepository := preload(
	"res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const MapSurface := preload("res://game/presentation/map/map_surface.gd")

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_catalog()
	_test_every_catalog_source_matches_available_artifacts()
	_test_canonical_map_with_runtime_texture()
	await _test_terrain3d_runtime_surface()
	_test_bundled_checkout_without_asset_masters()

func _test_canonical_map_with_runtime_texture() -> void:
	var source := MapSource.new(
		"myranth",
		"res://../../content/maps/myranth/map.json",
		"res://../../assets/runtime/maps/myranth",
		"content",
	)
	var map_result: Dictionary = JsonMapRepository.new(
		NativeLocalSession.new(),
		TextDocumentReader.new(),
	).load_map(source)
	_check(
		map_result["ok"],
		"canonical content map opens through inspectMap: %s"
		% map_result.get("message", "unknown error"),
	)
	if not map_result["ok"]:
		return
	var map: AonwMapView = map_result["map"]
	var atlas_result := TileAtlasRepository.new().load_atlas(map, source.visual_directory)
	_check(atlas_result["ok"], "canonical runtime texture bundle opens")
	if not atlas_result["ok"]:
		return
	_check(map.map_id() == &"myranth", "map identity is retained")
	_check(map.tiles().size() == 475, "complete MapView is normalized")
	_check(map.tiles().is_read_only(), "tile collection is immutable")
	_check(
		map.tiles()[0].movement_terrains().is_read_only(),
		"nested terrain collection is immutable",
	)
	_check(
		atlas_result["reference_texture"].get_width() > 0,
		"reference atlas is created",
	)

func _test_terrain3d_runtime_surface() -> void:
	var result: Dictionary = _open_map().execute(_starter_source())
	_check(result["ok"], "starter opens with its required Terrain3D artifact")
	if not result["ok"]:
		return
	var camera := Camera3D.new()
	camera.current = true
	Engine.get_main_loop().root.add_child(camera)
	var surface := MapSurface.new()
	Engine.get_main_loop().root.add_child(surface)
	await Engine.get_main_loop().process_frame
	surface.present(result["map"], result["terrain_artifact"], result["reference_texture"])
	_check(surface.terrain() is Terrain3D, "runtime terrain backend is Terrain3D")
	_check(
		surface.terrain().material.world_background
		== Terrain3DMaterial.WorldBackground.NONE,
		"runtime renders no Terrain3D world background outside the map",
	)
	_check(
		surface.terrain().data.get_region_count() > 0,
		"compiled base raster is imported into Terrain3D",
	)
	_check(
		surface.find_child("BaseTerrain", true, false) == null,
		"runtime has no ArrayMesh terrain fallback",
	)
	_check(
		surface.get_node("ReferenceTexture").mesh is ArrayMesh,
		"reference remains a Terrain3D-following overlay",
	)
	_check(
		surface.get_node("HexGrid").mesh is ArrayMesh,
		"grid remains an independent Terrain3D-following overlay",
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
	_check(not surface.get_node("HexGrid").visible, "grid visibility is independent")
	surface.free()
	camera.free()

func _test_bundled_checkout_without_asset_masters() -> void:
	var catalog := MapAssetCatalog.new(
		"res://missing-content-root",
		"res://assets/maps",
		"res://missing-runtime-assets",
	)
	var sources := catalog.discover()
	var expected_ids := [
		"aonw2_starter",
		"dravonia",
		"myranth",
		"terenos",
		"verdantia",
	]
	_check(sources.size() == expected_ids.size(), "bundled checkout includes every map")
	for source in sources:
		_check(source.map_id in expected_ids, "%s is a supported bundled map" % source.map_id)
		var result := _open_map().execute(source)
		_check(
			result["ok"]
			and result["map"].map_id() == source.map_id
			and result["map"].content_hash() == result["terrain_artifact"].map_content_hash,
			"%s resolves a Rust MapView and matching Terrain3D artifact" % source.map_id,
		)

func _test_catalog() -> void:
	var sources := MapAssetCatalog.new().discover()
	var identifiers: Array[String] = []
	for source in sources:
		identifiers.append(source.map_id)
	_check("myranth" in identifiers, "catalog discovers canonical content maps")
	_check("aonw2_starter" in identifiers, "catalog discovers canonical Godot maps")
	for source in sources:
		if source.map_id == "aonw2_starter":
			_check(source.origin == "content", "canonical content wins duplicate map ids")
			_check(
				source.visual_directory == "res://assets/maps/aonw2_starter",
				"starter uses the generated Godot visual bundle",
			)

func _test_every_catalog_source_matches_available_artifacts() -> void:
	var map_repository := JsonMapRepository.new(
		NativeLocalSession.new(),
		TextDocumentReader.new(),
	)
	var atlas_repository := TileAtlasRepository.new()
	var terrain_repository := TerrainArtifactRepository.new()
	for source in MapAssetCatalog.new().discover():
		var map_result: Dictionary = map_repository.load_map(source)
		_check(map_result["ok"], "%s canonical map opens" % source.map_id)
		if not map_result["ok"]:
			continue
		var manifest_path := ProjectSettings.globalize_path(
			source.visual_directory.path_join("map_texture_manifest.json")
		)
		if FileAccess.file_exists(manifest_path):
			var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
			_check(manifest_file != null, "%s asset bundle opens" % source.map_id)
			if manifest_file != null:
				var manifest: Variant = JSON.parse_string(manifest_file.get_as_text())
				_check(
					atlas_repository._manifest_error(manifest, map_result["map"]).is_empty(),
					"%s asset bundle matches its Rust map content hash" % source.map_id,
				)
		var terrain_result := terrain_repository.load_terrain(map_result["map"])
		_check(
			terrain_result["ok"],
			"%s has compiled Terrain3D authoring data: %s"
			% [source.map_id, terrain_result.get("message", "unknown error")],
		)

func _starter_source() -> AonwMapSource:
	return MapSource.new(
		"aonw2_starter",
		"res://assets/maps/aonw2_starter/map.json",
		"res://assets/maps/aonw2_starter",
		"Godot",
	)

func _open_map() -> AonwOpenMap:
	return OpenMap.new(
		JsonMapRepository.new(NativeLocalSession.new(), TextDocumentReader.new()),
		TileAtlasRepository.new(),
		TerrainArtifactRepository.new(),
	)

func _check_approx(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) <= 0.001, "%s (%s != %s)" % [message, actual, expected])

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
