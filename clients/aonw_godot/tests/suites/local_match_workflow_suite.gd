extends RefCounted

const LocalMatchSessionController := preload(
	"res://game/application/session/local_match_session_controller.gd"
)
const OpenLocalMatch := preload(
	"res://game/application/session/open_local_match.gd"
)
const LocalMatchWorkflow := preload(
	"res://game/application/match/local_match_workflow.gd"
)
const MapSource := preload("res://game/application/map/map_source.gd")
const MapView := preload("res://game/application/map/read_model/map_view.gd")
const MapTileView := preload(
	"res://game/application/map/read_model/map_tile_view.gd"
)

var _failures: Array[String]
var _invalidations := 0

class DocumentReaderDouble:
	extends RefCounted

	func read(_path: String) -> Dictionary:
		return {"ok": true, "document": "{}"}

class RecipientWorkflowGateway:
	extends RefCounted

	signal snapshot_response_released
	signal handoff_response_released

	var actor_player_id := "player-1"
	var snapshot_calls := 0
	var handoff_calls := 0
	var command_calls := 0
	var movement_cancellation_calls := 0

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
		requested_actor_player_id: String,
	) -> Dictionary:
		actor_player_id = requested_actor_player_id
		return {"ok": true, "value": _stamp()}

	func close_session() -> Dictionary:
		return {"ok": true}

	func snapshot_async() -> Dictionary:
		snapshot_calls += 1
		if snapshot_calls == 2:
			await snapshot_response_released
		return {"ok": true, "value": _snapshot()}

	func handoff_actor_async(requested_actor_player_id: String) -> Dictionary:
		handoff_calls += 1
		await handoff_response_released
		actor_player_id = requested_actor_player_id
		return {"ok": true, "value": _stamp()}

	func end_turn_async(_expected_revision: int) -> Dictionary:
		command_calls += 1
		return {"ok": false, "code": "unexpected_command", "message": "unexpected"}

	func cancel_movement_queries() -> void:
		movement_cancellation_calls += 1

	func release_snapshot_response() -> void:
		snapshot_response_released.emit()

	func release_handoff_response() -> void:
		handoff_response_released.emit()

	func _snapshot() -> AonwClientReadModels.SnapshotView:
		var result := AonwClientReadModels.SnapshotView.new()
		result.stamp = _stamp()
		result.turn = 1
		result.outcome = AonwClientReadModels.GameOutcomeView.new()
		result.outcome.condition = &"ongoing"
		result.outcome.score_by_player_id = {}.duplicate(true)
		result.outcome.score_by_player_id.make_read_only()
		result.turn_lifecycle = AonwClientReadModels.TurnLifecycleView.new()
		result.turn_lifecycle.has_own_state = true
		result.turn_lifecycle.own_state = &"active"
		result.turn_lifecycle.required_submission_count = 2
		result.diplomacy = _diplomacy()
		var unit := AonwClientReadModels.UnitView.new()
		unit.id = "unit-1" if actor_player_id == "player-1" else "unit-2"
		unit.owner_player_id = actor_player_id
		unit.kind = "commander"
		unit.display_name = "Commander"
		unit.coordinate = Vector2i.ZERO
		var units: Array[AonwClientReadModels.UnitView] = [unit]
		units.make_read_only()
		result.units = units
		var cities: Array[AonwClientReadModels.CityView] = []
		var artifacts: Array[AonwClientReadModels.ArtifactView] = []
		var improvements: Array[AonwClientReadModels.FieldImprovementView] = []
		var roads: Array[AonwClientReadModels.RoadView] = []
		for values in [cities, artifacts, improvements, roads]:
			values.make_read_only()
		result.cities = cities
		result.artifacts = artifacts
		result.field_improvements = improvements
		result.roads = roads
		return result

	func _stamp() -> AonwClientReadModels.Stamp:
		var result := AonwClientReadModels.Stamp.new()
		result.revision = 0
		result.state_digest = "shared-state"
		result.map_hash = "map-hash"
		result.ruleset_hash = "ruleset-hash"
		return result

	func _diplomacy() -> AonwClientReadModels.DiplomacyView:
		var result := AonwClientReadModels.DiplomacyView.new()
		var relations: Array[AonwClientReadModels.DiplomaticRelationView] = []
		var proposals: Array[AonwClientReadModels.DiplomaticProposalView] = []
		var messages: Array[AonwClientReadModels.DiplomaticMessageView] = []
		var trades: Array[AonwClientReadModels.ResourceTradeAgreementView] = []
		for values in [relations, proposals, messages, trades]:
			values.make_read_only()
		result.relations = relations
		result.proposals = proposals
		result.messages = messages
		result.resource_trade_agreements = trades
		return result

func run(failures: Array[String]) -> void:
	_failures = failures
	await _test_handoff_replaces_the_recipient_fail_closed()

func _test_handoff_replaces_the_recipient_fail_closed() -> void:
	var gateway := RecipientWorkflowGateway.new()
	var controller := LocalMatchSessionController.new(gateway)
	var open_match := OpenLocalMatch.new(controller, DocumentReaderDouble.new())
	var workflow := LocalMatchWorkflow.new(controller, open_match)
	var map := _map()
	workflow.projection_invalidated.connect(_on_projection_invalidated)
	var opened: Dictionary = await workflow.open(
		MapSource.new("map", "map.json", "", "test"),
		map,
		"player-1",
	)
	_check(
		opened["ok"]
		and opened["value"].units[0].id == "unit-1"
		and opened["value"].units[0].owner_player_id == "player-1",
		"recipient workflow opens the authenticated actor projection",
	)

	var stale_resync := {}
	_capture_resync(workflow, stale_resync)
	await Engine.get_main_loop().process_frame
	var handoff := {}
	_capture_handoff(workflow, handoff)
	await Engine.get_main_loop().process_frame
	var blocked_command: Dictionary = await workflow.end_turn_async()
	_check(
		_invalidations == 1
		and handoff.is_empty()
		and not blocked_command["ok"]
		and blocked_command["code"] == "recipient_resync_required"
		and gateway.command_calls == 0,
		"handoff clears the old projection before waiting and blocks stale commands",
	)

	gateway.release_snapshot_response()
	await Engine.get_main_loop().process_frame
	var late_snapshot: Dictionary = stale_resync.get("value", {})
	_check(
		not late_snapshot.get("ok", true)
		and late_snapshot.get("code", "") == "stale_session_response",
		"recipient generation rejects a pre-handoff snapshot at the same revision",
	)

	gateway.release_handoff_response()
	for _frame in range(10):
		if not handoff.is_empty():
			break
		await Engine.get_main_loop().process_frame
	var handed: Dictionary = handoff.get("value", {})
	_check(
		handed.get("ok", false)
		and handed["value"].units[0].id == "unit-2"
		and handed["value"].units[0].owner_player_id == "player-2"
		and gateway.snapshot_calls == 3
		and gateway.handoff_calls == 1
		and gateway.movement_cancellation_calls >= 1,
		"handoff publishes only the freshly synchronized next-recipient projection",
	)
	_test_local_activity_identity(workflow)
	workflow.close()

func _test_local_activity_identity(workflow: AonwLocalMatchWorkflow) -> void:
	var command := AonwClientReadModels.CommandResult.new()
	command.stamp = AonwClientReadModels.Stamp.new()
	command.stamp.revision = 12
	var first := AonwClientReadModels.CommandEvent.new()
	first.kind = &"turnEnded"
	var second := AonwClientReadModels.CommandEvent.new()
	second.kind = &"allPlayersSubmitted"
	command.events = [first, second]
	var activities: Array = workflow.call("_activities", command)
	_check(
		activities.size() == 2
		and activities[0].identity.revision == 12
		and activities[0].identity.event_index == 0
		and activities[0].kind == &"turnEnded"
		and activities[1].identity.revision == 12
		and activities[1].identity.event_index == 1
		and activities[1].kind == &"allPlayersSubmitted",
		"local activity identity is the ordered result revision and event index",
	)

func _capture_resync(workflow: AonwLocalMatchWorkflow, result: Dictionary) -> void:
	result["value"] = await workflow.resync()

func _capture_handoff(workflow: AonwLocalMatchWorkflow, result: Dictionary) -> void:
	result["value"] = await workflow.handoff_actor_async("player-2")

func _on_projection_invalidated() -> void:
	_invalidations += 1

func _map() -> AonwMapView:
	var names: Array[StringName] = [&"grassland"]
	var resources: Array[StringName] = []
	var tile := MapTileView.new(
		Vector2i.ZERO,
		&"grassland",
		&"grassland",
		names,
		names,
		resources,
		0,
	)
	var objectives: Array[AonwMapObjectiveView] = []
	var tiles: Array[AonwMapTileView] = [tile]
	return MapView.new(
		&"map", "map-hash", &"oddQFlatTop", 1, 1, 1.0, objectives, tiles,
	)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
