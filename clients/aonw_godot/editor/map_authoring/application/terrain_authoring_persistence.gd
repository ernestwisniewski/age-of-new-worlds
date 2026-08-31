class_name AonwTerrainAuthoringPersistence
extends RefCounted

func load_revision(_expected_identity: AonwTerrainArtifactIdentity) -> Dictionary:
	return {"ok": false, "message": "terrain authoring persistence is not implemented"}

func save_draft(
	_data: Terrain3DData,
	_artifact: AonwTerrainCompiledArtifact,
	_terrain_revision: int,
) -> Dictionary:
	return {"ok": false, "message": "terrain draft persistence is not implemented"}

func publish(
	_data: Terrain3DData,
	_artifact: AonwTerrainCompiledArtifact,
	_terrain_revision: int,
) -> Dictionary:
	return {"ok": false, "message": "terrain publication is not implemented"}
