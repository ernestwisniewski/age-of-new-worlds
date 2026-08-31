class_name AonwOpenMap
extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")

var _map_repository: AonwMapViewReader
var _atlas_repository: AonwMapTextureAssembler
var _terrain_repository: AonwTerrainArtifactReader

func _init(
	map_repository: AonwMapViewReader,
	atlas_repository: AonwMapTextureAssembler,
	terrain_repository: AonwTerrainArtifactReader,
) -> void:
	_map_repository = map_repository
	_atlas_repository = atlas_repository
	_terrain_repository = terrain_repository

func execute(source: AonwMapSource) -> Dictionary:
	var map_result: Dictionary = _map_repository.load_map(source)
	if not map_result["ok"]:
		return map_result

	var atlas_result: Dictionary = _atlas_repository.load_atlas(
		map_result["map"],
		map_result["visual_directory"],
	)
	if not atlas_result["ok"]:
		return atlas_result
	var terrain_result: Dictionary = _terrain_repository.load_terrain(map_result["map"])
	if not terrain_result["ok"]:
		return terrain_result
	return _success(map_result, atlas_result, terrain_result)

func execute_async(source: AonwMapSource) -> Dictionary:
	var map_result: Dictionary = await _map_repository.load_map_async(source)
	if not map_result["ok"]:
		return map_result
	var atlas_result: Dictionary = _atlas_repository.load_atlas(
		map_result["map"],
		map_result["visual_directory"],
	)
	if not atlas_result["ok"]:
		return atlas_result
	var terrain_result: Dictionary = _terrain_repository.load_terrain(map_result["map"])
	if not terrain_result["ok"]:
		return terrain_result
	return _success(map_result, atlas_result, terrain_result)

func _success(
	map_result: Dictionary,
	atlas_result: Dictionary,
	terrain_result: Dictionary,
) -> Dictionary:
	return {
		"ok": true,
		"map": map_result["map"],
		"reference_texture": atlas_result["reference_texture"],
		"terrain_artifact": terrain_result["artifact"],
	}
