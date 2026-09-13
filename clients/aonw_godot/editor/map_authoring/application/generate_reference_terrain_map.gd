@tool
extends "res://editor/map_authoring/application/generate_terrain_authoring_map.gd"
## The self-opening reference scene performs full source/atlas verification.
## Do not require a .godot cache when a verified packaged artifact is available.

func execute(source: AonwMapSource) -> Dictionary:
	if source == null or not FileAccess.file_exists(source.map_path):
		return {"ok": false, "message": "The selected map document is missing"}
	return _scene_writer.prepare_scene(source.map_id)
