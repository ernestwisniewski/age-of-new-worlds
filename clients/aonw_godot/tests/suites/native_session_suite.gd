extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const MapViewMapper := preload("res://game/infrastructure/map/map_view_mapper.gd")
const JsonMapRepository := preload("res://game/infrastructure/map/json_map_repository.gd")
const NativeLocalSession := preload("res://game/infrastructure/engine/native_local_session.gd")
const TextDocumentReader := preload(
	"res://game/infrastructure/filesystem/text_document_reader.gd"
)
const ClientResponseDecoder := preload(
	"res://game/infrastructure/engine/client_response_decoder.gd"
)
const ClientReadModels := preload("res://game/application/session/client_read_models.gd")
const ClientFailure := preload("res://game/application/session/client_failure.gd")
const ClientReadModelDecoder := preload(
	"res://game/infrastructure/engine/client_read_model_decoder.gd"
)
const ClientCommandSchema := preload(
	"res://game/infrastructure/engine/client_command_schema.gd"
)
const LocalMatchSessionController := preload(
	"res://game/application/session/local_match_session_controller.gd"
)
const LocalMatchGateway := preload(
	"res://game/infrastructure/engine/local_match_gateway.gd"
)
const MAP_WORKBENCH_SCRIPT := (
	"res://editor/map_authoring/infrastructure/engine_logical_map_workbench.gd"
)

var _failures: Array[String]

class ForeignVersionTransport:
	extends RefCounted

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 4

	func request(_body: Dictionary) -> Dictionary:
		return {
			"apiVersion": 7,
			"outcome": {
				"status": "success",
				"response": {"type": "capabilities"},
			},
		}

class UnsupportedClientTransport:
	extends RefCounted

	var requested := false

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 6

	func request(_body: Dictionary) -> Dictionary:
		requested = true
		return {}

class MissingFeatureTransport:
	extends RefCounted

	var open_requested := false

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 7

	func request(body: Dictionary) -> Dictionary:
		if body.get("type", "") == "capabilities":
			return _success({
				"type": "capabilities",
				"features": ["matchStart", "snapshot", "moveUnit"],
			})
		open_requested = true
		return _success({"type": "sessionOpened", "stamp": _stamp(0)})

	func _success(response: Dictionary) -> Dictionary:
		return {
			"apiVersion": 7,
			"outcome": {"status": "success", "response": response},
		}

	func _stamp(revision: int) -> Dictionary:
		return {
			"revision": revision,
			"stateDigest": "state",
			"mapHash": "map",
			"rulesetHash": "ruleset",
		}

class MalformedSnapshotTransport:
	extends RefCounted

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 7

	func request(body: Dictionary) -> Dictionary:
		match body.get("type", ""):
			"capabilities":
				return _success({
					"type": "capabilities",
					"features": [
						"matchStart", "snapshot", "reachable", "routePlan", "moveUnit",
					],
				})
			"openSession":
				return _success({"type": "sessionOpened", "stamp": _stamp(7)})
		return _success({
			"type": "snapshot",
			"snapshot": {
				"stamp": _stamp(99), "turn": 1, "pendingAction": null, "units": "invalid",
			},
		})

	func _success(response: Dictionary) -> Dictionary:
		return {
			"apiVersion": 7,
			"outcome": {"status": "success", "response": response},
		}

	func _stamp(revision: int) -> Dictionary:
		return {
			"revision": revision,
			"stateDigest": "state",
			"mapHash": "map",
			"rulesetHash": "ruleset",
		}

class TypedGatewayTransport:
	extends RefCounted

	var executed_commands: Variant

	func _init(value: Variant = 3.0) -> void:
		executed_commands = value

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 7

	func request(body: Dictionary) -> Dictionary:
		match body.get("type", ""):
			"openSession":
				return _success({"type": "sessionOpened", "stamp": _stamp(0)})
			"closeSession":
				return _success({"type": "sessionClosed"})
			"capabilities":
				return _success({
					"type": "capabilities",
					"features": [
						"matchStart", "snapshot", "reachable", "routePlan", "moveUnit",
					],
				})
			"advanceAiTurn":
				return _success({
					"type": "aiTurnAdvanced",
					"stamp": _stamp(9),
					"actorPlayerId": body["actorPlayerId"],
					"executedCommands": executed_commands,
					"completedTurn": true,
				})
		return {}

	func _success(response: Dictionary) -> Dictionary:
		return {
			"apiVersion": 7,
			"outcome": {"status": "success", "response": response},
		}

	func _stamp(revision: int) -> Dictionary:
		return {
			"revision": revision,
			"stateDigest": "state",
			"mapHash": "map",
			"rulesetHash": "ruleset",
		}

class DeferredLifecycleGateway:
	extends RefCounted

	signal ai_response_released

	var open_calls := 0
	var close_calls := 0
	var close_succeeds := true

	func is_available() -> bool:
		return true

	func engine_features() -> Dictionary:
		var value := AonwClientReadModels.EngineFeatureSet.new()
		var features: Array[StringName] = [
			&"matchStart", &"snapshot", &"reachable", &"routePlan", &"moveUnit",
		]
		features.make_read_only()
		value.features = features
		return {"ok": true, "value": value}

	func open_session(
		_map_document: String,
		_scenario_document: String,
		_actor_player_id: String,
	) -> Dictionary:
		open_calls += 1
		return {"ok": true, "value": _stamp(1)}

	func close_session() -> Dictionary:
		close_calls += 1
		if close_succeeds:
			return {"ok": true}
		return ClientFailure.result("engine_worker_unavailable", "close failed")

	func advance_ai_turn_async(actor_player_id: String, _command_budget: int) -> Dictionary:
		await ai_response_released
		var result := AonwClientReadModels.AiTurnResult.new()
		result.stamp = _stamp(2)
		result.actor_player_id = actor_player_id
		result.executed_commands = 1
		result.completed_turn = true
		return {"ok": true, "value": result}

	func release_ai_response() -> void:
		ai_response_released.emit()

	func _stamp(revision: int) -> AonwClientReadModels.Stamp:
		var stamp := AonwClientReadModels.Stamp.new()
		stamp.revision = revision
		stamp.state_digest = "state-%d" % revision
		stamp.map_hash = "map"
		stamp.ruleset_hash = "ruleset"
		return stamp

class DeferredAsyncCloseGateway:
	extends DeferredLifecycleGateway

	signal close_response_released

	var async_close_calls := 0
	var background_cancellation_calls := 0

	func close_session_async() -> Dictionary:
		async_close_calls += 1
		await close_response_released
		return {"ok": true}

	func cancel_background_ai() -> void:
		background_cancellation_calls += 1

	func release_close_response() -> void:
		close_response_released.emit()

class DeferredAsyncOpenGateway:
	extends DeferredLifecycleGateway

	signal feature_response_released
	signal open_response_released

	var async_feature_calls := 0
	var async_open_calls := 0

	func engine_features_async() -> Dictionary:
		async_feature_calls += 1
		await feature_response_released
		return super.engine_features()

	func open_session_async(
		map_document: String,
		scenario_document: String,
		actor_player_id: String,
	) -> Dictionary:
		async_open_calls += 1
		await open_response_released
		return super.open_session(map_document, scenario_document, actor_player_id)

	func release_feature_response() -> void:
		feature_response_released.emit()

	func release_open_response() -> void:
		open_response_released.emit()

class ExtraEnvelopeFieldTransport:
	extends RefCounted

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 7

	func request(_body: Dictionary) -> Dictionary:
		return {
			"apiVersion": 7,
			"outcome": {
				"status": "success",
				"response": {"type": "capabilities", "features": []},
			},
			"futureField": true,
		}

class TrackingTransport:
	extends RefCounted

	var delegate: RefCounted
	var request_types: Array[String] = []
	var interactive_request_types: Array[String] = []

	func _init(value: RefCounted) -> void:
		delegate = value

	func is_available() -> bool:
		return bool(delegate.call("is_available"))

	func client_api_version() -> int:
		return int(delegate.call("client_api_version"))

	func request(body: Dictionary) -> Dictionary:
		request_types.append(str(body.get("type", "")))
		return delegate.call("request", body)

	func request_async(body: Dictionary) -> Dictionary:
		request_types.append(str(body.get("type", "")))
		return await delegate.call("request_async", body)

	func request_interactive_async(body: Dictionary) -> Dictionary:
		var request_type := str(body.get("type", ""))
		request_types.append(request_type)
		interactive_request_types.append(request_type)
		return await delegate.call("request_interactive_async", body)

class BuildIdentitySessionDouble:
	extends RefCounted

	var identity: String
	var requested := false

	func _init(value: String) -> void:
		identity = value

	func client_api_version() -> int:
		return 7

	func build_identity() -> String:
		return identity

	func request_json(_document: String) -> String:
		requested = true
		return ""

class NeverReadySessionDouble:
	extends RefCounted

	var cancelled_job_id := -1

	func client_api_version() -> int:
		return 7

	func build_identity() -> String:
		return "expected-build"

	func request_json_async(_document: String) -> int:
		return 41

	func is_response_ready(_job_id: int) -> bool:
		return false

	func cancel_request(job_id: int) -> bool:
		cancelled_job_id = job_id
		return true

class CoalescingSessionDouble:
	extends RefCounted

	var next_job_id := 0
	var cancelled_job_ids: Array[int] = []

	func client_api_version() -> int:
		return 7

	func build_identity() -> String:
		return "expected-build"

	func request_json_async(_document: String) -> int:
		next_job_id += 1
		return next_job_id

	func is_response_ready(job_id: int) -> bool:
		return job_id == 2

	func poll_response_json(job_id: int) -> String:
		if job_id != 2:
			return ""
		return JSON.stringify({
			"apiVersion": 7,
			"outcome": {
				"status": "success",
				"response": {"type": "capabilities", "features": []},
			},
		})

	func cancel_request(job_id: int) -> bool:
		cancelled_job_ids.append(job_id)
		return true

class DeferredMovementGateway:
	extends RefCounted

	signal movement_responses_released

	var reachable_calls := 0
	var route_calls := 0
	var cancellation_calls := 0

	func is_available() -> bool:
		return true

	func engine_features() -> Dictionary:
		var value := AonwClientReadModels.EngineFeatureSet.new()
		var features: Array[StringName] = [
			&"matchStart", &"snapshot", &"reachable", &"routePlan", &"moveUnit",
		]
		features.make_read_only()
		value.features = features
		return {"ok": true, "value": value}

	func open_session(
		_map_document: String,
		_scenario_document: String,
		_actor_player_id: String,
	) -> Dictionary:
		return {"ok": true, "value": _stamp(1)}

	func close_session() -> Dictionary:
		return {"ok": true}

	func reachable_async(_expected_revision: int, unit_id: String) -> Dictionary:
		reachable_calls += 1
		await movement_responses_released
		var value := AonwClientReadModels.ReachableView.new()
		value.stamp = _stamp(1)
		value.unit_id = unit_id
		value.available_movement_units = 12
		value.tiles = []
		return {"ok": true, "value": value}

	func route_plan_async(
		_expected_revision: int,
		unit_id: String,
		target: Vector2i,
	) -> Dictionary:
		route_calls += 1
		await movement_responses_released
		var value := AonwClientReadModels.RoutePlanView.new()
		value.stamp = _stamp(1)
		value.unit_id = unit_id
		value.target = target
		value.destination = target
		value.steps = []
		return {"ok": true, "value": value}

	func cancel_movement_queries() -> void:
		cancellation_calls += 1

	func release_movement_responses() -> void:
		movement_responses_released.emit()

	func _stamp(revision: int) -> AonwClientReadModels.Stamp:
		var stamp := AonwClientReadModels.Stamp.new()
		stamp.revision = revision
		stamp.state_digest = "state-%d" % revision
		stamp.map_hash = "map"
		stamp.ruleset_hash = "ruleset"
		return stamp

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_native_build_identity_precondition()
	_test_strict_document_boundary()
	await _test_native_engine_boundary()
	await _test_shared_client_contract()

func _test_native_build_identity_precondition() -> void:
	var matching_double := BuildIdentitySessionDouble.new("expected-build")
	var matching := NativeLocalSession.new(matching_double, "expected-build")
	_check(matching.is_available(), "Godot accepts the exact packaged native build identity")
	var mismatched_double := BuildIdentitySessionDouble.new("foreign-build")
	var mismatched := NativeLocalSession.new(mismatched_double, "expected-build")
	var response: Dictionary = mismatched.request({"type": "capabilities"})
	_check(
		not mismatched.is_available()
		and response.get("outcome", {}).get("error", {}).get("code", "")
		== "unsupported_native_build"
		and not mismatched_double.requested,
		"Godot rejects a foreign native build before the first request",
	)

func run_editor_tools(failures: Array[String]) -> void:
	_failures = failures
	_test_logical_map_workbench_boundary()

func _test_logical_map_workbench_boundary() -> void:
	var workbench_script := load(MAP_WORKBENCH_SCRIPT) as GDScript
	_check(workbench_script != null, "Godot workbench native adapter script loads")
	if workbench_script == null:
		return
	var workbench: RefCounted = workbench_script.new()
	var spec := JSON.stringify({
		"generatorId": "blank",
		"generatorVersion": 1,
		"mapId": "godot_generated",
		"cols": 5,
		"rows": 5,
		"defaultZoom": 1.0,
		"hexRadiusMeters": 100.0,
		"maxTerrainHeightMeters": 240.0,
		"seed": "42",
	})
	var first: Dictionary = workbench.call("generate_map", spec)
	var second: Dictionary = workbench.call("generate_map", spec)
	_check(first["ok"], "Godot workbench generates logical map documents through Rust")
	if not first["ok"]:
		return
	_check(first["package"] == second.get("package"), "Godot workbench generation is deterministic")
	var direct: Dictionary = workbench.call(
		"generate_blank_map",
		"godot_generated",
		5,
		5,
		1.0,
		100.0,
		240.0,
		"42",
	)
	_check(
		direct["ok"] and direct["package"] == first["package"],
		"Godot New Map fields are encoded as the same strict Rust generation spec",
	)
	var procedural: Dictionary = workbench.call(
		"generate_new_map",
		&"continental",
		"godot_continent",
		40,
		30,
		1.0,
		100.0,
		240.0,
		"42",
	)
	_check(procedural["ok"], "Godot can select the deterministic Rust procedural generator")
	if procedural["ok"]:
		var procedural_map: Dictionary = JSON.parse_string(
			procedural["package"]["mapDocument"]
		)
		var procedural_decorations: Dictionary = JSON.parse_string(
			procedural["package"]["generatedDecorationPlanDocument"]
		)
		var terrain_names := {}
		var resource_tiles := 0
		for procedural_tile in procedural_map["tiles"]:
			terrain_names[procedural_tile["terrainTags"][0]] = true
			resource_tiles += 1 if not procedural_tile["resources"].is_empty() else 0
		_check(
			terrain_names.size() >= 5
			and resource_tiles >= 20
			and procedural_decorations["placements"].size() >= 100,
			"procedural Rust output contains varied terrain, resources, and decorations",
		)
	var map: Dictionary = JSON.parse_string(first["package"]["mapDocument"])
	var authoring: Dictionary = JSON.parse_string(
		first["package"]["terrainAuthoringDocument"]
	)
	var decorations: Dictionary = JSON.parse_string(
		first["package"]["generatedDecorationPlanDocument"]
	)
	_check(
		map.get("mapName") == "godot_generated"
		and map.get("tiles", []).size() == 25
		and authoring.get("sourceMapContentHash") == first["package"]["mapContentHash"]
		and decorations.get("placements", [null]).is_empty(),
		"Rust owns canonical map, terrain profile and generated-decoration documents",
	)
	var update: Dictionary = workbench.call(
		"reconfigure_terrain_height",
		first["package"]["mapDocument"],
		first["package"]["terrainAuthoringDocument"],
		180.0,
	)
	_check(update["ok"], "Godot requests map height-scale changes through Rust")
	if update["ok"]:
		var updated_profile: Dictionary = JSON.parse_string(
			update["update"]["terrainAuthoringDocument"]
		)
		_check(
			updated_profile.get("maxTerrainHeightMeters") == 180.0
			and updated_profile.get("hexRadiusMeters") == 100.0,
			"Rust rebuilds height envelopes and preserves the map spatial scale",
		)
	var tile: Dictionary = workbench.call(
		"inspect_map_tile",
		first["package"]["mapDocument"],
		Vector2i(2, 3),
	)
	_check(
		tile["ok"]
		and tile["snapshot"]["tile"]["displayTerrain"] == "grassland"
		and tile["snapshot"]["terrainOptions"].size() == 14
		and tile["snapshot"]["resourceOptions"].size() == 29,
		"Godot inspects logical tile state and palettes through Rust",
	)
	var terrain_edit: Dictionary = workbench.call(
		"set_tile_terrain",
		first["package"]["mapDocument"],
		first["package"]["terrainAuthoringDocument"],
		Vector2i(2, 3),
		&"forest",
	)
	_check(
		terrain_edit["ok"]
		and terrain_edit["update"]["snapshot"]["tile"]["displayTerrain"] == "forest"
		and terrain_edit["update"]["mapContentHash"] != first["package"]["mapContentHash"],
		"Godot sends SetTileTerrain to the Engine workbench",
	)
	if terrain_edit["ok"]:
		var resource_ids: Array[StringName] = [&"iron", &"wheat"]
		var resources_edit: Dictionary = workbench.call(
			"set_tile_resources",
			terrain_edit["update"]["mapDocument"],
			terrain_edit["update"]["terrainAuthoringDocument"],
			Vector2i(2, 3),
			resource_ids,
		)
		_check(
			resources_edit["ok"]
			and resources_edit["update"]["snapshot"]["tile"]["resources"]
			== ["wheat", "iron"],
			"Godot sends SetTileResources to the Engine workbench",
		)
		if resources_edit["ok"]:
			var height_edit: Dictionary = workbench.call(
				"set_tile_height",
				resources_edit["update"]["mapDocument"],
				resources_edit["update"]["terrainAuthoringDocument"],
				Vector2i(2, 3),
				5,
			)
			_check(
				height_edit["ok"]
				and height_edit["update"]["snapshot"]["tile"]["height"] == 5,
				"Godot sends SetTileHeight to the Engine workbench",
			)
	var invalid: Dictionary = JSON.parse_string(spec)
	invalid["cols"] = 4
	_check(
		not workbench.call("generate_map", JSON.stringify(invalid))["ok"],
		"Rust rejects an invalid authored map specification",
	)

func _test_strict_document_boundary() -> void:
	var file := FileAccess.open(
		"res://assets/maps/aonw2_starter/map.json",
		FileAccess.READ,
	)
	_check(file != null, "content identifier fixture map opens")
	if file != null:
		var fixture: Dictionary = JSON.parse_string(file.get_as_text())
		for valid_identifier in ["a", "a_b-1", "aonw2_starter"]:
			var valid_map := fixture.duplicate(true)
			valid_map["mapName"] = valid_identifier
			var valid_result := _inspect_map(JSON.stringify(valid_map))
			_check(
				valid_result.get("outcome", {}).get("status", "") == "success",
				"lowercase ASCII content identifiers are accepted: %s" % valid_result,
			)
		for invalid_identifier in ["", "Uppercase", "ends_", "żagle"]:
			var invalid_map := fixture.duplicate(true)
			invalid_map["mapName"] = invalid_identifier
			_check(
				_inspect_map(JSON.stringify(invalid_map)).get("outcome", {}).get("status", "")
				== "failure",
				"invalid content identifiers are rejected",
			)
		var feature_first := fixture.duplicate(true)
		feature_first["tiles"][0]["terrainTags"] = []
		_check(
			_inspect_map(JSON.stringify(feature_first)).get("outcome", {}).get("status", "")
			== "failure",
			"tiles require authored terrain tags",
		)
		var mismatched_source := MapSource.new(
			"wrong_map_id",
			"res://assets/maps/aonw2_starter/map.json",
			"res://assets/maps/aonw2_starter",
			"test",
		)
		_check(
			not JsonMapRepository.new(
				NativeLocalSession.new(),
				TextDocumentReader.new(),
			).load_map(mismatched_source)["ok"],
			"source directory id must match mapName",
		)
	var raw := {
		"schemaVersion": 1,
		"gridLayout": "oddQFlatTop",
		"cols": 5,
		"rows": 5,
		"mapName": "strict_test",
		"objectives": [],
		"tiles": [],
	}
	var strict_result := _inspect_map(JSON.stringify(raw))
	_check(
		strict_result.get("outcome", {}).get("status", "") == "failure",
		"strict documents require defaultZoom",
	)

func _test_native_engine_boundary() -> void:
	var client := NativeLocalSession.new()
	_check(client.is_available(), "Rust GDExtension is loaded")
	if not client.is_available():
		return
	var file := FileAccess.open(
		"res://assets/maps/aonw2_starter/map.json",
		FileAccess.READ,
	)
	_check(file != null, "native boundary fixture map opens")
	if file == null:
		return
	var map_json := file.get_as_text()
	var validation := client.request({"type": "inspectMap", "mapDocument": map_json})
	_check(
		validation.get("outcome", {}).get("status", "") == "success",
		"Rust validates the strict map through inspectMap",
	)
	var map_view: Dictionary = validation.get("outcome", {}).get("response", {}).get("map", {})
	_check(
		map_view.get("contentHash", "")
		== "4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d",
		"Rust returns the shared logical content hash",
	)

	var transport := TrackingTransport.new(NativeLocalSession.new())
	var session := LocalMatchSessionController.new(LocalMatchGateway.new(transport))
	_check(session.is_available(), "native local session is registered")
	if not session.is_available():
		return
	var scenario_file := FileAccess.open(
		"res://assets/scenarios/aonw2_starter.json",
		FileAccess.READ,
	)
	_check(scenario_file != null, "native boundary scenario opens")
	if scenario_file == null:
		return
	var opened: Dictionary = session.open(
		map_json,
		scenario_file.get_as_text(),
		"preview-player",
	)
	_check(opened["ok"], "native local scenario session opens")
	var snapshot: Dictionary = session.snapshot()
	_check(
			snapshot["ok"]
			and snapshot["value"].turn == 1
			and snapshot["value"].units.size() == 1
		and snapshot["value"].units[0].id == "preview-commander"
		and snapshot["value"].units[0].coordinate == Vector2i(2, 1)
		and snapshot["value"].stamp.map_hash == map_view.get("contentHash", ""),
		"native snapshot owns the scenario unit view",
	)
	var reachable: Dictionary = session.reachable("preview-commander")
	_check(
		reachable["ok"] and not reachable["value"].tiles.is_empty(),
		"native session returns reachable hexes",
	)
	var route: Dictionary = session.route_plan("preview-commander", Vector2i(2, 2))
	_check(route["ok"] and route["value"].steps.size() > 1, "native route is planned")
	var moved: Dictionary = await session.move_unit_async(
		"preview-commander",
		Vector2i(2, 2),
	)
	_check(
		moved["ok"]
		and moved["value"].accepted
		and moved["value"].stamp.revision == 1
		and moved["value"].evidence.steps[-1].coordinate.y == 2,
		"native session applies a revision-bound move",
	)
	var stale_envelope := transport.request({
		"type": "dispatch",
		"command": {
			"type": "moveUnit",
			"expectedRevision": 0,
			"unitId": "preview-commander",
			"target": {"col": 2, "row": 1},
		},
	})
	var stale_body: Dictionary = stale_envelope.get("outcome", {}).get("response", {})
	var stale_result := ClientReadModelDecoder.decode_command(stale_body.get("result", {}))
	_check(
		stale_result != null
		and not stale_result.accepted
		and stale_result.rejection == &"stale_revision",
		"native Rust rejection maps to the shared Godot rejection code",
	)
	var skipped: Dictionary = await session.skip_unit_turn_async("preview-commander")
	_check(
		skipped["ok"]
		and skipped["value"].accepted
		and skipped["value"].stamp.revision == 2
		and skipped["value"].patch.upserted_units[0].movement_units == 0
		and skipped["value"].patch.pending_action.kind == &"unitTurnSkip",
		"native session skips a unit turn",
	)
	var cancelled: Dictionary = await session.cancel_unit_action_async("preview-commander")
	_check(
		cancelled["ok"]
		and cancelled["value"].accepted
		and cancelled["value"].stamp.revision == 3
		and cancelled["value"].patch.pending_action == null,
		"native session cancels a unit action",
	)
	var fortified: Dictionary = await session.fortify_unit_async("preview-commander")
	_check(
		fortified["ok"]
		and fortified["value"].accepted
		and fortified["value"].stamp.revision == 4
		and fortified["value"].patch.upserted_units[0].posture == "fortified",
		"native session fortifies an idle unit",
	)
	var ended: Dictionary = await session.end_turn_async()
	_check(
		ended["ok"]
		and ended["value"].accepted
		and ended["value"].stamp.revision == 5
		and ended["value"].patch.turn == 2
		and ended["value"].patch.turn_lifecycle == null,
		"native session advances the solo turn on the interactive async lane",
	)
	var saved: Dictionary = session.save_game()
	_check(
		saved["ok"] and not saved["value"].is_empty(),
		"native session exports a canonical save",
	)
	var replay: Dictionary = session.replay_log()
	_check(
		replay["ok"] and not replay["value"].is_empty(),
		"native session exports a deterministic replay",
	)
	var verified: Dictionary = session.verify_replay(map_json, replay["value"])
	_check(
		verified["ok"] and verified["value"].entry_count == 6,
		"native session verifies replay results in Rust",
	)
	await session.close_async()
	var restored: Dictionary = session.open_save(map_json, saved["value"])
	_check(
		restored["ok"] and restored["value"].revision == 5,
		"native session restores a canonical save",
	)
	_check(
		session.get("_gateway").get("_transport") == transport
		and transport.interactive_request_types == [
			"dispatch", "dispatch", "dispatch", "dispatch", "dispatch", "closeSession",
		]
		and transport.request_types == [
			"capabilities",
			"openSession",
			"snapshot",
			"query",
			"query",
			"dispatch",
			"dispatch",
			"dispatch",
			"dispatch",
			"dispatch",
			"dispatch",
			"exportSave",
			"exportReplay",
			"verifyReplay",
			"closeSession",
			"capabilities",
			"openSave",
		],
		"one Godot session keeps one Rust transport for its complete lifecycle",
	)
	await session.close_async()
	_test_packaged_scenario_sessions()

func _test_packaged_scenario_sessions() -> void:
	for map_id in ["dravonia", "myranth", "terenos", "verdantia"]:
		var map_file := FileAccess.open(
			"res://assets/maps/%s/map.json" % map_id,
			FileAccess.READ,
		)
		var scenario_file := FileAccess.open(
			"res://assets/scenarios/%s.json" % map_id,
			FileAccess.READ,
		)
		var manifest_file := FileAccess.open(
			"res://assets/maps/%s/map_texture_manifest.json" % map_id,
			FileAccess.READ,
		)
		_check(
			map_file != null and scenario_file != null and manifest_file != null,
			"%s runtime documents open" % map_id,
		)
		if map_file == null or scenario_file == null or manifest_file == null:
			continue
		var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
		var controller := LocalMatchSessionController.new(
			LocalMatchGateway.new(NativeLocalSession.new())
		)
		var opened: Dictionary = controller.open(
			map_file.get_as_text(),
			scenario_file.get_as_text(),
			"preview-player",
		)
		var snapshot: Dictionary = controller.snapshot() if opened["ok"] else opened
		_check(
			opened["ok"]
			and snapshot["ok"]
			and snapshot["value"].units.size() == 1
			and snapshot["value"].stamp.map_hash == manifest["mapContentHash"],
			"%s packaged scenario opens through the native engine" % map_id,
		)
		controller.close()

func _test_shared_client_contract() -> void:
	var inspect_request_file := FileAccess.open(
		"res://../../tests/fixtures/client_protocol/inspect_map_request.json",
		FileAccess.READ,
	)
	_check(inspect_request_file != null, "shared inspectMap request golden opens in Godot")
	if inspect_request_file != null:
		var inspect_request: Variant = JSON.parse_string(inspect_request_file.get_as_text())
		_check(
			inspect_request is Dictionary
			and inspect_request["apiVersion"] == 7
			and inspect_request["request"]["type"] == "inspectMap",
			"Godot consumes the shared inspectMap request contract",
		)

	var request_file := FileAccess.open(
		"res://../../tests/fixtures/client_protocol/move_unit_request.json",
		FileAccess.READ,
	)
	_check(request_file != null, "shared client request golden opens in Godot")
	if request_file != null:
		var request: Variant = JSON.parse_string(request_file.get_as_text())
		_check(
			request is Dictionary
			and request["apiVersion"] == 7
			and request["request"]["command"]["type"] == "moveUnit",
			"Godot consumes the shared move request contract",
		)

	var response_file := FileAccess.open(
		"res://../../tests/fixtures/client_protocol/command_result_response.json",
		FileAccess.READ,
	)
	_check(response_file != null, "shared client response golden opens in Godot")
	if response_file != null:
		var decoder := ClientResponseDecoder.new(7)
		var decoded := decoder.decode(response_file.get_as_text())
		_check(
			decoded.get("outcome", {}).get("status", "") == "success",
			"Godot consumes the shared command response contract",
		)
		var body: Dictionary = decoded["outcome"]["response"]
		var command: AonwClientReadModels.CommandResult = (
			ClientReadModelDecoder.decode_command(body.get("result", {}))
		)
		_check(
			command != null
			and command.patch.upserted_units[0].kind == "commander"
			and command.evidence.steps[-1].coordinate == Vector2i(3, 4),
			"Godot maps the shared response into typed client read models",
		)
		var rejected_result: Dictionary = body["result"].duplicate(true)
		rejected_result["outcome"] = {"status": "rejected", "code": "stale_revision"}
		rejected_result["events"] = []
		rejected_result["evidence"] = null
		var rejected := ClientReadModelDecoder.decode_command(rejected_result)
		_check(
			rejected != null and rejected.rejection == &"stale_revision",
			"Godot maps a shared command rejection to a validated code",
		)
		rejected_result["outcome"]["code"] = "match_finished"
		_check(
			ClientReadModelDecoder.decode_command(rejected_result) != null,
			"Godot accepts the global terminal-match rejection",
		)
		rejected_result["outcome"]["code"] = "future_rejection"
		_check(
			ClientReadModelDecoder.decode_command(rejected_result) == null,
			"Godot rejects an unknown command rejection code",
		)
		var turn_result: Dictionary = body["result"].duplicate(true)
		turn_result["events"] = [{"type": "turnEnded", "playerId": "player-1"}]
		turn_result["evidence"] = {
			"type": "turnKernel",
			"processors": ["submission", "lifecycle"],
			"foundedCityIds": [],
			"combatExecutions": [],
			"resetUnitIds": [],
			"movementExecutions": [],
			"invalidatedOrderUnitIds": [],
			"finishedAutoExploreUnitIds": [],
		}
		var turn_command := ClientReadModelDecoder.decode_command(turn_result)
		_check(
			turn_command != null
			and turn_command.events[0].kind == &"turnEnded"
			and turn_command.evidence.processors == [&"submission", &"lifecycle"],
			"Godot decodes recipient-safe turn events and evidence",
		)
		var invalid_version := decoder.decode(
			'{"apiVersion":"7","outcome":{"status":"success","response":{}}}'
		)
		_check(
			invalid_version.get("outcome", {}).get("status", "") == "failure",
			"Godot rejects coercible client API versions",
		)

	var rejection_codes_file := FileAccess.open(
		"res://../../tests/fixtures/client_protocol/command_rejection_codes.json",
		FileAccess.READ,
	)
	_check(rejection_codes_file != null, "shared command rejection-code fixture opens in Godot")
	if rejection_codes_file != null:
		var rejection_codes: Dictionary = JSON.parse_string(rejection_codes_file.get_as_text())
		_check(
			rejection_codes.get("codes") == Array(ClientCommandSchema.REJECTION_CODES),
			"Godot command rejection codes match the shared contract fixture",
		)

	var map_response_file := FileAccess.open(
		"res://../../tests/fixtures/client_protocol/map_inspected_response.json",
		FileAccess.READ,
	)
	_check(map_response_file != null, "shared map response golden opens in Godot")
	if map_response_file != null:
		var decoded_map := ClientResponseDecoder.new(7).decode(map_response_file.get_as_text())
		var map_body: Dictionary = decoded_map.get("outcome", {}).get("response", {})
		var mapped := MapViewMapper.new().from_wire(map_body.get("map"))
		_check(
			map_body.get("type", "") == "mapInspected"
			and mapped["ok"]
			and mapped["value"].tile_at(Vector2i.ZERO).display_terrain() == &"forest"
			and mapped["value"].contains(Vector2i.ZERO)
			and not mapped["value"].contains(Vector2i(1, 0)),
			"Godot maps the shared response into its map read model",
		)
		var foreign_map: Dictionary = map_body["map"].duplicate(true)
		foreign_map["tiles"][0]["unknown"] = true
		_check(
			not MapViewMapper.new().from_wire(foreign_map)["ok"],
			"Godot rejects foreign map response fields",
		)
		var duplicate_tiles: Dictionary = map_body["map"].duplicate(true)
		duplicate_tiles["tiles"].append(duplicate_tiles["tiles"][0].duplicate(true))
		_check(
			not MapViewMapper.new().from_wire(duplicate_tiles)["ok"],
			"Godot rejects duplicated map tile coordinates",
		)
		var unknown_terrain: Dictionary = map_body["map"].duplicate(true)
		unknown_terrain["tiles"][0]["displayTerrain"] = "futureTerrain"
		_check(
			not MapViewMapper.new().from_wire(unknown_terrain)["ok"],
			"Godot rejects unknown map enum values",
		)
		var outside_objective: Dictionary = map_body["map"].duplicate(true)
		outside_objective["objectives"][0]["coordinate"]["col"] = 1
		_check(
			not MapViewMapper.new().from_wire(outside_objective)["ok"],
			"Godot rejects objectives outside the validated tile coverage",
		)

	var snapshot_stamp := {
		"revision": 0,
		"stateDigest": "b".repeat(64),
		"mapHash": "a".repeat(64),
		"rulesetHash": "c".repeat(64),
	}
	var unit := {
		"id": "unit-a",
		"ownerPlayerId": "player-1",
		"kind": "commander",
		"name": "Commander",
		"coordinate": {"col": 0, "row": 0},
		"movementUnits": 12,
		"posture": "active",
		"hitPoints": null,
		"carriedArtifactId": null,
		"ownedDetails": null,
	}
	var turn_lifecycle := {
		"ownState": "active",
		"ownSubmitted": false,
		"requiredSubmissionCount": 1,
		"submittedCount": 0,
	}
	var game_outcome := {
		"condition": "ongoing",
		"winnerPlayerId": null,
		"scoreByPlayerId": {},
	}
	var diplomacy := {
		"relations": [],
		"proposals": [],
		"messages": [],
		"resourceTradeAgreements": [],
	}
	var snapshot_document := {
		"stamp": snapshot_stamp,
		"turn": 7,
		"outcome": game_outcome,
		"turnLifecycle": turn_lifecycle,
		"pendingAction": {
			"type": "workerActionSelection",
			"unitId": "unit-a",
			"improvement": "farm",
		},
		"cityFoundingDraft": null,
		"diplomacy": diplomacy,
		"units": [unit],
		"cities": [],
		"artifacts": [],
		"fieldImprovements": [],
		"roads": [],
	}
	var decoded_snapshot := ClientReadModelDecoder.decode_snapshot(snapshot_document)
	_check(
		decoded_snapshot != null
		and decoded_snapshot.turn == 7
		and decoded_snapshot.outcome.condition == &"ongoing"
		and decoded_snapshot.pending_action.kind == &"workerActionSelection"
		and decoded_snapshot.pending_action.improvement == &"farm"
		and decoded_snapshot.units[0].kind == "commander",
		"Godot maps the complete recipient-safe snapshot",
	)
	var invalid_pending: Dictionary = snapshot_document.duplicate(true)
	invalid_pending["pendingAction"]["improvement"] = "futureImprovement"
	_check(
		ClientReadModelDecoder.decode_snapshot(invalid_pending) == null,
		"Godot rejects an unknown pending-action enum value",
	)
	var invalid_turn: Dictionary = snapshot_document.duplicate(true)
	invalid_turn["turn"] = 0
	invalid_turn["pendingAction"] = null
	_check(
		ClientReadModelDecoder.decode_snapshot(invalid_turn) == null,
		"Godot rejects a non-positive authoritative turn",
	)
	var unknown_unit: Dictionary = unit.duplicate(true)
	unknown_unit["kind"] = "futureUnit"
	var invalid_unit: Dictionary = snapshot_document.duplicate(true)
	invalid_unit["pendingAction"] = null
	invalid_unit["units"] = [unknown_unit]
	_check(
		ClientReadModelDecoder.decode_snapshot(invalid_unit) == null,
		"Godot rejects unknown unit enum values",
	)
	var second_unit: Dictionary = unit.duplicate(true)
	second_unit["id"] = "unit-b"
	var unstable_units: Dictionary = snapshot_document.duplicate(true)
	unstable_units["pendingAction"] = null
	unstable_units["units"] = [second_unit, unit]
	_check(
		ClientReadModelDecoder.decode_snapshot(unstable_units) == null,
		"Godot rejects an unstable snapshot unit order",
	)

	var foreign := LocalMatchSessionController.new(
		LocalMatchGateway.new(ForeignVersionTransport.new()),
	).engine_features()
	_check(
		not foreign["ok"]
		and foreign["code"] == "unsupported_client_api"
		and _has_failure_kind(foreign, ClientFailure.Kind.COMPATIBILITY),
		"Godot rejects foreign client API responses",
	)

	var unsupported_transport := UnsupportedClientTransport.new()
	var unsupported := LocalMatchSessionController.new(
		LocalMatchGateway.new(unsupported_transport),
	).engine_features()
	_check(
		not unsupported["ok"]
		and unsupported["code"] == "unsupported_client_api"
		and not unsupported_transport.requested,
		"Godot rejects an incompatible transport before dispatch",
	)
	var missing_feature_transport := MissingFeatureTransport.new()
	var missing_features := LocalMatchSessionController.new(
		LocalMatchGateway.new(missing_feature_transport),
	).open("map", "scenario", "player")
	_check(
		not missing_features["ok"]
		and missing_features["code"] == "unsupported_engine_features"
		and _has_failure_kind(missing_features, ClientFailure.Kind.COMPATIBILITY)
		and not missing_feature_transport.open_requested,
		"Godot negotiates required engine features before opening a session",
	)

	var malformed_controller := LocalMatchSessionController.new(
		LocalMatchGateway.new(MalformedSnapshotTransport.new()),
	)
	var opened := malformed_controller.open("map", "scenario", "player")
	var malformed := malformed_controller.snapshot()
	_check(
		opened["ok"]
		and not malformed["ok"]
		and malformed_controller.revision() == 7,
		"Godot updates revision only after complete typed response validation",
	)

	var typed_controller := LocalMatchSessionController.new(
		LocalMatchGateway.new(TypedGatewayTransport.new()),
	)
	var typed_opened := typed_controller.open("map", "scenario", "player")
	var engine_features: Dictionary = typed_controller.engine_features()
	var ai_turn: Dictionary = typed_controller.advance_ai_turn("ai-player", 4)
	_check(
		typed_opened["ok"]
		and engine_features["ok"]
		and engine_features["value"] is AonwClientReadModels.EngineFeatureSet
		and engine_features["value"].supports(&"snapshot")
		and not engine_features["value"].supports(&"workers")
		and ai_turn["ok"]
		and ai_turn["value"] is AonwClientReadModels.AiTurnResult
		and ai_turn["value"].actor_player_id == "ai-player"
		and ai_turn["value"].executed_commands == 3
		and ai_turn["value"].completed_turn
		and typed_controller.revision() == 9,
		"Godot exposes negotiated features and AI envelopes as typed application results",
	)
	for invalid_integer: Variant in [3.5, "3"]:
		var invalid_controller := LocalMatchSessionController.new(
			LocalMatchGateway.new(TypedGatewayTransport.new(invalid_integer)),
		)
		invalid_controller.open("map", "scenario", "player")
		var invalid_ai_turn := invalid_controller.advance_ai_turn("ai-player", 4)
		_check(
			not invalid_ai_turn["ok"]
			and invalid_ai_turn["code"] == "invalid_client_response",
			"Godot rejects non-integral or coercible AI counters at the gateway",
		)

	var extra_envelope := LocalMatchSessionController.new(
		LocalMatchGateway.new(ExtraEnvelopeFieldTransport.new()),
	).engine_features()
	_check(
		not extra_envelope["ok"]
		and extra_envelope["code"] == "invalid_client_response"
		and _has_failure_kind(extra_envelope, ClientFailure.Kind.PROTOCOL),
		"Godot rejects unknown client envelope fields at the infrastructure boundary",
	)

	var deferred_gateway := DeferredLifecycleGateway.new()
	var lifecycle_controller := LocalMatchSessionController.new(deferred_gateway)
	var initial_close: Dictionary = lifecycle_controller.close()
	var closed_snapshot: Dictionary = lifecycle_controller.snapshot()
	var lifecycle_opened := lifecycle_controller.open("map", "scenario", "player")
	var duplicate_open := lifecycle_controller.open("map", "scenario", "player")
	_close_and_release_deferred_response(lifecycle_controller, deferred_gateway)
	var late_ai_turn: Dictionary = await lifecycle_controller.advance_ai_turn_async(
		"ai-player",
		4,
	)
	var repeated_close: Dictionary = lifecycle_controller.close()
	var reopened := lifecycle_controller.open("map", "scenario", "player")
	_check(
		initial_close["ok"]
		and not closed_snapshot["ok"]
		and closed_snapshot["code"] == "session_not_open"
		and _has_failure_kind(closed_snapshot, ClientFailure.Kind.LIFECYCLE)
		and lifecycle_opened["ok"]
		and not duplicate_open["ok"]
		and duplicate_open["code"] == "session_already_open"
		and _has_failure_kind(duplicate_open, ClientFailure.Kind.LIFECYCLE)
		and not late_ai_turn["ok"]
		and late_ai_turn["code"] == "stale_session_response"
		and _has_failure_kind(late_ai_turn, ClientFailure.Kind.STALE_RESPONSE)
		and repeated_close["ok"]
		and reopened["ok"]
		and lifecycle_controller.lifecycle()
		== AonwLocalMatchSessionController.Lifecycle.OPEN
		and lifecycle_controller.generation() == 3
		and lifecycle_controller.revision() == 1
		and deferred_gateway.open_calls == 2
		and deferred_gateway.close_calls == 1,
		"Godot lifecycle rejects duplicate open, ignores late replies, and reopens cleanly",
	)
	lifecycle_controller.close()
	var failed_close_gateway := DeferredLifecycleGateway.new()
	var failed_close_controller := LocalMatchSessionController.new(failed_close_gateway)
	failed_close_controller.open("map", "scenario", "player")
	failed_close_gateway.close_succeeds = false
	var failed_close: Dictionary = failed_close_controller.close()
	_check(
		not failed_close["ok"]
		and _has_failure_kind(failed_close, ClientFailure.Kind.TRANSPORT)
		and failed_close_controller.is_open()
		and failed_close_controller.revision() == 1,
		"Godot lifecycle remains open when the engine does not confirm close",
	)
	failed_close_gateway.close_succeeds = true
	failed_close_controller.close()
	var async_open_gateway := DeferredAsyncOpenGateway.new()
	var async_open_controller := LocalMatchSessionController.new(async_open_gateway)
	var async_open_result := {}
	_capture_async_open(async_open_controller, async_open_result)
	await Engine.get_main_loop().process_frame
	_check(
		async_open_result.is_empty()
		and async_open_controller.lifecycle()
		== AonwLocalMatchSessionController.Lifecycle.OPENING
		and async_open_gateway.async_feature_calls == 1
		and async_open_gateway.async_open_calls == 0,
		"Godot negotiates engine features without blocking the opening frame",
	)
	var opening_duplicate := async_open_controller.open("map", "scenario", "player")
	async_open_gateway.release_feature_response()
	await Engine.get_main_loop().process_frame
	_check(
		not opening_duplicate["ok"]
		and opening_duplicate["code"] == "session_already_open"
		and async_open_result.is_empty()
		and async_open_gateway.async_open_calls == 1,
		"Godot keeps one opening generation while the native start is pending",
	)
	async_open_gateway.release_open_response()
	await Engine.get_main_loop().process_frame
	var completed_async_open: Dictionary = async_open_result.get("value", {})
	_check(
		completed_async_open.get("ok", false)
		and async_open_controller.is_open()
		and async_open_controller.revision() == 1,
		"Godot publishes an async session only after the native start is validated",
	)
	async_open_controller.close()
	var abandoned_open_gateway := DeferredAsyncOpenGateway.new()
	var abandoned_open_controller := LocalMatchSessionController.new(abandoned_open_gateway)
	var abandoned_open_result := {}
	_capture_async_open(abandoned_open_controller, abandoned_open_result)
	await Engine.get_main_loop().process_frame
	abandoned_open_controller.close()
	abandoned_open_gateway.release_feature_response()
	await Engine.get_main_loop().process_frame
	var stale_open: Dictionary = abandoned_open_result.get("value", {})
	_check(
		not stale_open.get("ok", true)
		and stale_open.get("code", "") == "stale_session_response"
		and abandoned_open_gateway.async_open_calls == 0
		and not abandoned_open_controller.is_open(),
		"Godot discards an async open whose lifecycle generation was closed",
	)
	var async_close_gateway := DeferredAsyncCloseGateway.new()
	var async_close_controller := LocalMatchSessionController.new(async_close_gateway)
	async_close_controller.open("map", "scenario", "player")
	var async_close_result := {}
	_capture_async_close(async_close_controller, async_close_result)
	await Engine.get_main_loop().process_frame
	_check(
		async_close_result.is_empty()
		and async_close_controller.lifecycle()
		== AonwLocalMatchSessionController.Lifecycle.CLOSING
		and async_close_gateway.async_close_calls == 1
		and async_close_gateway.background_cancellation_calls == 1,
		"Godot begins close by cancelling background work without blocking a frame",
	)
	async_close_gateway.release_close_response()
	await Engine.get_main_loop().process_frame
	var completed_async_close: Dictionary = async_close_result.get("value", {})
	_check(
		completed_async_close.get("ok", false)
		and async_close_controller.lifecycle()
		== AonwLocalMatchSessionController.Lifecycle.CLOSED
		and async_close_controller.revision() == 0,
		"Godot completes async close only after the engine acknowledges it",
	)
	var never_ready := NeverReadySessionDouble.new()
	var timeout_session := NativeLocalSession.new(never_ready, "expected-build")
	var timeout_envelope: Dictionary = await timeout_session.request_async(
		{"type": "capabilities"},
		0,
	)
	_check(
		timeout_envelope.get("outcome", {}).get("error", {}).get("code", "")
		== "client_timeout"
		and never_ready.cancelled_job_id == 41
		and _has_failure_kind(
			ClientFailure.result("client_timeout", "request timed out"),
			ClientFailure.Kind.TIMEOUT,
		),
		"Godot times out and physically cancels an abandoned native job",
	)
	var coalescing_double := CoalescingSessionDouble.new()
	var coalescing_session := NativeLocalSession.new(
		coalescing_double,
		"expected-build",
	)
	var replaced_result := {}
	_capture_coalesced_request(coalescing_session, replaced_result)
	await Engine.get_main_loop().process_frame
	var latest_envelope: Dictionary = await coalescing_session.request_coalesced_async(
		{"type": "capabilities"},
		&"movement_query",
		1000,
	)
	await Engine.get_main_loop().process_frame
	var replaced_envelope: Dictionary = replaced_result.get("value", {})
	_check(
		latest_envelope.get("outcome", {}).get("status", "") == "success"
		and replaced_envelope.get("outcome", {}).get("error", {}).get("code", "")
		== "stale_session_response"
		and 1 in coalescing_double.cancelled_job_ids
		and coalescing_session.get("_coalesced_jobs").is_empty(),
		"Godot coalesces movement work and exposes only the latest native response",
	)
	var movement_gateway := DeferredMovementGateway.new()
	var movement_controller := LocalMatchSessionController.new(movement_gateway)
	movement_controller.open("map", "scenario", "player")
	var newest_route_result := {}
	_start_deferred_route(movement_controller, newest_route_result)
	_release_deferred_movement_responses(movement_gateway)
	var superseded_reachable: Dictionary = await movement_controller.reachable_async(
		"unit-a",
	)
	await Engine.get_main_loop().process_frame
	var newest_route: Dictionary = newest_route_result.get("value", {})
	_check(
		not superseded_reachable["ok"]
		and superseded_reachable["code"] == "stale_session_response"
		and _has_failure_kind(superseded_reachable, ClientFailure.Kind.STALE_RESPONSE)
		and newest_route.get("ok", false)
		and newest_route.get("value") is AonwClientReadModels.RoutePlanView
		and movement_controller.revision() == 1
		and movement_gateway.reachable_calls == 1
		and movement_gateway.route_calls == 1,
		"Godot correlation discards an older reachable reply and keeps the newest route",
	)
	movement_controller.close()
	_check(
		_has_failure_kind(
			ClientFailure.result("unit_not_found", "authoritative rejection"),
			ClientFailure.Kind.ENGINE,
		),
		"Godot preserves authoritative engine failures outside closed client categories",
	)

func _close_and_release_deferred_response(
	controller: AonwLocalMatchSessionController,
	gateway: DeferredLifecycleGateway,
) -> void:
	await Engine.get_main_loop().process_frame
	controller.close()
	gateway.release_ai_response()

func _capture_coalesced_request(
	session: AonwNativeLocalSession,
	result: Dictionary,
) -> void:
	result["value"] = await session.request_coalesced_async(
		{"type": "capabilities"},
		&"movement_query",
		1000,
	)

func _capture_async_close(
	controller: AonwLocalMatchSessionController,
	result: Dictionary,
) -> void:
	result["value"] = await controller.close_async()

func _capture_async_open(
	controller: AonwLocalMatchSessionController,
	result: Dictionary,
) -> void:
	result["value"] = await controller.open_async("map", "scenario", "player")

func _start_deferred_route(
	controller: AonwLocalMatchSessionController,
	result: Dictionary,
) -> void:
	await Engine.get_main_loop().process_frame
	result["value"] = await controller.route_plan_async(
		"unit-a",
		Vector2i(2, 2),
	)

func _release_deferred_movement_responses(gateway: DeferredMovementGateway) -> void:
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	gateway.release_movement_responses()

func _has_failure_kind(result: Dictionary, expected_kind: int) -> bool:
	var failure: Variant = result.get("failure")
	return (
		failure is RefCounted
		and failure.get_script() == ClientFailure
		and int(failure.get("kind")) == expected_kind
	)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _inspect_map(map_document: String) -> Dictionary:
	return NativeLocalSession.new().request({
		"type": "inspectMap",
		"mapDocument": map_document,
	})
