@tool
extends "res://editor/map_authoring/composition/map_authoring_composition_root.gd"
## Reference and legacy surfaces share the dock but never race to own a session.

const ReferenceDock := preload("res://editor/map_authoring/presentation/reference_terrain_workbench_dock.gd")
const ReferenceScenes := preload("res://editor/map_authoring/infrastructure/terrain/reference_terrain_scene_repository.gd")
const ReferenceFactory := preload("res://editor/map_authoring/presentation/reference_terrain_scene_factory.gd")
const ReferenceGenerator := preload("res://editor/map_authoring/application/generate_reference_terrain_map.gd")

func _init(
	scene_root: String = AonwTerrainAuthoringSceneRepository.SCENE_ROOT,
	authoring_asset_root: String = AonwTerrainAuthoringSceneRepository.AUTHORING_ASSET_ROOT,
	compiled_artifact_root: String = AonwTerrainAuthoringSceneRepository.COMPILED_ARTIFACT_ROOT,
) -> void:
	super(scene_root, authoring_asset_root, compiled_artifact_root)
	_scene_writer = ReferenceScenes.new(ReferenceFactory.new(), scene_root, authoring_asset_root, compiled_artifact_root)
	_generator = ReferenceGenerator.new(_map_reader, _artifact_reader, _scene_writer)

func create_dock() -> Control:
	var dock := ReferenceDock.new()
	dock.configure(_catalog, _generator, _scene_writer, _create_logical_map, _logical_map_editor, _terrain_profile_editor)
	return dock

func open_surface(surface: AonwTerrainAuthoringSurface) -> Dictionary:
	if surface.has_method("ensure_reference_session"):
		var result: Dictionary = await surface.call("ensure_reference_session")
		return result
	return await super.open_surface(surface)
