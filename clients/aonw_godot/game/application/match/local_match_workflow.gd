class_name AonwLocalMatchWorkflow
extends RefCounted

signal projection_invalidated

const ClientFailure := preload("res://game/application/session/client_failure.gd")
const ProjectionStore := preload(
	"res://game/application/session/recipient_projection_store.gd"
)
const ViewModels := preload(
	"res://game/application/match/local_match_view_models.gd"
)

var _controller: AonwLocalMatchSessionController
var _open_match: AonwOpenLocalMatch
var _store: RefCounted

func _init(
	controller: AonwLocalMatchSessionController,
	open_match: AonwOpenLocalMatch,
) -> void:
	assert(controller != null, "Local match controller is required")
	assert(open_match != null, "Open local match use case is required")
	_controller = controller
	_open_match = open_match

func open(
	source: AonwMapSource,
	map: AonwMapView,
	actor_player_id: String,
) -> Dictionary:
	var closed: Dictionary = await close_async()
	if not closed["ok"]:
		return closed
	var opened: Dictionary = await _open_match.execute_async(
		source.map_path,
		"res://assets/scenarios/%s.json" % map.map_id(),
		actor_player_id,
	)
	if not opened["ok"]:
		return opened
	_store = ProjectionStore.new(map.content_hash(), Callable(map, "contains"))
	var synchronized: Dictionary = await _read_snapshot(false)
	if synchronized["ok"]:
		return synchronized
	await _controller.close_async()
	_store.clear()
	_store = null
	return synchronized

func resync() -> Dictionary:
	return await _read_snapshot(true)

func handoff_actor_async(actor_player_id: String) -> Dictionary:
	var ready := _require_projection()
	if not ready.is_empty():
		return ready
	var next_store: RefCounted = _store
	_invalidate_projection()
	var handed: Dictionary = await _controller.handoff_actor_async(actor_player_id)
	if not handed["ok"]:
		await _controller.close_async()
		return handed
	var snapshot: Dictionary = await _controller.snapshot_async()
	if not snapshot["ok"]:
		await _controller.close_async()
		return snapshot
	var stored: Dictionary = next_store.open(snapshot["value"])
	if not stored["ok"]:
		await _controller.close_async()
		return stored
	_store = next_store
	return {
		"ok": true,
		"value": _projection(stored["value"]),
		"changed": stored["changed"],
	}

func close() -> Dictionary:
	_clear_projection()
	return _controller.close()

func close_async() -> Dictionary:
	_clear_projection()
	return await _controller.close_async()

func is_open() -> bool:
	return _controller.is_open()

func revision() -> int:
	return _controller.revision()

func reachable_async(unit_id: String) -> Dictionary:
	var ready := _require_projection()
	if not ready.is_empty():
		return ready
	var result: Dictionary = await _controller.reachable_async(unit_id)
	if not result["ok"]:
		return result
	var raw: AonwClientReadModels.ReachableView = result["value"]
	if not _matches_projection(raw.stamp):
		return _resync_required("Reachable view does not match the recipient projection")
	var tiles: Array[AonwLocalMatchViewModels.ReachableTile] = []
	for raw_tile in raw.tiles:
		var tile := ViewModels.ReachableTile.new()
		tile.coordinate = raw_tile.coordinate
		tile.cost_units = raw_tile.cost_units
		tile.exhausts_movement = raw_tile.exhausts_movement
		tiles.append(tile)
	tiles.make_read_only()
	var value := ViewModels.ReachableView.new()
	value.revision = raw.stamp.revision
	value.unit_id = raw.unit_id
	value.available_movement_units = raw.available_movement_units
	value.tiles = tiles
	return {"ok": true, "value": value}

func route_plan_async(unit_id: String, target: Vector2i) -> Dictionary:
	var ready := _require_projection()
	if not ready.is_empty():
		return ready
	var result: Dictionary = await _controller.route_plan_async(unit_id, target)
	if not result["ok"]:
		return result
	var raw: AonwClientReadModels.RoutePlanView = result["value"]
	if not _matches_projection(raw.stamp):
		return _resync_required("Route view does not match the recipient projection")
	var value := ViewModels.RouteView.new()
	value.revision = raw.stamp.revision
	value.unit_id = raw.unit_id
	value.target = raw.target
	value.destination = raw.destination
	value.total_cost_units = raw.total_cost_units
	value.available_movement_units = raw.available_movement_units
	value.remaining_movement_units = raw.remaining_movement_units
	value.steps = _movement_steps(raw.steps)
	return {"ok": true, "value": value}

func move_unit_async(unit_id: String, target: Vector2i) -> Dictionary:
	var ready := _require_projection()
	if not ready.is_empty():
		return ready
	return _apply_command(await _controller.move_unit_async(unit_id, target))

func cancel_unit_action_async(unit_id: String) -> Dictionary:
	var ready := _require_projection()
	if not ready.is_empty():
		return ready
	return _apply_command(await _controller.cancel_unit_action_async(unit_id))

func skip_unit_turn_async(unit_id: String) -> Dictionary:
	var ready := _require_projection()
	if not ready.is_empty():
		return ready
	return _apply_command(await _controller.skip_unit_turn_async(unit_id))

func fortify_unit_async(unit_id: String) -> Dictionary:
	var ready := _require_projection()
	if not ready.is_empty():
		return ready
	return _apply_command(await _controller.fortify_unit_async(unit_id))

func end_turn_async() -> Dictionary:
	var ready := _require_projection()
	if not ready.is_empty():
		return ready
	return _apply_command(await _controller.end_turn_async())

func cancel_movement_queries() -> void:
	_controller.cancel_movement_queries()

func _read_snapshot(resyncing: bool) -> Dictionary:
	if _store == null:
		return _resync_required("Recipient projection is not configured")
	var requested_store: RefCounted = _store
	var result: Dictionary = await _controller.snapshot_async()
	if not result["ok"]:
		return result
	if requested_store != _store:
		return _resync_required("Recipient projection changed while synchronizing")
	var stored: Dictionary = (
		requested_store.replace_after_resync(result["value"])
		if resyncing
		else requested_store.open(result["value"])
	)
	if not stored["ok"]:
		return stored
	return {
		"ok": true,
		"value": _projection(stored["value"]),
		"changed": stored["changed"],
	}

func _apply_command(result: Dictionary) -> Dictionary:
	if not result["ok"]:
		return result
	if _store == null:
		return _resync_required("Recipient projection is not initialized")
	var raw: AonwClientReadModels.CommandResult = result["value"]
	var stored: Dictionary = _store.apply_command(raw)
	if not stored["ok"]:
		return stored
	var value := ViewModels.CommandResult.new()
	value.accepted = raw.accepted
	value.rejection = raw.rejection
	value.revision = stored["value"].stamp.revision
	value.turn = _turn(stored["value"])
	value.unit_transition = _unit_transition(raw)
	value.activities = _activities(raw)
	return {"ok": true, "value": value, "changed": stored["changed"]}

func _activities(
	command: AonwClientReadModels.CommandResult,
) -> Array[AonwLocalMatchViewModels.ActivityView]:
	var result: Array[AonwLocalMatchViewModels.ActivityView] = []
	for index in range(command.events.size()):
		var identity := ViewModels.ActivityIdentity.new()
		identity.revision = command.stamp.revision
		identity.event_index = index
		var activity := ViewModels.ActivityView.new()
		activity.identity = identity
		activity.kind = command.events[index].kind
		result.append(activity)
	result.make_read_only()
	return result

func _projection(snapshot: AonwClientReadModels.SnapshotView) -> AonwLocalMatchViewModels.ProjectionView:
	var units: Array[AonwLocalMatchViewModels.UnitView] = []
	for unit in snapshot.units:
		units.append(_unit(unit))
	units.make_read_only()
	var result := ViewModels.ProjectionView.new()
	result.revision = snapshot.stamp.revision
	result.turn = _turn(snapshot)
	result.units = units
	return result

func _turn(snapshot: AonwClientReadModels.SnapshotView) -> AonwLocalMatchViewModels.TurnView:
	var result := ViewModels.TurnView.new()
	result.number = snapshot.turn
	result.has_own_state = snapshot.turn_lifecycle.has_own_state
	result.own_state = snapshot.turn_lifecycle.own_state
	result.own_submitted = snapshot.turn_lifecycle.own_submitted
	result.required_submission_count = snapshot.turn_lifecycle.required_submission_count
	result.submitted_count = snapshot.turn_lifecycle.submitted_count
	result.pending_action = (
		&"" if snapshot.pending_action == null else snapshot.pending_action.kind
	)
	result.outcome_condition = snapshot.outcome.condition
	return result

func _unit(raw: AonwClientReadModels.UnitView) -> AonwLocalMatchViewModels.UnitView:
	var result := ViewModels.UnitView.new()
	result.id = raw.id
	result.owner_player_id = raw.owner_player_id
	result.kind = StringName(raw.kind)
	result.display_name = raw.display_name
	result.coordinate = raw.coordinate
	return result

func _unit_transition(
	command: AonwClientReadModels.CommandResult,
) -> AonwLocalMatchViewModels.UnitTransition:
	var units: Array[AonwLocalMatchViewModels.UnitView] = []
	for unit in command.patch.upserted_units:
		units.append(_unit(unit))
	units.make_read_only()
	var removed := command.patch.removed_unit_ids.duplicate()
	removed.make_read_only()
	var result := ViewModels.UnitTransition.new()
	result.upserted_units = units
	result.removed_unit_ids = removed
	var evidence: Variant = command.evidence
	if evidence is AonwClientReadModels.MovementEvidence:
		result.movement_unit_id = evidence.unit_id
		result.movement_steps = _movement_steps(evidence.steps)
	else:
		var no_steps: Array[AonwLocalMatchViewModels.MovementStep] = []
		no_steps.make_read_only()
		result.movement_steps = no_steps
	return result

func _movement_steps(raw_steps: Array) -> Array[AonwLocalMatchViewModels.MovementStep]:
	var result: Array[AonwLocalMatchViewModels.MovementStep] = []
	for raw in raw_steps:
		var step := ViewModels.MovementStep.new()
		step.coordinate = raw.coordinate
		step.enter_cost_units = raw.enter_cost_units
		step.cumulative_cost_units = raw.cumulative_cost_units
		result.append(step)
	result.make_read_only()
	return result

func _matches_projection(stamp: AonwClientReadModels.Stamp) -> bool:
	if _store == null or not _store.has_snapshot():
		return false
	var current: AonwClientReadModels.SnapshotView = _store.current()
	return (
		stamp.revision == current.stamp.revision
		and stamp.state_digest == current.stamp.state_digest
		and stamp.map_hash == current.stamp.map_hash
		and stamp.ruleset_hash == current.stamp.ruleset_hash
	)

func _clear_projection() -> void:
	_invalidate_projection()

func _invalidate_projection() -> void:
	if _store != null:
		_store.clear()
		projection_invalidated.emit()
	_store = null

func _require_projection() -> Dictionary:
	if _store != null and _store.has_snapshot():
		return {}
	return _resync_required("Recipient projection is not available")

func _resync_required(message: String) -> Dictionary:
	return ClientFailure.result("recipient_resync_required", message)
