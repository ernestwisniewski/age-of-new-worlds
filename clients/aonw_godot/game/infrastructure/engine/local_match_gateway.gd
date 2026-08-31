class_name AonwLocalMatchGateway
extends RefCounted

const ReadModelDecoder := preload(
	"res://game/infrastructure/engine/client_read_model_decoder.gd"
)
const ClientResponseDecoder := preload(
	"res://game/infrastructure/engine/client_response_decoder.gd"
)
const ReadModels := preload(
	"res://game/application/session/client_read_models.gd"
)
const ClientFailure := preload("res://game/application/session/client_failure.gd")
const ClientProtocol := preload(
	"res://game/infrastructure/engine/client_protocol.gd"
)
const ENGINE_FEATURE_NAMES := [
	"inspectMap", "matchStart", "actorHandoff", "aiTurns", "snapshot",
	"reachable", "routePlan", "moveUnit", "unitActions", "turnKernel",
	"movementLogistics", "combat", "cities", "workers", "production",
	"research", "diplomacy", "artifacts", "saveGame", "replayVerification",
	"replayPlayback",
]
const MOVEMENT_QUERY_KEY := &"movement_query"
const BACKGROUND_AI_KEY := &"background_ai"

var _transport: RefCounted
var _response_decoder: AonwClientResponseDecoder

func _init(transport: RefCounted) -> void:
	assert(transport != null, "Client transport is required")
	_transport = transport
	_response_decoder = ClientResponseDecoder.new(ClientProtocol.API_VERSION)

func is_available() -> bool:
	return bool(_transport.call("is_available"))

func engine_features() -> Dictionary:
	return _decode_engine_features(_extract(
		_execute({"type": "capabilities"}, "capabilities"),
		"features",
	))

func engine_features_async() -> Dictionary:
	if not _transport.has_method("request_async"):
		return engine_features()
	return _decode_engine_features(_extract(
		await _execute_async({"type": "capabilities"}, "capabilities", &"", true),
		"features",
	))

func _decode_engine_features(extracted: Dictionary) -> Dictionary:
	if not extracted["ok"]:
		return extracted
	var raw_features: Variant = extracted["value"]
	if not raw_features is Array:
		return _failure("invalid_client_response", "Engine returned invalid capabilities")
	var features: Array[StringName] = []
	var seen := {}
	for raw_feature in raw_features:
		if (
			not raw_feature is String
			or raw_feature not in ENGINE_FEATURE_NAMES
			or seen.has(raw_feature)
		):
			return _failure("invalid_client_response", "Engine returned invalid capabilities")
		seen[raw_feature] = true
		features.append(StringName(raw_feature))
	features.make_read_only()
	var result := ReadModels.EngineFeatureSet.new()
	result.features = features
	return {"ok": true, "value": result}

func open_session(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
) -> Dictionary:
	return _extract_stamp(_execute({
		"type": "openSession",
		"mapDocument": map_document,
		"scenarioDocument": scenario_document,
		"actorPlayerId": actor_player_id,
	}, "sessionOpened"), "stamp")

func open_session_async(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
) -> Dictionary:
	if not _transport.has_method("request_async"):
		return open_session(map_document, scenario_document, actor_player_id)
	return _extract_stamp(await _execute_async({
		"type": "openSession",
		"mapDocument": map_document,
		"scenarioDocument": scenario_document,
		"actorPlayerId": actor_player_id,
	}, "sessionOpened", &"", true), "stamp")

func start_match(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
	match_identity: Dictionary,
	fog_enabled: bool,
) -> Dictionary:
	return _extract_stamp(_execute({
		"type": "startMatch",
		"mapDocument": map_document,
		"scenarioDocument": scenario_document,
		"actorPlayerId": actor_player_id,
		"matchIdentity": match_identity,
		"fogMode": "enabled" if fog_enabled else "disabled",
	}, "sessionOpened"), "stamp")

func start_match_async(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
	match_identity: Dictionary,
	fog_enabled: bool,
) -> Dictionary:
	if not _transport.has_method("request_async"):
		return start_match(
			map_document,
			scenario_document,
			actor_player_id,
			match_identity,
			fog_enabled,
		)
	return _extract_stamp(await _execute_async({
		"type": "startMatch",
		"mapDocument": map_document,
		"scenarioDocument": scenario_document,
		"actorPlayerId": actor_player_id,
		"matchIdentity": match_identity,
		"fogMode": "enabled" if fog_enabled else "disabled",
	}, "sessionOpened", &"", true), "stamp")

func handoff_actor(actor_player_id: String) -> Dictionary:
	return _extract_stamp(_execute({
		"type": "handoffActor",
		"actorPlayerId": actor_player_id,
	}, "actorHandedOff"), "stamp")

func handoff_actor_async(actor_player_id: String) -> Dictionary:
	if not _transport.has_method("request_async"):
		return handoff_actor(actor_player_id)
	return _extract_stamp(await _execute_async({
		"type": "handoffActor",
		"actorPlayerId": actor_player_id,
	}, "actorHandedOff", &"", true), "stamp")

func advance_ai_turn(actor_player_id: String, command_budget: int) -> Dictionary:
	return _decode_ai_turn(_execute({
		"type": "advanceAiTurn",
		"actorPlayerId": actor_player_id,
		"commandBudget": command_budget,
	}, "aiTurnAdvanced"))

func advance_ai_turn_async(actor_player_id: String, command_budget: int) -> Dictionary:
	if (
		not _transport.has_method("request_async")
		and not _transport.has_method("request_coalesced_background_async")
	):
		return advance_ai_turn(actor_player_id, command_budget)
	return _decode_ai_turn(await _execute_async({
		"type": "advanceAiTurn",
		"actorPlayerId": actor_player_id,
		"commandBudget": command_budget,
	}, "aiTurnAdvanced", BACKGROUND_AI_KEY, false))

func close_session() -> Dictionary:
	return _decode_session_closed(_execute({"type": "closeSession"}, "sessionClosed"))

func close_session_async() -> Dictionary:
	if not _transport.has_method("request_async"):
		return close_session()
	return _decode_session_closed(
		await _execute_async({"type": "closeSession"}, "sessionClosed", &"", true)
	)

func cancel_background_ai() -> void:
	if _transport.has_method("cancel_coalesced_request"):
		_transport.call("cancel_coalesced_request", BACKGROUND_AI_KEY)

func _decode_session_closed(result: Dictionary) -> Dictionary:
	if not result["ok"]:
		return result
	if not _has_exact_fields(result["value"], ["type"]):
		return _failure("invalid_client_response", "Engine returned invalid session close")
	return {"ok": true}

func snapshot() -> Dictionary:
	return _decode_snapshot(_extract(
		_execute({"type": "snapshot"}, "snapshot"),
		"snapshot",
	))

func snapshot_async() -> Dictionary:
	if not _transport.has_method("request_async"):
		return snapshot()
	return _decode_snapshot(_extract(
		await _execute_async({"type": "snapshot"}, "snapshot", &"", true),
		"snapshot",
	))

func _decode_snapshot(extracted: Dictionary) -> Dictionary:
	if not extracted["ok"]:
		return extracted
	var snapshot := ReadModelDecoder.decode_snapshot(extracted["value"])
	if snapshot == null:
		return _failure("invalid_client_response", "Engine returned an invalid snapshot")
	return {"ok": true, "value": snapshot}

func reachable(expected_revision: int, unit_id: String) -> Dictionary:
	return _decode_reachable(_query({
		"type": "reachable",
		"expectedRevision": expected_revision,
		"unitId": unit_id,
	}, "reachable"))

func reachable_async(expected_revision: int, unit_id: String) -> Dictionary:
	return _decode_reachable(await _query_async({
		"type": "reachable",
		"expectedRevision": expected_revision,
		"unitId": unit_id,
	}, "reachable", MOVEMENT_QUERY_KEY))

func route_plan(expected_revision: int, unit_id: String, target: Vector2i) -> Dictionary:
	return _decode_route_plan(_query({
		"type": "routePlan",
		"expectedRevision": expected_revision,
		"unitId": unit_id,
		"target": _coordinate(target),
	}, "routePlan"))

func route_plan_async(
	expected_revision: int,
	unit_id: String,
	target: Vector2i,
) -> Dictionary:
	return _decode_route_plan(await _query_async({
		"type": "routePlan",
		"expectedRevision": expected_revision,
		"unitId": unit_id,
		"target": _coordinate(target),
	}, "routePlan", MOVEMENT_QUERY_KEY))

func cancel_movement_queries() -> void:
	if _transport.has_method("cancel_coalesced_request"):
		_transport.call("cancel_coalesced_request", MOVEMENT_QUERY_KEY)

func _decode_reachable(result: Dictionary) -> Dictionary:
	if not result["ok"]:
		return result
	var reachable_view := ReadModelDecoder.decode_reachable(result["value"])
	if reachable_view == null:
		return _failure("invalid_client_response", "Engine returned invalid reachable tiles")
	return {"ok": true, "value": reachable_view}

func _decode_route_plan(result: Dictionary) -> Dictionary:
	if not result["ok"]:
		return result
	var route_plan := ReadModelDecoder.decode_route_plan(result["value"])
	if route_plan == null:
		return _failure("invalid_client_response", "Engine returned an invalid route plan")
	return {"ok": true, "value": route_plan}

func move_unit_async(
	expected_revision: int,
	unit_id: String,
	target: Vector2i,
) -> Dictionary:
	return await _command_async({
		"type": "moveUnit",
		"expectedRevision": expected_revision,
		"unitId": unit_id,
		"target": _coordinate(target),
	})

func cancel_unit_action_async(expected_revision: int, unit_id: String) -> Dictionary:
	return await _unit_action_async("cancelUnitAction", expected_revision, unit_id)

func skip_unit_turn_async(expected_revision: int, unit_id: String) -> Dictionary:
	return await _unit_action_async("skipUnitTurn", expected_revision, unit_id)

func fortify_unit_async(expected_revision: int, unit_id: String) -> Dictionary:
	return await _unit_action_async("fortifyUnit", expected_revision, unit_id)

func end_turn_async(expected_revision: int) -> Dictionary:
	return await _command_async({
		"type": "endTurn",
		"expectedRevision": expected_revision,
	})

func save_game() -> Dictionary:
	return _extract(_execute({"type": "exportSave"}, "saveExported"), "document")

func open_save(map_document: String, save_document: String) -> Dictionary:
	return _extract_stamp(_execute({
		"type": "openSave",
		"mapDocument": map_document,
		"saveDocument": save_document,
	}, "saveOpened"), "stamp")

func replay_log() -> Dictionary:
	return _extract(_execute({"type": "exportReplay"}, "replayExported"), "document")

func verify_replay(map_document: String, replay_document: String) -> Dictionary:
	var extracted := _extract(_execute({
		"type": "verifyReplay",
		"mapDocument": map_document,
		"replayDocument": replay_document,
	}, "replayVerified"), "verification")
	if not extracted["ok"]:
		return extracted
	var raw: Variant = extracted["value"]
	if not _has_exact_fields(raw, ["entryCount", "finalEventOffset", "finalStamp"]):
		return _failure("invalid_client_response", "Engine returned invalid replay verification")
	if (
		not _is_non_negative_integer(raw["entryCount"])
		or not _is_non_negative_integer(raw["finalEventOffset"])
	):
		return _failure("invalid_client_response", "Engine returned invalid replay verification")
	var stamp := ReadModelDecoder.decode_stamp(raw["finalStamp"])
	if stamp == null:
		return _failure("invalid_client_response", "Engine returned invalid replay verification")
	var verification := ReadModels.ReplayVerification.new()
	verification.entry_count = int(raw["entryCount"])
	verification.final_event_offset = int(raw["finalEventOffset"])
	verification.final_stamp = stamp
	return {"ok": true, "value": verification}

func _query(query: Dictionary, result_type: String) -> Dictionary:
	var extracted := _extract(
		_execute({"type": "query", "query": query}, "query"),
		"result",
	)
	if not extracted["ok"]:
		return extracted
	var value: Variant = extracted["value"]
	if not value is Dictionary or value.get("type", "") != result_type:
		return _failure("invalid_client_response", "Engine returned an unexpected query result")
	return {"ok": true, "value": value}

func _query_async(
	query: Dictionary,
	result_type: String,
	cancellation_key: StringName,
) -> Dictionary:
	var extracted := _extract(
		await _execute_async(
			{"type": "query", "query": query},
			"query",
			cancellation_key,
			true,
		),
		"result",
	)
	if not extracted["ok"]:
		return extracted
	var value: Variant = extracted["value"]
	if not value is Dictionary or value.get("type", "") != result_type:
		return _failure("invalid_client_response", "Engine returned an unexpected query result")
	return {"ok": true, "value": value}

func _command_async(command: Dictionary) -> Dictionary:
	return _decode_command(_extract(
		await _execute_async(
			{"type": "dispatch", "command": command},
			"command",
			&"",
			true,
		),
		"result",
	))

func _decode_command(extracted: Dictionary) -> Dictionary:
	if not extracted["ok"]:
		return extracted
	var command_result := ReadModelDecoder.decode_command(extracted["value"])
	if command_result == null:
		return _failure("invalid_client_response", "Engine returned an invalid command result")
	return {"ok": true, "value": command_result}

func _unit_action_async(
	action_type: String,
	expected_revision: int,
	unit_id: String,
) -> Dictionary:
	return await _command_async({
		"type": action_type,
		"expectedRevision": expected_revision,
		"unitId": unit_id,
	})

func _execute(request: Dictionary, response_type: String) -> Dictionary:
	if int(_transport.call("client_api_version")) != ClientProtocol.API_VERSION:
		return _failure(
			"unsupported_client_api",
			"The client transport uses an unsupported API version",
		)
	var envelope: Variant = _transport.call("request", request)
	return _response_decoder.decode_envelope(envelope, response_type)

func _execute_async(
	request: Dictionary,
	response_type: String,
	cancellation_key: StringName = &"",
	interactive: bool = false,
) -> Dictionary:
	if int(_transport.call("client_api_version")) != ClientProtocol.API_VERSION:
		return _failure(
			"unsupported_client_api",
			"The client transport uses an unsupported API version",
		)
	var coalesced_method := (
		&"request_coalesced_async"
		if interactive
		else &"request_coalesced_background_async"
	)
	if cancellation_key != &"" and _transport.has_method(coalesced_method):
		var coalesced_envelope: Variant = await _transport.call(
			coalesced_method,
			request,
			cancellation_key,
		)
		return _response_decoder.decode_envelope(coalesced_envelope, response_type)
	if interactive and _transport.has_method("request_interactive_async"):
		var interactive_envelope: Variant = await _transport.call(
			"request_interactive_async",
			request,
		)
		return _response_decoder.decode_envelope(interactive_envelope, response_type)
	if not _transport.has_method("request_async"):
		return _execute(request, response_type)
	var envelope: Variant = await _transport.call("request_async", request)
	return _response_decoder.decode_envelope(envelope, response_type)

func _decode_ai_turn(result: Dictionary) -> Dictionary:
	if not result["ok"]:
		return result
	var body: Variant = result["value"]
	if not _has_exact_fields(body, [
		"type", "stamp", "actorPlayerId", "executedCommands", "completedTurn",
	]):
		return _failure("invalid_client_response", "Engine returned an invalid AI turn result")
	var stamp := ReadModelDecoder.decode_stamp(body["stamp"])
	if (
		stamp == null
		or not body["actorPlayerId"] is String
		or not _is_non_negative_integer(body["executedCommands"])
		or not body["completedTurn"] is bool
	):
		return _failure("invalid_client_response", "Engine returned an invalid AI turn result")
	var value := ReadModels.AiTurnResult.new()
	value.stamp = stamp
	value.actor_player_id = body["actorPlayerId"]
	value.executed_commands = body["executedCommands"]
	value.completed_turn = body["completedTurn"]
	return {"ok": true, "value": value}

func _extract(result: Dictionary, field: String) -> Dictionary:
	if not result["ok"]:
		return result
	var body: Variant = result["value"]
	if not _has_exact_fields(body, ["type", field]):
		return _failure("invalid_client_response", "Engine response is missing %s" % field)
	return {"ok": true, "value": body[field]}

func _extract_stamp(result: Dictionary, field: String) -> Dictionary:
	var extracted := _extract(result, field)
	if not extracted["ok"]:
		return extracted
	var stamp := ReadModelDecoder.decode_stamp(extracted["value"])
	if stamp == null:
		return _failure("invalid_client_response", "Engine returned an invalid session stamp")
	return {"ok": true, "value": stamp}

func _coordinate(value: Vector2i) -> Dictionary:
	return {"col": value.x, "row": value.y}

func _is_non_negative_integer(value: Variant) -> bool:
	if not value is int and not value is float:
		return false
	var numeric_value := float(value)
	return (
		is_finite(numeric_value)
		and numeric_value >= 0.0
		and numeric_value == floorf(numeric_value)
	)

func _has_exact_fields(value: Variant, fields: Array) -> bool:
	if not value is Dictionary or value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

func _failure(code: String, message: String) -> Dictionary:
	return ClientFailure.result(code, message)
