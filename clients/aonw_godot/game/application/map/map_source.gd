class_name AonwMapSource
extends RefCounted

var map_id: String
var map_path: String
var visual_directory: String
var origin: String

func _init(
	source_map_id: String,
	source_map_path: String,
	source_visual_directory: String,
	source_origin: String,
) -> void:
	map_id = source_map_id
	map_path = source_map_path
	visual_directory = source_visual_directory
	origin = source_origin

func display_name() -> String:
	return "%s · %s" % [map_id, origin]
