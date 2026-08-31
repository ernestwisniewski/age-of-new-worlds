extends SceneTree

const MapSource := preload("res://game/application/map/map_source.gd")
const HexGridGeometry := preload(
	"res://game/presentation/map/geometry/hex_grid_geometry.gd"
)
const JsonMapRepository := preload(
	"res://game/infrastructure/map/json_map_repository.gd"
)
const NativeLocalSession := preload(
	"res://game/infrastructure/engine/native_local_session.gd"
)
const TextDocumentReader := preload(
	"res://game/infrastructure/filesystem/text_document_reader.gd"
)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() != 3:
		_fail(
			"usage: export_map_render_probe.gd "
			+ "<scenario.json> <probe.json> <diagnostics.json>"
		)
		return

	var scenario := _read_object(arguments[0])
	if scenario.is_empty():
		return
	var repository := JsonMapRepository.new(
		NativeLocalSession.new(),
		TextDocumentReader.new(),
	)
	var probes: Array[Dictionary] = []
	var diagnostics: Array[Dictionary] = []
	for map_scenario in scenario["maps"]:
		var before_memory := OS.get_static_memory_usage()
		var started_at := Time.get_ticks_usec()
		var result := repository.load_map(MapSource.new(
			map_scenario["mapId"],
			"res://../../%s" % map_scenario["document"],
			"",
			"MapRenderProbe",
		))
		if not result["ok"]:
			_fail("cannot load %s: %s" % [map_scenario["mapId"], result["message"]])
			return
		var map: AonwMapView = result["map"]
		if str(map.map_id()) != map_scenario["mapId"]:
			_fail(
				"expected mapId %s, received %s"
				% [map_scenario["mapId"], map.map_id()]
			)
			return
		var probe := _build_map_probe(map, scenario)
		probes.append(probe)
		diagnostics.append({
			"mapId": str(map.map_id()),
			"cols": map.cols(),
			"rows": map.rows(),
			"tiles": map.tiles().size(),
			"elapsedMicros": Time.get_ticks_usec() - started_at,
			"residentMemoryDeltaBytes": maxi(
				OS.get_static_memory_usage() - before_memory,
				0,
			),
			"serializedProbeBytes": JSON.stringify(probe).to_utf8_buffer().size(),
		})

	if not _write_json(arguments[1], {"maps": probes}):
		return
	if not _write_json(arguments[2], {"maps": diagnostics}):
		return
	print("Godot map render probe: OK")
	quit(0)

func _build_map_probe(map: AonwMapView, scenario: Dictionary) -> Dictionary:
	var geometry := HexGridGeometry.new(map.cols(), map.rows())
	var tiles: Array[Dictionary] = []
	for tile in map.tiles():
		tiles.append(_tile_probe(tile, geometry))
	var objectives: Array[Dictionary] = []
	for objective in map.objectives():
		objectives.append(_objective_probe(objective))
	var cases: Array[Dictionary] = []
	for probe_case in scenario["cases"]:
		cases.append(_case_probe(
			map,
			geometry,
			probe_case,
			scenario["viewports"],
		))
	return {
		"mapId": str(map.map_id()),
		"contentHash": map.content_hash(),
		"gridLayout": str(map.grid_layout()),
		"cols": map.cols(),
		"rows": map.rows(),
		"defaultZoom": float(map.default_zoom()),
		"bounds": _bounds(geometry.bounds()),
		"tiles": tiles,
		"objectives": objectives,
		"cases": cases,
	}

func _tile_probe(tile: AonwMapTileView, geometry: AonwHexGridGeometry) -> Dictionary:
	var coordinate := tile.coordinate()
	var center := geometry.tile_center(coordinate)
	var corners: Array[Array] = []
	for corner in 6:
		corners.append(_point(_normalized_uv(
			geometry,
			geometry.corner_position(coordinate, corner),
		)))
	var neighbors: Array[Array] = []
	for neighbor in geometry.neighbors(coordinate):
		neighbors.append(_hex(neighbor))
	return {
		"coordinate": _hex(coordinate),
		"displayTerrain": str(tile.display_terrain()),
		"yieldTerrain": str(tile.yield_terrain()),
		"movementTerrains": _strings(tile.movement_terrains()),
		"terrainTags": _strings(tile.terrain_tags()),
		"resources": _strings(tile.resources()),
		"height": tile.height(),
		"center": _point(_normalized_uv(geometry, center)),
		"corners": corners,
		"neighbors": neighbors,
		"centerRoundTrip": _hex(geometry.tile_at_point(center)),
	}

func _objective_probe(objective: AonwMapObjectiveView) -> Dictionary:
	return {
		"id": str(objective.id()),
		"type": str(objective.type()),
		"coordinate": _hex(objective.coordinate()),
		"requiredHoldTurns": objective.required_hold_turns(),
		"victoryPoints": objective.victory_points(),
		"goldPerTurn": objective.gold_per_turn(),
	}

func _case_probe(
	map: AonwMapView,
	geometry: AonwHexGridGeometry,
	probe_case: Dictionary,
	viewports: Array,
) -> Dictionary:
	var world_point := _case_point(geometry, probe_case)
	var normalized := _normalized_uv(geometry, world_point)
	var viewport_probes: Array[Dictionary] = []
	for viewport in viewports:
		viewport_probes.append(_viewport_probe(
			map,
			geometry,
			normalized,
			viewport,
		))
	return {
		"name": probe_case["name"],
		"kind": probe_case["kind"],
		"normalizedPoint": _point(normalized),
		"selectedHex": _selected_hex(map, geometry, world_point),
		"viewports": viewport_probes,
	}

func _viewport_probe(
	map: AonwMapView,
	geometry: AonwHexGridGeometry,
	normalized: Vector2,
	viewport: Dictionary,
) -> Dictionary:
	var width := int(viewport["width"])
	var height := int(viewport["height"])
	var screen := Vector2(normalized.x * float(width), normalized.y * float(height))
	var round_trip_normalized := Vector2(
		screen.x / float(width),
		screen.y / float(height),
	)
	var area := geometry.bounds()
	var round_trip_world := Vector2(
		area.position.x + round_trip_normalized.x * area.size.x,
		area.position.y + round_trip_normalized.y * area.size.y,
	)
	return {
		"name": viewport["name"],
		"width": width,
		"height": height,
		"screenPoint": _point(screen),
		"selectedHex": _selected_hex(map, geometry, round_trip_world),
	}

func _case_point(geometry: AonwHexGridGeometry, probe_case: Dictionary) -> Vector2:
	match probe_case["kind"]:
		"center":
			return geometry.tile_center(_coordinate(probe_case["hex"]))
		"edge":
			var coordinate := _coordinate(probe_case["hex"])
			var corners: Array = probe_case["corners"]
			return _midpoint(
				geometry.corner_position(coordinate, int(corners[0])),
				geometry.corner_position(coordinate, int(corners[1])),
			)
		"corner":
			return geometry.corner_position(
				_coordinate(probe_case["hex"]),
				int(probe_case["corner"]),
			)
		"normalized":
			var normalized := _vector(probe_case["point"])
			var area := geometry.bounds()
			return Vector2(
				area.position.x + normalized.x * area.size.x,
				area.position.y + normalized.y * area.size.y,
			)
		"centerMidpoint":
			var hexes: Array = probe_case["hexes"]
			return _midpoint(
				geometry.tile_center(_coordinate(hexes[0])),
				geometry.tile_center(_coordinate(hexes[1])),
			)
	push_error("unknown probe case kind: %s" % probe_case["kind"])
	return Vector2.ZERO

func _selected_hex(
	map: AonwMapView,
	geometry: AonwHexGridGeometry,
	point: Vector2,
) -> Variant:
	var coordinate := geometry.tile_at_point(point)
	return _hex(coordinate) if map.contains(coordinate) else null

func _normalized_uv(geometry: AonwHexGridGeometry, point: Vector2) -> Vector2:
	var area := geometry.bounds()
	return Vector2(
		(point.x - area.position.x) / area.size.x,
		(point.y - area.position.y) / area.size.y,
	)

func _midpoint(left: Vector2, right: Vector2) -> Vector2:
	return (left + right) * 0.5

func _coordinate(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func _vector(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _hex(coordinate: Vector2i) -> Array[int]:
	return [coordinate.x, coordinate.y]

func _point(point: Vector2) -> Array[float]:
	return [float(point.x), float(point.y)]

func _bounds(area: Rect2) -> Array[float]:
	return [
		float(area.position.x),
		float(area.position.y),
		float(area.size.x),
		float(area.size.y),
	]

func _strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result

func _read_object(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("cannot open probe scenario: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("probe scenario is not a JSON object: %s" % path)
		return {}
	return parsed

func _write_json(path: String, value: Dictionary) -> bool:
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		_fail("cannot create probe directory: %s" % error_string(error))
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("cannot write map render probe: %s" % path)
		return false
	file.store_string(JSON.stringify(value, "  ") + "\n")
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
