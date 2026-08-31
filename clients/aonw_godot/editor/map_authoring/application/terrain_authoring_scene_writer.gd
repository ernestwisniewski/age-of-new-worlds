@tool
class_name AonwTerrainAuthoringSceneWriter
extends RefCounted

func scene_path_for(_map_id: String) -> String:
	return ""

func prepare_scene(_map_id: String) -> Dictionary:
	return {"ok": false, "message": "terrain authoring scene writer is not implemented"}
