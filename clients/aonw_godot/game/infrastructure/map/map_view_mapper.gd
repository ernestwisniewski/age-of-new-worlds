class_name AonwMapViewMapper
extends RefCounted

const MapView := preload("res://game/application/map/read_model/map_view.gd")
const MapTileView := preload("res://game/application/map/read_model/map_tile_view.gd")
const MapObjectiveView := preload(
	"res://game/application/map/read_model/map_objective_view.gd"
)
const TERRAIN_NAMES := [
	"ocean", "coast", "lake", "plains", "grassland", "desert", "tundra", "snow",
	"mountain", "hills", "wetlands", "jungle", "forest", "river",
]
const RESOURCE_NAMES := [
	"wheat", "fish", "deer", "sheep", "rice", "cow", "apple", "banana", "citrus",
	"gold", "silver", "gems", "silk", "spices", "cotton", "grapes", "ivory",
	"pearls", "coffee", "cocoa", "tobacco", "sugar", "iron", "coal", "oil",
	"aluminium", "uranium", "horses", "marble",
]
const OBJECTIVE_TYPES := ["ruins", "strategicPass", "holySite", "legendaryResource"]

func from_wire(raw: Variant) -> Dictionary:
	if not _has_exact_fields(raw, [
		"mapId", "contentHash", "gridLayout", "cols", "rows", "defaultZoom",
		"tiles", "objectives",
	]):
		return _failure("Engine map view has invalid fields")
	if (
		not raw["mapId"] is String
		or str(raw["mapId"]).is_empty()
		or not raw["contentHash"] is String
		or not _is_sha256(raw["contentHash"])
		or raw["gridLayout"] != "oddQFlatTop"
		or not _is_integer(raw["cols"], true)
		or int(raw["cols"]) == 0
		or not _is_integer(raw["rows"], true)
		or int(raw["rows"]) == 0
		or not _is_positive_number(raw["defaultZoom"])
		or not raw["objectives"] is Array
		or not raw["tiles"] is Array
	):
		return _failure("Engine map view values are invalid")

	var objectives: Array[AonwMapObjectiveView] = []
	for raw_objective in raw["objectives"]:
		var objective_result := _objective(raw_objective)
		if not objective_result["ok"]:
			return objective_result
		objectives.append(objective_result["value"])

	var tiles: Array[AonwMapTileView] = []
	for raw_tile in raw["tiles"]:
		var tile_result := _tile(raw_tile)
		if not tile_result["ok"]:
			return tile_result
		tiles.append(tile_result["value"])
	var coverage_error := _coverage_error(
		tiles,
		objectives,
		int(raw["cols"]),
		int(raw["rows"]),
	)
	if not coverage_error.is_empty():
		return _failure(coverage_error)

	return {
		"ok": true,
		"value": MapView.new(
			StringName(raw["mapId"]),
			raw["contentHash"],
			StringName(raw["gridLayout"]),
			int(raw["cols"]),
			int(raw["rows"]),
			float(raw["defaultZoom"]),
			objectives,
			tiles,
		),
	}

func _objective(raw: Variant) -> Dictionary:
	if not _has_exact_fields(raw, [
		"id", "type", "coordinate", "requiredHoldTurns", "victoryPoints", "goldPerTurn",
	]):
		return _failure("Engine map objective has invalid fields")
	if (
		not raw["id"] is String
		or str(raw["id"]).is_empty()
		or not raw["type"] is String
		or raw["type"] not in OBJECTIVE_TYPES
		or not _is_coordinate(raw["coordinate"])
		or not _is_integer(raw["requiredHoldTurns"], true)
		or not _is_integer(raw["victoryPoints"], true)
		or not _is_integer(raw["goldPerTurn"], true)
	):
		return _failure("Engine map objective values are invalid")
	return {
		"ok": true,
		"value": MapObjectiveView.new(
			StringName(raw["id"]),
			StringName(raw["type"]),
			_coordinate(raw["coordinate"]),
			int(raw["requiredHoldTurns"]),
			int(raw["victoryPoints"]),
			int(raw["goldPerTurn"]),
		),
	}

func _tile(raw: Variant) -> Dictionary:
	if not _has_exact_fields(raw, [
		"coordinate", "displayTerrain", "yieldTerrain", "movementTerrains",
		"terrainTags", "resources", "height",
	]):
		return _failure("Engine map tile has invalid fields")
	if (
		not _is_coordinate(raw["coordinate"])
		or not raw["displayTerrain"] is String
		or raw["displayTerrain"] not in TERRAIN_NAMES
		or not raw["yieldTerrain"] is String
		or raw["yieldTerrain"] not in TERRAIN_NAMES
		or not raw["movementTerrains"] is Array
		or not raw["terrainTags"] is Array
		or not raw["resources"] is Array
		or not _is_integer(raw["height"], true)
	):
		return _failure("Engine map tile values are invalid")
	var movement_terrains := _names(raw["movementTerrains"], TERRAIN_NAMES)
	var terrain_tags := _names(raw["terrainTags"], TERRAIN_NAMES)
	var resources := _names(raw["resources"], RESOURCE_NAMES)
	for result in [movement_terrains, terrain_tags, resources]:
		if not result["ok"]:
			return _failure("Engine map tile collections are invalid")
	return {
		"ok": true,
		"value": MapTileView.new(
			_coordinate(raw["coordinate"]),
			StringName(raw["displayTerrain"]),
			StringName(raw["yieldTerrain"]),
			movement_terrains["value"],
			terrain_tags["value"],
			resources["value"],
			int(raw["height"]),
		),
	}

func _names(raw: Array, allowed: Array) -> Dictionary:
	var result: Array[StringName] = []
	for value in raw:
		if not value is String or value not in allowed:
			return _failure("expected a string collection")
		result.append(StringName(value))
	return {"ok": true, "value": result}

func _is_coordinate(raw: Variant) -> bool:
	return (
		_has_exact_fields(raw, ["col", "row"])
		and _is_integer(raw["col"], true)
		and _is_integer(raw["row"], true)
	)

func _coordinate(raw: Dictionary) -> Vector2i:
	return Vector2i(int(raw["col"]), int(raw["row"]))

func _is_positive_number(raw: Variant) -> bool:
	return (raw is int or raw is float) and float(raw) > 0.0 and is_finite(float(raw))

func _is_integer(raw: Variant, non_negative: bool) -> bool:
	if not raw is int and not raw is float:
		return false
	var integer := int(raw)
	return float(integer) == float(raw) and (not non_negative or integer >= 0)

func _coverage_error(
	tiles: Array[AonwMapTileView],
	objectives: Array[AonwMapObjectiveView],
	cols: int,
	rows: int,
) -> String:
	if tiles.size() != cols * rows:
		return "Engine map tile coverage is incomplete"
	var coordinates := {}
	for tile in tiles:
		var coordinate := tile.coordinate()
		if not _within_bounds(coordinate, cols, rows):
			return "Engine map tile is outside map bounds"
		if coordinates.has(coordinate):
			return "Engine map tile coordinate is duplicated"
		if tile.height() < 0 or tile.height() > 5:
			return "Engine map tile height is outside the supported range"
		coordinates[coordinate] = true
	var objective_ids := {}
	for objective in objectives:
		if not _within_bounds(objective.coordinate(), cols, rows):
			return "Engine map objective is outside map bounds"
		if objective_ids.has(objective.id()):
			return "Engine map objective id is duplicated"
		objective_ids[objective.id()] = true
	return ""

func _within_bounds(coordinate: Vector2i, cols: int, rows: int) -> bool:
	return (
		coordinate.x >= 0
		and coordinate.x < cols
		and coordinate.y >= 0
		and coordinate.y < rows
	)

func _is_sha256(value: Variant) -> bool:
	return (
		value is String
		and value.length() == 64
		and value.to_lower() == value
		and value.is_valid_hex_number(false)
	)

func _has_exact_fields(raw: Variant, fields: Array) -> bool:
	if not raw is Dictionary or raw.size() != fields.size():
		return false
	for field in fields:
		if not raw.has(field):
			return false
	return true

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
