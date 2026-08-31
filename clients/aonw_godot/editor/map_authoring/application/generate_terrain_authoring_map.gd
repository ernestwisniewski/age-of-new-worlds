@tool
class_name AonwGenerateTerrainAuthoringMap
extends RefCounted

var _map_reader: AonwMapViewReader
var _terrain_reader: AonwTerrainArtifactReader
var _scene_writer: AonwTerrainAuthoringSceneWriter

func _init(
	map_reader: AonwMapViewReader,
	terrain_reader: AonwTerrainArtifactReader,
	scene_writer: AonwTerrainAuthoringSceneWriter,
) -> void:
	_map_reader = map_reader
	_terrain_reader = terrain_reader
	_scene_writer = scene_writer

func execute(source: AonwMapSource) -> Dictionary:
	var map_result := _map_reader.load_map(source)
	if not map_result["ok"]:
		return map_result
	var terrain_result := _terrain_reader.load_terrain(map_result["map"])
	if not terrain_result["ok"]:
		return terrain_result
	return _scene_writer.prepare_scene(source.map_id)
