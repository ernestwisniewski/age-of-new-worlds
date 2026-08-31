class_name AonwMapTileView
extends RefCounted

var _coordinate: Vector2i
var _display_terrain: StringName
var _yield_terrain: StringName
var _movement_terrains: Array[StringName]
var _terrain_tags: Array[StringName]
var _resources: Array[StringName]
var _height: int

func _init(
	coordinate: Vector2i,
	display_terrain: StringName,
	yield_terrain: StringName,
	movement_terrains: Array[StringName],
	terrain_tags: Array[StringName],
	resources: Array[StringName],
	height: int,
) -> void:
	_coordinate = coordinate
	_display_terrain = display_terrain
	_yield_terrain = yield_terrain
	_movement_terrains = movement_terrains.duplicate()
	_terrain_tags = terrain_tags.duplicate()
	_resources = resources.duplicate()
	_movement_terrains.make_read_only()
	_terrain_tags.make_read_only()
	_resources.make_read_only()
	_height = height

func coordinate() -> Vector2i:
	return _coordinate

func display_terrain() -> StringName:
	return _display_terrain

func yield_terrain() -> StringName:
	return _yield_terrain

func movement_terrains() -> Array[StringName]:
	return _movement_terrains

func terrain_tags() -> Array[StringName]:
	return _terrain_tags

func resources() -> Array[StringName]:
	return _resources

func height() -> int:
	return _height
