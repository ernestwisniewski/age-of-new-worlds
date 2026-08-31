class_name AonwMapViewReader
extends RefCounted

func load_map(_source: AonwMapSource) -> Dictionary:
	return {"ok": false, "message": "map view reader is not implemented"}

func load_map_async(source: AonwMapSource) -> Dictionary:
	return load_map(source)
