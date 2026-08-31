class_name AonwPackagedMapCatalog
extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const PACKAGED_MAP_ROOT := "res://assets/maps"

var _sources: Array[AonwMapSource] = []

func _init(sources: Array[AonwMapSource]) -> void:
	assert(not sources.is_empty(), "At least one packaged map is required")
	var identities: Dictionary = {}
	for source in sources:
		assert(source != null, "Packaged map source is required")
		assert(
			_is_safe_map_id(source.map_id),
			"Packaged map IDs must be safe path segments",
		)
		assert(not identities.has(source.map_id), "Packaged map IDs must be unique")
		var directory := PACKAGED_MAP_ROOT.path_join(source.map_id)
		assert(
			source.map_path == directory.path_join("map.json")
			and source.visual_directory == directory
			and source.origin == "package",
			"Packaged maps must stay inside the runtime asset root",
		)
		identities[source.map_id] = true
		_sources.append(_copy(source))
	_sources.make_read_only()

func count() -> int:
	return _sources.size()

func label_at(index: int) -> String:
	return _sources[index].map_id

func source_at(index: int) -> AonwMapSource:
	return _copy(_sources[index])

static func _is_safe_map_id(value: String) -> bool:
	if value.is_empty() or value != value.to_lower():
		return false
	for character in value:
		if character not in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			return false
	return true

func _copy(source: AonwMapSource) -> AonwMapSource:
	return MapSource.new(
		source.map_id,
		source.map_path,
		source.visual_directory,
		source.origin,
	)
