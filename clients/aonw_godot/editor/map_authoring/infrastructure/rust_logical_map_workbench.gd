class_name AonwRustLogicalMapWorkbench
extends AonwLogicalMapWorkbench

const API_VERSION := 1
const PACKAGE_FIELDS := [
	"mapDocument",
	"terrainAuthoringDocument",
	"generationDocument",
	"generatedDecorationPlanDocument",
	"mapContentHash",
	"authoringProfileHash",
	"generationSpecHash",
	"generatedDecorationPlanHash",
]
const TERRAIN_PROFILE_UPDATE_FIELDS := [
	"terrainAuthoringDocument",
	"authoringProfileHash",
	"maxTerrainHeightMeters",
]
const MAP_EDIT_UPDATE_FIELDS := [
	"mapDocument",
	"terrainAuthoringDocument",
	"mapContentHash",
	"authoringProfileHash",
	"snapshot",
]
const TILE_EDITOR_SNAPSHOT_FIELDS := [
	"mapContentHash", "cols", "rows", "tile", "terrainOptions", "resourceOptions",
]
const TILE_FIELDS := [
	"col", "row", "displayTerrain", "terrainTags", "resources", "height",
]

var _bridge: RefCounted

func _init(bridge: RefCounted = null) -> void:
	_bridge = bridge if bridge != null else AonwMapWorkbenchBridge.new()

func generate_map(spec_document: String) -> Dictionary:
	var request := JSON.stringify({
		"apiVersion": API_VERSION,
		"request": {
			"type": "generateMap",
			"specDocument": spec_document,
		},
	})
	var parsed: Variant = JSON.parse_string(str(_bridge.request_json(request)))
	if parsed is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench returned invalid JSON")
	var response: Dictionary = parsed
	if response.get("apiVersion") != API_VERSION or response.get("outcome") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench response is incompatible")
	var outcome: Dictionary = response["outcome"]
	if outcome.get("status") == "failure":
		var error: Variant = outcome.get("error")
		if error is not Dictionary:
			return _failure("invalid_workbench_response", "Rust workbench failure is malformed")
		return {
			"ok": false,
			"code": str(error.get("code", "map_generation_failed")),
			"message": str(error.get("message", "map generation failed")),
			"path": str(error.get("path", "")),
		}
	if outcome.get("status") != "success" or outcome.get("response") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench outcome is malformed")
	var body: Dictionary = outcome["response"]
	if body.get("type") != "mapGenerated" or body.get("package") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench result is unsupported")
	var package: Dictionary = body["package"]
	if not _has_exact_string_fields(package, PACKAGE_FIELDS):
		return _failure("invalid_workbench_response", "generated map package is malformed")
	return {"ok": true, "package": package}

func generate_blank_map(
	map_id: String,
	cols: int,
	rows: int,
	default_zoom: float,
	hex_radius_meters: float,
	max_terrain_height_meters: float,
	seed: String,
) -> Dictionary:
	return generate_new_map(
		&"blank",
		map_id,
		cols,
		rows,
		default_zoom,
		hex_radius_meters,
		max_terrain_height_meters,
		seed,
	)

func generate_new_map(
	generator_id: StringName,
	map_id: String,
	cols: int,
	rows: int,
	default_zoom: float,
	hex_radius_meters: float,
	max_terrain_height_meters: float,
	seed: String,
) -> Dictionary:
	return generate_map(JSON.stringify({
		"generatorId": str(generator_id),
		"generatorVersion": 1,
		"mapId": map_id,
		"cols": cols,
		"rows": rows,
		"defaultZoom": default_zoom,
		"hexRadiusMeters": hex_radius_meters,
		"maxTerrainHeightMeters": max_terrain_height_meters,
		"seed": seed,
	}))

func reconfigure_terrain_height(
	map_document: String,
	terrain_authoring_document: String,
	max_terrain_height_meters: float,
) -> Dictionary:
	var request := JSON.stringify({
		"apiVersion": API_VERSION,
		"request": {
			"type": "reconfigureTerrainHeight",
			"mapDocument": map_document,
			"terrainAuthoringDocument": terrain_authoring_document,
			"maxTerrainHeightMeters": max_terrain_height_meters,
		},
	})
	var parsed: Variant = JSON.parse_string(str(_bridge.request_json(request)))
	if parsed is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench returned invalid JSON")
	var response: Dictionary = parsed
	if response.get("apiVersion") != API_VERSION or response.get("outcome") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench response is incompatible")
	var outcome: Dictionary = response["outcome"]
	if outcome.get("status") == "failure":
		var error: Variant = outcome.get("error")
		if error is not Dictionary:
			return _failure("invalid_workbench_response", "Rust workbench failure is malformed")
		return {
			"ok": false,
			"code": str(error.get("code", "terrain_height_reconfiguration_failed")),
			"message": str(error.get("message", "terrain height reconfiguration failed")),
			"path": str(error.get("path", "")),
		}
	if outcome.get("status") != "success" or outcome.get("response") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench outcome is malformed")
	var body: Dictionary = outcome["response"]
	if body.get("type") != "terrainHeightReconfigured" or body.get("update") is not Dictionary:
		return _failure("invalid_workbench_response", "terrain profile update is unsupported")
	var update: Dictionary = body["update"]
	if update.size() != TERRAIN_PROFILE_UPDATE_FIELDS.size():
		return _failure("invalid_workbench_response", "terrain profile update is malformed")
	if (
		update.get("terrainAuthoringDocument") is not String
		or update["terrainAuthoringDocument"].is_empty()
		or update.get("authoringProfileHash") is not String
		or update["authoringProfileHash"].is_empty()
		or update.get("maxTerrainHeightMeters") is not float
		or not is_finite(update["maxTerrainHeightMeters"])
		or update["maxTerrainHeightMeters"] <= 0.0
	):
		return _failure("invalid_workbench_response", "terrain profile update is malformed")
	return {"ok": true, "update": update}

func inspect_map_tile(map_document: String, coordinate: Vector2i) -> Dictionary:
	var result := _dispatch({
		"type": "inspectMapTile",
		"mapDocument": map_document,
		"col": coordinate.x,
		"row": coordinate.y,
	}, "mapTileInspected")
	if not result["ok"]:
		return result
	var snapshot: Variant = result["body"].get("snapshot")
	if not _is_tile_editor_snapshot(snapshot):
		return _failure("invalid_workbench_response", "map tile snapshot is malformed")
	return {"ok": true, "snapshot": snapshot}

func set_tile_terrain(
	map_document: String,
	terrain_authoring_document: String,
	coordinate: Vector2i,
	terrain: StringName,
) -> Dictionary:
	return _edit({
		"type": "setTileTerrain",
		"mapDocument": map_document,
		"terrainAuthoringDocument": terrain_authoring_document,
		"col": coordinate.x,
		"row": coordinate.y,
		"terrain": str(terrain),
	})

func set_tile_resources(
	map_document: String,
	terrain_authoring_document: String,
	coordinate: Vector2i,
	resources: Array[StringName],
) -> Dictionary:
	var wire_resources: Array[String] = []
	for resource in resources:
		wire_resources.append(str(resource))
	return _edit({
		"type": "setTileResources",
		"mapDocument": map_document,
		"terrainAuthoringDocument": terrain_authoring_document,
		"col": coordinate.x,
		"row": coordinate.y,
		"resources": wire_resources,
	})

func set_tile_height(
	map_document: String,
	terrain_authoring_document: String,
	coordinate: Vector2i,
	height: int,
) -> Dictionary:
	return _edit({
		"type": "setTileHeight",
		"mapDocument": map_document,
		"terrainAuthoringDocument": terrain_authoring_document,
		"col": coordinate.x,
		"row": coordinate.y,
		"height": height,
	})

func _edit(request_body: Dictionary) -> Dictionary:
	var result := _dispatch(request_body, "mapTileEdited")
	if not result["ok"]:
		return result
	var update: Variant = result["body"].get("update")
	if not _has_exact_fields(update, MAP_EDIT_UPDATE_FIELDS):
		return _failure("invalid_workbench_response", "logical map update is malformed")
	if (
		not update["mapDocument"] is String
		or update["mapDocument"].is_empty()
		or not update["terrainAuthoringDocument"] is String
		or update["terrainAuthoringDocument"].is_empty()
		or not _is_sha256(update["mapContentHash"])
		or not _is_sha256(update["authoringProfileHash"])
		or not _is_tile_editor_snapshot(update["snapshot"])
		or update["mapContentHash"] != update["snapshot"]["mapContentHash"]
	):
		return _failure("invalid_workbench_response", "logical map update is malformed")
	return {"ok": true, "update": update}

func _dispatch(request_body: Dictionary, expected_type: String) -> Dictionary:
	var request := JSON.stringify({
		"apiVersion": API_VERSION,
		"request": request_body,
	})
	var parsed: Variant = JSON.parse_string(str(_bridge.request_json(request)))
	if parsed is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench returned invalid JSON")
	var response: Dictionary = parsed
	if response.get("apiVersion") != API_VERSION or response.get("outcome") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench response is incompatible")
	var outcome: Dictionary = response["outcome"]
	if outcome.get("status") == "failure":
		var error: Variant = outcome.get("error")
		if error is not Dictionary:
			return _failure("invalid_workbench_response", "Rust workbench failure is malformed")
		return {
			"ok": false,
			"code": str(error.get("code", "logical_map_edit_failed")),
			"message": str(error.get("message", "logical map edit failed")),
			"path": str(error.get("path", "")),
		}
	if outcome.get("status") != "success" or outcome.get("response") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench outcome is malformed")
	var body: Dictionary = outcome["response"]
	if body.get("type") != expected_type:
		return _failure("invalid_workbench_response", "Rust workbench result is unsupported")
	return {"ok": true, "body": body}

func _is_tile_editor_snapshot(value: Variant) -> bool:
	if not _has_exact_fields(value, TILE_EDITOR_SNAPSHOT_FIELDS):
		return false
	if (
		not _is_sha256(value["mapContentHash"])
		or not _is_integer(value["cols"], 1, 40)
		or not _is_integer(value["rows"], 1, 30)
		or not _is_name_array(value["terrainOptions"])
		or not _is_name_array(value["resourceOptions"])
		or not _has_exact_fields(value["tile"], TILE_FIELDS)
	):
		return false
	var tile: Dictionary = value["tile"]
	return (
		_is_integer(tile["col"], 0, int(value["cols"]) - 1)
		and _is_integer(tile["row"], 0, int(value["rows"]) - 1)
		and tile["displayTerrain"] is String
		and tile["displayTerrain"] in value["terrainOptions"]
		and _is_name_array(tile["terrainTags"], value["terrainOptions"])
		and _is_name_array(tile["resources"], value["resourceOptions"], true)
		and _is_integer(tile["height"], 0, 5)
	)

func _has_exact_fields(value: Variant, expected: Array) -> bool:
	if value is not Dictionary or value.size() != expected.size():
		return false
	for field in expected:
		if not value.has(field):
			return false
	return true

func _is_name_array(value: Variant, allowed: Array = [], allow_empty := false) -> bool:
	if value is not Array or (value.is_empty() and not allow_empty):
		return false
	var seen := {}
	for name in value:
		if not name is String or name.is_empty() or seen.has(name):
			return false
		if not allowed.is_empty() and name not in allowed:
			return false
		seen[name] = true
	return true

func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if value is not int and value is not float:
		return false
	return float(int(value)) == float(value) and int(value) >= minimum and int(value) <= maximum

func _is_sha256(value: Variant) -> bool:
	return (
		value is String
		and value.length() == 64
		and value.to_lower() == value
		and value.is_valid_hex_number(false)
	)

func _has_exact_string_fields(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for field in expected:
		if not value.has(field) or value[field] is not String or value[field].is_empty():
			return false
	return true

func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
