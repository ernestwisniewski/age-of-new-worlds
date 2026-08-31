class_name AonwMemoryTerrainAuthoringPersistence
extends AonwTerrainAuthoringPersistence

var load_count := 0
var draft_count := 0
var publish_count := 0
var last_identity: AonwTerrainArtifactIdentity
var last_artifact: AonwTerrainCompiledArtifact
var last_revision := -1

func load_revision(expected_identity: AonwTerrainArtifactIdentity) -> Dictionary:
	load_count += 1
	last_identity = expected_identity
	return {
		"ok": true,
		"compatibility": "compatible",
		"has_draft": false,
		"revision": 0,
	}

func save_draft(
	_data: Terrain3DData,
	artifact: AonwTerrainCompiledArtifact,
	terrain_revision: int,
) -> Dictionary:
	draft_count += 1
	_record(artifact, terrain_revision)
	return {"ok": true}

func publish(
	_data: Terrain3DData,
	artifact: AonwTerrainCompiledArtifact,
	terrain_revision: int,
) -> Dictionary:
	publish_count += 1
	_record(artifact, terrain_revision)
	return {"ok": true}

func _record(artifact: AonwTerrainCompiledArtifact, terrain_revision: int) -> void:
	last_artifact = artifact
	last_revision = terrain_revision
