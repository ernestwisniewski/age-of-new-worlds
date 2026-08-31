class_name AonwLocalMatchSessionController
extends RefCounted

const ClientFailure := preload("res://game/application/session/client_failure.gd")
const REQUIRED_ENGINE_FEATURES: Array[StringName] = [
	&"matchStart",
	&"snapshot",
	&"reachable",
	&"routePlan",
	&"moveUnit",
]

enum Lifecycle { CLOSED, OPENING, OPEN, CLOSING }

var _gateway: RefCounted
var _stamp: AonwClientReadModels.Stamp
var _engine_features: AonwClientReadModels.EngineFeatureSet
var _lifecycle := Lifecycle.CLOSED
var _generation := 0
var _recipient_generation := 0
var _movement_query_correlation := 0

func _init(gateway: RefCounted) -> void:
	assert(gateway != null, "Local match gateway port is required")
	_gateway = gateway

func is_available() -> bool:
	return bool(_gateway.call("is_available"))

func revision() -> int:
	return 0 if _stamp == null else _stamp.revision

func lifecycle() -> int:
	return _lifecycle

func generation() -> int:
	return _generation

func is_open() -> bool:
	return _lifecycle == Lifecycle.OPEN

func engine_features() -> Dictionary:
	if _engine_features != null:
		return {"ok": true, "value": _engine_features}
	return _gateway.call("engine_features")

func open(map_document: String, scenario_document: String, actor_player_id: String) -> Dictionary:
	return _open_with(&"open_session", [
		map_document,
		scenario_document,
		actor_player_id,
	])

func open_async(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
) -> Dictionary:
	return await _open_with_async(&"open_session_async", &"open_session", [
		map_document,
		scenario_document,
		actor_player_id,
	])

func start_match(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
	match_identity: Dictionary,
	fog_enabled: bool,
) -> Dictionary:
	return _open_with(&"start_match", [
		map_document,
		scenario_document,
		actor_player_id,
		match_identity,
		fog_enabled,
	])

func start_match_async(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
	match_identity: Dictionary,
	fog_enabled: bool,
) -> Dictionary:
	return await _open_with_async(&"start_match_async", &"start_match", [
		map_document,
		scenario_document,
		actor_player_id,
		match_identity,
		fog_enabled,
	])

func handoff_actor_async(actor_player_id: String) -> Dictionary:
	cancel_movement_queries()
	_recipient_generation += 1
	var method := (
		&"handoff_actor_async"
		if _gateway.has_method("handoff_actor_async")
		else &"handoff_actor"
	)
	return await _call_stamp_async(method, [actor_player_id])

func advance_ai_turn(actor_player_id: String, command_budget: int) -> Dictionary:
	return _call_value(&"advance_ai_turn", [actor_player_id, command_budget])

func advance_ai_turn_async(actor_player_id: String, command_budget: int) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	var request_generation := _generation
	var request_recipient_generation := _recipient_generation
	var result: Dictionary = await _gateway.call(
		"advance_ai_turn_async",
		actor_player_id,
		command_budget,
	)
	if (
		request_generation != _generation
		or request_recipient_generation != _recipient_generation
		or _lifecycle != Lifecycle.OPEN
	):
		return _failure(
			"stale_session_response",
			"The session changed before the engine response arrived",
		)
	return _track_value_stamp(result)

func close() -> Dictionary:
	if not _begin_close():
		return {"ok": true}
	return _finish_close(_gateway.call("close_session"))

func close_async() -> Dictionary:
	if not _begin_close():
		return {"ok": true}
	var result: Dictionary
	if _gateway.has_method("close_session_async"):
		result = await _gateway.call("close_session_async")
	else:
		result = _gateway.call("close_session")
	return _finish_close(result)

func _begin_close() -> bool:
	if _lifecycle in [Lifecycle.CLOSED, Lifecycle.CLOSING]:
		return false
	cancel_movement_queries()
	if _gateway.has_method("cancel_background_ai"):
		_gateway.call("cancel_background_ai")
	_generation += 1
	_lifecycle = Lifecycle.CLOSING
	return true

func _finish_close(result: Dictionary) -> Dictionary:
	if result["ok"]:
		_stamp = null
		_engine_features = null
		_lifecycle = Lifecycle.CLOSED
	else:
		_lifecycle = Lifecycle.OPEN
	return result

func snapshot() -> Dictionary:
	return _call_value(&"snapshot")

func snapshot_async() -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	var request_generation := _generation
	var request_recipient_generation := _recipient_generation
	var result: Dictionary
	if _gateway.has_method("snapshot_async"):
		result = await _gateway.call("snapshot_async")
	else:
		result = _gateway.call("snapshot")
	if (
		request_generation != _generation
		or request_recipient_generation != _recipient_generation
		or _lifecycle != Lifecycle.OPEN
	):
		return _failure(
			"stale_session_response",
			"The session changed before the engine response arrived",
		)
	return _track_value_stamp(result)

func reachable(unit_id: String) -> Dictionary:
	cancel_movement_queries()
	return _call_value(&"reachable", [revision(), unit_id])

func reachable_async(unit_id: String) -> Dictionary:
	return await _call_movement_value_async(&"reachable_async", [unit_id])

func route_plan(unit_id: String, target: Vector2i) -> Dictionary:
	cancel_movement_queries()
	return _call_value(&"route_plan", [revision(), unit_id, target])

func route_plan_async(unit_id: String, target: Vector2i) -> Dictionary:
	return await _call_movement_value_async(&"route_plan_async", [unit_id, target])

func cancel_movement_queries() -> void:
	_movement_query_correlation += 1
	if _gateway.has_method("cancel_movement_queries"):
		_gateway.call("cancel_movement_queries")

func move_unit_async(unit_id: String, target: Vector2i) -> Dictionary:
	return await _call_revision_value_async(
		&"move_unit_async",
		&"move_unit",
		[unit_id, target],
	)

func cancel_unit_action_async(unit_id: String) -> Dictionary:
	return await _call_revision_value_async(
		&"cancel_unit_action_async",
		&"cancel_unit_action",
		[unit_id],
	)

func skip_unit_turn_async(unit_id: String) -> Dictionary:
	return await _call_revision_value_async(
		&"skip_unit_turn_async",
		&"skip_unit_turn",
		[unit_id],
	)

func fortify_unit_async(unit_id: String) -> Dictionary:
	return await _call_revision_value_async(
		&"fortify_unit_async",
		&"fortify_unit",
		[unit_id],
	)

func end_turn_async() -> Dictionary:
	return await _call_revision_value_async(&"end_turn_async", &"end_turn", [])

func save_game() -> Dictionary:
	return _call_plain(&"save_game")

func open_save(map_document: String, save_document: String) -> Dictionary:
	return _open_with(&"open_save", [map_document, save_document])

func replay_log() -> Dictionary:
	return _call_plain(&"replay_log")

func verify_replay(map_document: String, replay_document: String) -> Dictionary:
	return _gateway.call("verify_replay", map_document, replay_document)

func _open_with(method: StringName, arguments: Array) -> Dictionary:
	var opening := _begin_open()
	if not opening["ok"]:
		return opening
	var features := _accept_engine_features(_gateway.call("engine_features"))
	if not features["ok"]:
		return features
	return _finish_open(_gateway.callv(method, arguments), features["value"])

func _open_with_async(
	async_method: StringName,
	fallback_method: StringName,
	arguments: Array,
) -> Dictionary:
	var opening := _begin_open()
	if not opening["ok"]:
		return opening
	var request_generation := _generation
	var negotiated: Dictionary
	if _gateway.has_method("engine_features_async"):
		negotiated = await _gateway.call("engine_features_async")
	else:
		negotiated = _gateway.call("engine_features")
	if not _is_current_open(request_generation):
		return _stale_response()
	var features := _accept_engine_features(negotiated)
	if not features["ok"]:
		return features
	var result: Dictionary
	if _gateway.has_method(async_method):
		result = await _gateway.callv(async_method, arguments)
	else:
		result = _gateway.callv(fallback_method, arguments)
	if not _is_current_open(request_generation):
		return _stale_response()
	return _finish_open(result, features["value"])

func _begin_open() -> Dictionary:
	if _lifecycle != Lifecycle.CLOSED:
		return _failure("session_already_open", "Close the active session before opening another")
	_generation += 1
	_lifecycle = Lifecycle.OPENING
	_stamp = null
	_engine_features = null
	return {"ok": true}

func _accept_engine_features(negotiated: Dictionary) -> Dictionary:
	if not negotiated["ok"]:
		_lifecycle = Lifecycle.CLOSED
		return negotiated
	var features: AonwClientReadModels.EngineFeatureSet = negotiated["value"]
	var missing := features.missing(REQUIRED_ENGINE_FEATURES)
	if not missing.is_empty():
		_lifecycle = Lifecycle.CLOSED
		return _failure(
			"unsupported_engine_features",
			"The native engine is missing required features: %s" % [
				", ".join(missing),
			],
		)
	return {"ok": true, "value": features}

func _finish_open(
	result: Dictionary,
	features: AonwClientReadModels.EngineFeatureSet,
) -> Dictionary:
	if result["ok"]:
		_stamp = result["value"]
		_engine_features = features
		_lifecycle = Lifecycle.OPEN
	else:
		_engine_features = null
		_lifecycle = Lifecycle.CLOSED
	return result

func _is_current_open(request_generation: int) -> bool:
	return request_generation == _generation and _lifecycle == Lifecycle.OPENING

func _stale_response() -> Dictionary:
	return _failure(
		"stale_session_response",
		"The session changed before the engine response arrived",
	)

func _call_stamp_async(method: StringName, arguments: Array = []) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	var request_generation := _generation
	var request_recipient_generation := _recipient_generation
	var request_revision := revision()
	var result: Dictionary = await _gateway.callv(method, arguments)
	if (
		request_generation != _generation
		or request_recipient_generation != _recipient_generation
		or _lifecycle != Lifecycle.OPEN
		or request_revision != revision()
	):
		return _stale_response()
	return _track_stamp(result)

func _call_value(method: StringName, arguments: Array = []) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	return _track_value_stamp(_gateway.callv(method, arguments))

func _call_movement_value_async(method: StringName, arguments: Array) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	_movement_query_correlation += 1
	var request_correlation := _movement_query_correlation
	var request_generation := _generation
	var request_recipient_generation := _recipient_generation
	var request_revision := revision()
	var gateway_arguments := [request_revision]
	gateway_arguments.append_array(arguments)
	var result: Dictionary = await _gateway.callv(method, gateway_arguments)
	if (
		request_generation != _generation
		or request_recipient_generation != _recipient_generation
		or _lifecycle != Lifecycle.OPEN
		or request_correlation != _movement_query_correlation
		or request_revision != revision()
	):
		return _failure(
			"stale_session_response",
			"The session changed before the engine response arrived",
		)
	return _track_value_stamp(result)

func _call_revision_value_async(
	async_method: StringName,
	fallback_method: StringName,
	arguments: Array,
) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	cancel_movement_queries()
	var request_generation := _generation
	var request_recipient_generation := _recipient_generation
	var request_revision := revision()
	var gateway_arguments := [request_revision]
	gateway_arguments.append_array(arguments)
	var result: Dictionary
	if _gateway.has_method(async_method):
		result = await _gateway.callv(async_method, gateway_arguments)
	else:
		result = _gateway.callv(fallback_method, gateway_arguments)
	if (
		request_generation != _generation
		or request_recipient_generation != _recipient_generation
		or _lifecycle != Lifecycle.OPEN
		or request_revision != revision()
	):
		return _stale_response()
	return _track_value_stamp(result)

func _call_plain(method: StringName, arguments: Array = []) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	return _gateway.callv(method, arguments)

func _require_open() -> Dictionary:
	if _lifecycle == Lifecycle.OPEN:
		return {}
	return _failure("session_not_open", "Open a session before using session operations")

func _failure(code: String, message: String) -> Dictionary:
	return ClientFailure.result(code, message)

func _track_stamp(result: Dictionary) -> Dictionary:
	if result["ok"]:
		_stamp = result["value"]
	return result

func _track_value_stamp(result: Dictionary) -> Dictionary:
	if not result["ok"]:
		return result
	var value: RefCounted = result["value"]
	var stamp: Variant = value.get("stamp")
	assert(stamp is AonwClientReadModels.Stamp, "Gateway result must carry a typed stamp")
	_stamp = stamp
	return result
