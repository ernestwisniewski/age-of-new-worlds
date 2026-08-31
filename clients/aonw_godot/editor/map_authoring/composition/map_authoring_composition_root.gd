@tool
class_name AonwMapAuthoringCompositionRoot
extends RefCounted

const MapAssetCatalog := preload(
	"res://editor/map_authoring/infrastructure/map_asset_catalog.gd"
)
const JsonMapRepository := preload(
	"res://game/infrastructure/map/json_map_repository.gd"
)
const NativeLocalSession := preload(
	"res://game/infrastructure/engine/native_local_session.gd"
)
const TextDocumentReader := preload(
	"res://game/infrastructure/filesystem/text_document_reader.gd"
)
const TileAtlasRepository := preload(
	"res://game/infrastructure/map/tile_atlas_repository.gd"
)
const ArtifactRepository := preload(
	"res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const AuthoringStore := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_authoring_store.gd"
)
const AuthoringSession := preload(
	"res://editor/map_authoring/application/terrain_authoring_session.gd"
)
const SceneRepository := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_authoring_scene_repository.gd"
)
const SceneFactory := preload(
	"res://editor/map_authoring/presentation/terrain_authoring_scene_factory.gd"
)
const GenerateTerrainAuthoringMap := preload(
	"res://editor/map_authoring/application/generate_terrain_authoring_map.gd"
)
const WorkbenchDock := preload(
	"res://editor/map_authoring/presentation/map_workbench_dock.gd"
)
const EngineLogicalMapWorkbench := preload(
	"res://editor/map_authoring/infrastructure/engine_logical_map_workbench.gd"
)
const FilesystemTerrainProfileEditor := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_profile_editor.gd"
)
const FilesystemLogicalMapEditor := preload(
	"res://editor/map_authoring/infrastructure/logical_map_editor.gd"
)
const CreateLogicalMap := preload(
	"res://editor/map_authoring/application/create_logical_map.gd"
)
const FilesystemGeneratedMapStore := preload(
	"res://editor/map_authoring/infrastructure/filesystem_generated_map_store.gd"
)
const TerrainCompiler := preload(
	"res://editor/map_authoring/infrastructure/terrain/terrain_compiler.gd"
)
const GeneratedDecorationPlanRepository := preload(
	"res://editor/map_authoring/infrastructure/generated_decoration_plan_repository.gd"
)

var _catalog: AonwMapSourceCatalog
var _map_reader: AonwMapViewReader
var _atlas_reader: AonwMapTextureAssembler
var _artifact_reader: AonwTerrainCompiledArtifactRepository
var _scene_writer: AonwTerrainAuthoringSceneRepository
var _generator: AonwGenerateTerrainAuthoringMap
var _logical_map_workbench: AonwLogicalMapWorkbench
var _logical_map_editor: AonwLogicalMapEditor
var _create_logical_map: AonwCreateLogicalMap
var _terrain_profile_editor: AonwTerrainProfileEditor
var _generated_decoration_reader: AonwGeneratedDecorationPlanReader

func _init(
	scene_root: String = AonwTerrainAuthoringSceneRepository.SCENE_ROOT,
	authoring_asset_root: String = AonwTerrainAuthoringSceneRepository.AUTHORING_ASSET_ROOT,
	compiled_artifact_root: String = AonwTerrainAuthoringSceneRepository.COMPILED_ARTIFACT_ROOT,
) -> void:
	_catalog = MapAssetCatalog.new()
	_artifact_reader = ArtifactRepository.new(compiled_artifact_root)
	_map_reader = JsonMapRepository.new(
		NativeLocalSession.new(),
		TextDocumentReader.new(),
	)
	_atlas_reader = TileAtlasRepository.new()
	_scene_writer = SceneRepository.new(
		SceneFactory.new(),
		scene_root,
		authoring_asset_root,
		compiled_artifact_root,
	)
	_generator = GenerateTerrainAuthoringMap.new(
		_map_reader,
		_artifact_reader,
		_scene_writer,
	)
	_logical_map_workbench = EngineLogicalMapWorkbench.new()
	_create_logical_map = CreateLogicalMap.new(
		_logical_map_workbench,
		FilesystemGeneratedMapStore.new(TerrainCompiler.new()),
	)
	_logical_map_editor = FilesystemLogicalMapEditor.new(_logical_map_workbench)
	_terrain_profile_editor = FilesystemTerrainProfileEditor.new(_logical_map_workbench)
	_generated_decoration_reader = GeneratedDecorationPlanRepository.new()

func create_dock() -> Control:
	var dock := WorkbenchDock.new()
	dock.configure(
		_catalog,
		_generator,
		_scene_writer,
		_create_logical_map,
		_logical_map_editor,
		_terrain_profile_editor,
	)
	return dock

func generator() -> AonwGenerateTerrainAuthoringMap:
	return _generator

func scene_writer() -> AonwTerrainAuthoringSceneWriter:
	return _scene_writer

func logical_map_workbench() -> AonwLogicalMapWorkbench:
	return _logical_map_workbench

func open_scene(scene_root: Node) -> Dictionary:
	if scene_root == null:
		return {"ok": true, "ignored": true}
	var surface := scene_root as AonwTerrainAuthoringSurface
	if surface == null:
		surface = scene_root.find_child(
			"TerrainAuthoring",
			true,
			false,
		) as AonwTerrainAuthoringSurface
	if surface == null:
		return {"ok": true, "ignored": true}
	return await open_surface(surface)

func open_surface(surface: AonwTerrainAuthoringSurface) -> Dictionary:
	if surface.is_session_open():
		return {"ok": true}
	if (
		surface.source_map_id.is_empty()
		or surface.compiled_artifact_directory.is_empty()
		or surface.authoring_root.is_empty()
	):
		return _failure("terrain authoring scene is not configured")
	var terrain := surface.terrain()
	if terrain.data == null and surface.is_inside_tree():
		await surface.get_tree().process_frame
	if terrain.data == null:
		return _failure("Terrain3D data is not ready")
	var source := _source_for_map(surface.source_map_id)
	if source == null:
		return _failure("logical source map is missing: %s" % surface.source_map_id)
	var map_result := _map_reader.load_map(source)
	if not map_result["ok"]:
		return map_result
	var terrain_result := _artifact_reader.load_terrain(map_result["map"])
	if not terrain_result["ok"]:
		return terrain_result
	var atlas_result := _atlas_reader.load_atlas(
		map_result["map"],
		map_result["visual_directory"],
	)
	var store := AuthoringStore.new(surface.authoring_root)
	var reference_texture: Texture2D = (
		atlas_result["reference_texture"] if atlas_result["ok"] else null
	)
	var artifact: AonwTerrainCompiledArtifact = terrain_result["artifact"]
	var session := AuthoringSession.new(terrain.data, artifact, store)
	var result := surface.open_session(session, artifact, reference_texture, _artifact_reader)
	if result["ok"]:
		var decorations := _generated_decoration_reader.load_plan(source, artifact)
		if decorations["ok"]:
			surface.present_generated_decorations(decorations["placements"])
		else:
			surface.clear_generated_decorations()
			result["generated_warning"] = decorations["message"]
	if result["ok"] and not atlas_result["ok"]:
		result["reference_warning"] = atlas_result["message"]
	return result

func _source_for_map(map_id: String) -> AonwMapSource:
	for source in _catalog.discover():
		if source.map_id == map_id:
			return source
	return null

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
