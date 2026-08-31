class_name AonwMapPreviewCompositionRoot
extends Node

const OpenMap := preload("res://game/application/map/open_map.gd")
const MapSource := preload("res://game/application/map/map_source.gd")
const PackagedMapCatalog := preload(
	"res://game/application/map/packaged_map_catalog.gd"
)
const LocalMatchSessionController := preload(
	"res://game/application/session/local_match_session_controller.gd"
)
const OpenLocalMatch := preload(
	"res://game/application/session/open_local_match.gd"
)
const LocalMatchWorkflow := preload(
	"res://game/application/match/local_match_workflow.gd"
)
const NativeLocalSession := preload(
	"res://game/infrastructure/engine/native_local_session.gd"
)
const LocalMatchGateway := preload(
	"res://game/infrastructure/engine/local_match_gateway.gd"
)
const TextDocumentReader := preload(
	"res://game/infrastructure/filesystem/text_document_reader.gd"
)
const JsonMapRepository := preload(
	"res://game/infrastructure/map/json_map_repository.gd"
)
const TileAtlasRepository := preload(
	"res://game/infrastructure/map/tile_atlas_repository.gd"
)
const TerrainArtifactRepository := preload(
	"res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd"
)
const RUNTIME_TERRAIN_ROOT := "res://assets/terrain_compiled"

func _ready() -> void:
	var transport := NativeLocalSession.new()
	var documents := TextDocumentReader.new()
	var open_map := OpenMap.new(
		JsonMapRepository.new(transport, documents),
		TileAtlasRepository.new(),
		TerrainArtifactRepository.new(RUNTIME_TERRAIN_ROOT),
	)
	var local_session := LocalMatchSessionController.new(LocalMatchGateway.new(transport))
	var open_local_match := OpenLocalMatch.new(local_session, documents)
	var local_match := LocalMatchWorkflow.new(local_session, open_local_match)
	var packaged_sources: Array[AonwMapSource] = [
		MapSource.new(
			"aonw2_starter",
			"res://assets/maps/aonw2_starter/map.json",
			"res://assets/maps/aonw2_starter",
			"package",
		),
	]
	var packaged_maps := PackagedMapCatalog.new(packaged_sources)
	var screen := get_parent()
	assert(screen.has_method("configure"), "Map preview screen must accept its ports")
	screen.call("configure", open_map, local_match, packaged_maps)
