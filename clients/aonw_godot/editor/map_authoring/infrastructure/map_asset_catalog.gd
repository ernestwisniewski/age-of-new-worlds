class_name AonwMapAssetCatalog
extends AonwMapSourceCatalog

const MapSource := preload("res://game/application/map/map_source.gd")
const DEFAULT_CONTENT_ROOT := "res://../../content/maps"
const BUNDLED_ROOT := "res://assets/maps"
const RUNTIME_MAP_ASSET_ROOT := "res://../../assets/runtime/maps"

var _content_root: String
var _bundled_root: String
var _runtime_map_asset_root: String

func _init(
	content_root: String = DEFAULT_CONTENT_ROOT,
	bundled_root: String = BUNDLED_ROOT,
	runtime_map_asset_root: String = RUNTIME_MAP_ASSET_ROOT,
) -> void:
	_content_root = content_root
	_bundled_root = bundled_root
	_runtime_map_asset_root = runtime_map_asset_root

func discover() -> Array[AonwMapSource]:
	var sources: Array[AonwMapSource] = []
	_append_sources(sources, _content_root, _runtime_map_asset_root, "content")
	_append_sources(sources, _bundled_root, _bundled_root, "Godot")
	sources = _deduplicate(sources)
	sources.sort_custom(func(left: AonwMapSource, right: AonwMapSource) -> bool:
		if left.map_id == right.map_id:
			return left.origin < right.origin
		return left.map_id < right.map_id
	)
	return sources

func _append_sources(
	target: Array[AonwMapSource],
	root_path: String,
	visual_root: String,
	origin: String,
) -> void:
	var absolute_root := _resolve_path(root_path)
	var directory := DirAccess.open(absolute_root)
	if directory == null:
		return
	for directory_name in directory.get_directories():
		var source_directory := root_path.path_join(directory_name)
		var absolute_source_directory := absolute_root.path_join(directory_name)
		var map_path := source_directory.path_join("map.json")
		if not FileAccess.file_exists(absolute_source_directory.path_join("map.json")):
			continue
		target.append(AonwMapSource.new(
			directory_name,
			map_path,
			visual_root.path_join(directory_name),
			origin,
		))

func _deduplicate(sources: Array[AonwMapSource]) -> Array[AonwMapSource]:
	var result: Array[AonwMapSource] = []
	var selected := {}
	for source in sources:
		var key := source.map_id
		if selected.has(key):
			if source.origin == "Godot":
				var canonical: AonwMapSource = selected[key]
				canonical.visual_directory = source.visual_directory
			continue
		selected[key] = source
		result.append(source)
	return result

static func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return ProjectSettings.globalize_path(path)
	return path
