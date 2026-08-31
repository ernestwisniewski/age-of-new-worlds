extends RefCounted

const RecipientProjectionStore := preload(
	"res://game/application/session/recipient_projection_store.gd"
)
const ClientFailure := preload("res://game/application/session/client_failure.gd")

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_patch_semantics()
	_test_invalid_patch_is_atomic()
	_test_resync_identity()
	_test_snapshot_ordering()

func _test_patch_semantics() -> void:
	var store := _store()
	var opened: Dictionary = store.open(_snapshot(7))
	_check(opened["ok"] and opened["changed"], "projection store opens one full snapshot")
	var before: AonwClientReadModels.SnapshotView = store.current()
	var patch := _patch(7, 8, 8, null, null)
	patch.upserted_units = _units([_unit("unit-1", Vector2i(2, 2))])
	var applied: Dictionary = store.apply_command(_command(true, _stamp(8), patch))
	var after: AonwClientReadModels.SnapshotView = store.current()
	_check(
		applied["ok"]
		and applied["changed"]
		and after != before
		and after.stamp.revision == 8
		and after.turn == 8
		and after.units[0].coordinate == Vector2i(2, 2),
		"projection store atomically applies one contiguous accepted patch",
	)
	_check(
		after.pending_action == null
		and after.city_founding_draft == null
		and after.outcome == before.outcome
		and after.turn_lifecycle == before.turn_lifecycle
		and after.diplomacy == before.diplomacy,
		"projection store distinguishes explicit clears from absent replacements",
	)

	var rejected_patch := _patch(8, 8, 8, null, null)
	var rejected: Dictionary = store.apply_command(_command(false, after.stamp, rejected_patch))
	_check(
		rejected["ok"] and not rejected["changed"] and store.current() == after,
		"projection store leaves a canonical rejected command unchanged",
	)
	var noop: Dictionary = store.apply_command(_command(true, after.stamp, rejected_patch))
	_check(
		noop["ok"] and not noop["changed"] and store.current() == after,
		"projection store leaves an accepted no-op unchanged",
	)

	var mutating_rejection := _patch(8, 8, 8, null, null)
	mutating_rejection.upserted_units = _units([_unit("unit-1", Vector2i(3, 2))])
	var rejected_mutation: Dictionary = store.apply_command(
		_command(false, after.stamp, mutating_rejection)
	)
	_check(
		not rejected_mutation["ok"]
		and rejected_mutation["code"] == "recipient_resync_required"
		and store.current() == after,
		"projection store rejects a mutating rejection without exposing partial state",
	)

func _test_invalid_patch_is_atomic() -> void:
	var store := _store()
	store.open(_snapshot(8, Vector2i(2, 2)))
	var before: AonwClientReadModels.SnapshotView = store.current()
	var invalid_removal := _patch(8, 9, 8, null, null)
	invalid_removal.upserted_units = _units([_unit("unit-2", Vector2i(3, 3))])
	invalid_removal.removed_unit_ids = _strings(["missing-unit"])
	var removal_result: Dictionary = store.apply_command(
		_command(true, _stamp(9), invalid_removal)
	)
	_check(
		not removal_result["ok"] and store.current() == before,
		"projection store rejects an invalid removal before committing any upsert",
	)

	var outside_bounds := _patch(8, 9, 8, null, null)
	outside_bounds.upserted_units = _units([_unit("unit-1", Vector2i(20, 20))])
	var bounds_result: Dictionary = store.apply_command(
		_command(true, _stamp(9), outside_bounds)
	)
	_check(
		not bounds_result["ok"]
		and bounds_result["failure"].kind == ClientFailure.Kind.PROTOCOL
		and store.current() == before
		and store.current().units[0].coordinate == Vector2i(2, 2),
		"projection store requests resync for an out-of-bounds patch atomically",
	)

	var skipped_revision := _patch(8, 10, 8, null, null)
	var skipped_result: Dictionary = store.apply_command(
		_command(true, _stamp(10), skipped_revision)
	)
	_check(
		not skipped_result["ok"] and store.current() == before,
		"projection store rejects a patch that skips the cached revision",
	)

func _test_resync_identity() -> void:
	var store := _store()
	store.open(_snapshot(8))
	var before: AonwClientReadModels.SnapshotView = store.current()
	var older: Dictionary = store.replace_after_resync(_snapshot(7))
	var foreign: Dictionary = store.replace_after_resync(
		_snapshot(10, Vector2i(1, 2), "foreign-map")
	)
	_check(
		not older["ok"] and not foreign["ok"] and store.current() == before,
		"projection store rejects backward and foreign resync snapshots",
	)
	var replacement := _snapshot(10, Vector2i(4, 4))
	var replaced: Dictionary = store.replace_after_resync(replacement)
	_check(
		replaced["ok"]
		and replaced["changed"]
		and store.current() == replacement
		and store.current().stamp.revision == 10,
		"projection store replaces the full view with a compatible forward resync",
	)
	store.clear()
	_check(not store.has_snapshot(), "projection store clears recipient data on session close")

func _test_snapshot_ordering() -> void:
	var store := _store()
	var unordered := _snapshot(7)
	unordered.units = _units([
		_unit("unit-2", Vector2i(2, 2)),
		_unit("unit-1", Vector2i(1, 2)),
	])
	var result: Dictionary = store.open(unordered)
	_check(
		not result["ok"] and not store.has_snapshot(),
		"projection store rejects unordered recipient identities before open",
	)
	var foreign_map: Dictionary = store.open(
		_snapshot(7, Vector2i(1, 2), "foreign-map")
	)
	_check(
		not foreign_map["ok"] and not store.has_snapshot(),
		"projection store rejects an initial snapshot for a different map",
	)

func _store() -> RefCounted:
	return RecipientProjectionStore.new(
		"map-hash",
		Callable(self, "_coordinate_exists"),
	)

func _coordinate_exists(coordinate: Vector2i) -> bool:
	return coordinate.x >= 0 and coordinate.x < 10 and coordinate.y >= 0 and coordinate.y < 10

func _snapshot(
	revision: int,
	coordinate: Vector2i = Vector2i(1, 2),
	map_hash: String = "map-hash",
) -> AonwClientReadModels.SnapshotView:
	var result := AonwClientReadModels.SnapshotView.new()
	result.stamp = _stamp(revision, map_hash)
	result.turn = 7
	result.outcome = AonwClientReadModels.GameOutcomeView.new()
	result.outcome.condition = &"ongoing"
	result.outcome.score_by_player_id = {}.duplicate(true)
	result.outcome.score_by_player_id.make_read_only()
	result.turn_lifecycle = AonwClientReadModels.TurnLifecycleView.new()
	result.turn_lifecycle.has_own_state = true
	result.turn_lifecycle.own_state = &"active"
	result.turn_lifecycle.required_submission_count = 1
	result.diplomacy = _diplomacy()
	result.units = _units([_unit("unit-1", coordinate)])
	result.cities = _cities([])
	result.artifacts = _artifacts([])
	result.field_improvements = _improvements([])
	result.roads = _roads([])
	result.pending_action = AonwClientReadModels.PendingActionView.new()
	result.pending_action.kind = &"unitTurnSkip"
	result.pending_action.unit_id = "unit-1"
	result.pending_action.restore_movement_units = 2
	result.city_founding_draft = AonwClientReadModels.CityFoundingDraftView.new()
	result.city_founding_draft.founder_unit_id = "unit-1"
	result.city_founding_draft.center = Vector2i(3, 3)
	var controlled: Array[Vector2i] = [Vector2i(3, 4)]
	controlled.make_read_only()
	result.city_founding_draft.controlled_hexes = controlled
	return result

func _stamp(
	revision: int,
	map_hash: String = "map-hash",
) -> AonwClientReadModels.Stamp:
	var result := AonwClientReadModels.Stamp.new()
	result.revision = revision
	result.state_digest = "digest-%d" % revision
	result.map_hash = map_hash
	result.ruleset_hash = "ruleset-hash"
	return result

func _unit(id: String, coordinate: Vector2i) -> AonwClientReadModels.UnitView:
	var result := AonwClientReadModels.UnitView.new()
	result.id = id
	result.owner_player_id = "player-1"
	result.kind = "commander"
	result.display_name = "Commander"
	result.coordinate = coordinate
	result.movement_units = 8
	result.posture = "active"
	return result

func _patch(
	from_revision: int,
	to_revision: int,
	turn: int,
	pending_action: AonwClientReadModels.PendingActionView,
	founding_draft: AonwClientReadModels.CityFoundingDraftView,
) -> AonwClientReadModels.ViewPatch:
	var result := AonwClientReadModels.ViewPatch.new()
	result.from_revision = from_revision
	result.to_revision = to_revision
	result.turn = turn
	result.pending_action = pending_action
	result.city_founding_draft = founding_draft
	result.upserted_units = _units([])
	result.removed_unit_ids = _strings([])
	result.upserted_cities = _cities([])
	result.removed_city_ids = _strings([])
	result.upserted_artifacts = _artifacts([])
	result.removed_artifact_ids = _strings([])
	result.upserted_field_improvements = _improvements([])
	result.removed_field_improvement_coordinates = _coordinates([])
	result.upserted_roads = _roads([])
	result.removed_road_coordinates = _coordinates([])
	return result

func _command(
	accepted: bool,
	stamp: AonwClientReadModels.Stamp,
	patch: AonwClientReadModels.ViewPatch,
) -> AonwClientReadModels.CommandResult:
	var result := AonwClientReadModels.CommandResult.new()
	result.accepted = accepted
	result.stamp = stamp
	result.patch = patch
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

func _units(values: Array) -> Array[AonwClientReadModels.UnitView]:
	var result: Array[AonwClientReadModels.UnitView] = []
	for value in values:
		result.append(value)
	result.make_read_only()
	return result

func _cities(values: Array) -> Array[AonwClientReadModels.CityView]:
	var result: Array[AonwClientReadModels.CityView] = []
	for value in values:
		result.append(value)
	result.make_read_only()
	return result

func _artifacts(values: Array) -> Array[AonwClientReadModels.ArtifactView]:
	var result: Array[AonwClientReadModels.ArtifactView] = []
	for value in values:
		result.append(value)
	result.make_read_only()
	return result

func _improvements(values: Array) -> Array[AonwClientReadModels.FieldImprovementView]:
	var result: Array[AonwClientReadModels.FieldImprovementView] = []
	for value in values:
		result.append(value)
	result.make_read_only()
	return result

func _roads(values: Array) -> Array[AonwClientReadModels.RoadView]:
	var result: Array[AonwClientReadModels.RoadView] = []
	for value in values:
		result.append(value)
	result.make_read_only()
	return result

func _strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(value)
	result.make_read_only()
	return result

func _coordinates(values: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for value in values:
		result.append(value)
	result.make_read_only()
	return result

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
