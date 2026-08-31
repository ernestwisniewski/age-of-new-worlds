extends RefCounted

const ClientFailure := preload("res://game/application/session/client_failure.gd")
const RESYNC_REQUIRED := "recipient_resync_required"

var _coordinate_exists: Callable
var _expected_map_hash: String
var _snapshot: AonwClientReadModels.SnapshotView

func _init(expected_map_hash: String, coordinate_exists: Callable) -> void:
	assert(not expected_map_hash.is_empty(), "Recipient projection requires a map identity")
	assert(coordinate_exists.is_valid(), "Recipient projection requires map bounds")
	_expected_map_hash = expected_map_hash
	_coordinate_exists = coordinate_exists

func has_snapshot() -> bool:
	return _snapshot != null

func current() -> AonwClientReadModels.SnapshotView:
	return _snapshot

func clear() -> void:
	_snapshot = null

func open(snapshot: AonwClientReadModels.SnapshotView) -> Dictionary:
	if _snapshot != null:
		return _resync_required("Recipient projection is already open")
	if not _valid_snapshot(snapshot):
		return _resync_required("Recipient snapshot failed validation")
	_snapshot = snapshot
	return _success(snapshot, true)

func replace_after_resync(snapshot: AonwClientReadModels.SnapshotView) -> Dictionary:
	if _snapshot == null:
		return open(snapshot)
	if (
		not _valid_snapshot(snapshot)
		or not _same_static_identity(_snapshot.stamp, snapshot.stamp)
		or snapshot.stamp.revision < _snapshot.stamp.revision
	):
		return _resync_required("Recipient resync is incompatible with the cached projection")
	_snapshot = snapshot
	return _success(snapshot, true)

func apply_command(command: AonwClientReadModels.CommandResult) -> Dictionary:
	var before := _snapshot
	if before == null or command == null or command.patch == null:
		return _resync_required("Recipient command has no projection base")
	var patch := command.patch
	if (
		not _valid_stamp(command.stamp)
		or not _same_static_identity(before.stamp, command.stamp)
		or patch.from_revision != before.stamp.revision
		or patch.to_revision != command.stamp.revision
	):
		return _resync_required("Recipient patch does not continue the cached identity")
	if not command.accepted:
		if (
			command.stamp.revision != before.stamp.revision
			or command.stamp.state_digest != before.stamp.state_digest
			or _patch_changes_state(patch, before)
		):
			return _resync_required("Rejected command returned a mutating projection")
		return _success(before, false)
	if patch.to_revision == patch.from_revision:
		if (
			command.stamp.state_digest != before.stamp.state_digest
			or _patch_changes_state(patch, before)
		):
			return _resync_required("Accepted no-op returned a mutating projection")
		return _success(before, false)
	if patch.to_revision != patch.from_revision + 1:
		return _resync_required("Recipient patch skipped a revision")

	var units := _apply_collection(
		before.units,
		patch.upserted_units,
		patch.removed_unit_ids,
		false,
	)
	var cities := _apply_collection(
		before.cities,
		patch.upserted_cities,
		patch.removed_city_ids,
		false,
	)
	var artifacts := _apply_collection(
		before.artifacts,
		patch.upserted_artifacts,
		patch.removed_artifact_ids,
		false,
	)
	var improvements := _apply_collection(
		before.field_improvements,
		patch.upserted_field_improvements,
		patch.removed_field_improvement_coordinates,
		true,
	)
	var roads := _apply_collection(
		before.roads,
		patch.upserted_roads,
		patch.removed_road_coordinates,
		true,
	)
	for collection in [units, cities, artifacts, improvements, roads]:
		if not collection["ok"]:
			return _resync_required("Recipient patch contains an invalid collection delta")

	var after := AonwClientReadModels.SnapshotView.new()
	after.stamp = command.stamp
	after.turn = patch.turn
	after.outcome = before.outcome if patch.outcome == null else patch.outcome
	after.turn_lifecycle = (
		before.turn_lifecycle
		if patch.turn_lifecycle == null
		else patch.turn_lifecycle
	)
	after.pending_action = patch.pending_action
	after.city_founding_draft = patch.city_founding_draft
	after.diplomacy = before.diplomacy if patch.diplomacy == null else patch.diplomacy
	after.units = _unit_values(units["values"])
	after.cities = _city_values(cities["values"])
	after.artifacts = _artifact_values(artifacts["values"])
	after.field_improvements = _improvement_values(improvements["values"])
	after.roads = _road_values(roads["values"])
	if not _valid_snapshot(after):
		return _resync_required("Recipient patch produced an invalid projection")
	_snapshot = after
	return _success(after, true)

func _apply_collection(
	current: Array,
	upserted: Array,
	removed: Array,
	coordinate_key: bool,
) -> Dictionary:
	if (
		not _ordered_entities(upserted, coordinate_key)
		or not _ordered_keys(removed, coordinate_key)
	):
		return {"ok": false}
	var values: Dictionary = {}
	for value in current:
		values[_entity_key(value, coordinate_key)] = value
	var upserted_keys: Dictionary = {}
	for value in upserted:
		upserted_keys[_entity_key(value, coordinate_key)] = true
	for key in removed:
		if upserted_keys.has(key) or not values.erase(key):
			return {"ok": false}
	for value in upserted:
		values[_entity_key(value, coordinate_key)] = value
	return {"ok": true, "values": values}

func _valid_snapshot(snapshot: AonwClientReadModels.SnapshotView) -> bool:
	if (
		snapshot == null
		or not _valid_stamp(snapshot.stamp)
		or snapshot.stamp.map_hash != _expected_map_hash
		or snapshot.turn < 1
		or snapshot.outcome == null
		or snapshot.turn_lifecycle == null
		or snapshot.diplomacy == null
		or not _ordered_entities(snapshot.units, false)
		or not _ordered_entities(snapshot.cities, false)
		or not _ordered_entities(snapshot.artifacts, false)
		or not _ordered_entities(snapshot.field_improvements, true)
		or not _ordered_entities(snapshot.roads, true)
	):
		return false
	for unit in snapshot.units:
		if not _valid_unit(unit):
			return false
	for city in snapshot.cities:
		if not _valid_city(city):
			return false
	for artifact in snapshot.artifacts:
		if not _valid_artifact(artifact):
			return false
	for improvement in snapshot.field_improvements:
		if not _valid_coordinate(improvement.coordinate):
			return false
	for road in snapshot.roads:
		if not _valid_coordinate(road.coordinate):
			return false
	return (
		_valid_pending_action(snapshot.pending_action)
		and _valid_founding_draft(snapshot.city_founding_draft)
	)

func _valid_stamp(stamp: AonwClientReadModels.Stamp) -> bool:
	return (
		stamp != null
		and stamp.revision >= 0
		and not stamp.state_digest.is_empty()
		and not stamp.map_hash.is_empty()
		and not stamp.ruleset_hash.is_empty()
	)

func _same_static_identity(
	left: AonwClientReadModels.Stamp,
	right: AonwClientReadModels.Stamp,
) -> bool:
	return left.map_hash == right.map_hash and left.ruleset_hash == right.ruleset_hash

func _valid_unit(unit: AonwClientReadModels.UnitView) -> bool:
	if unit == null or unit.id.is_empty() or not _valid_coordinate(unit.coordinate):
		return false
	var details := unit.owned_details
	if details == null:
		return true
	if details.has_worker_assignment and not _valid_coordinate(details.worker_assignment):
		return false
	if details.worker_job != null and not _valid_coordinate(details.worker_job.target):
		return false
	if details.queued_path != null:
		if not _valid_coordinate(details.queued_path.target):
			return false
		for step in details.queued_path.steps:
			if not _valid_coordinate(step.coordinate):
				return false
	if details.merchant_trade_route != null:
		for step in details.merchant_trade_route.steps:
			if not _valid_coordinate(step.coordinate):
				return false
	var founding := details.city_founding_job
	return founding == null or (
		_valid_coordinate(founding.center)
		and _valid_coordinate_set(founding.controlled_hexes)
	)

func _valid_city(city: AonwClientReadModels.CityView) -> bool:
	if (
		city == null
		or city.id.is_empty()
		or not _valid_coordinate(city.center)
		or not _valid_coordinate_set(city.visible_controlled_hexes)
	):
		return false
	var details := city.owned_details
	return details == null or (
		_valid_coordinate_set(details.worked_hexes)
		and (
			not details.has_preferred_expansion_hex
			or _valid_coordinate(details.preferred_expansion_hex)
		)
	)

func _valid_artifact(artifact: AonwClientReadModels.ArtifactView) -> bool:
	if artifact == null or artifact.id.is_empty() or artifact.location == null:
		return false
	return (
		artifact.location.kind not in [&"map", &"excavation"]
		or _valid_coordinate(artifact.location.coordinate)
	)

func _valid_pending_action(action: AonwClientReadModels.PendingActionView) -> bool:
	return action == null or not action.has_defender or _valid_coordinate(action.defender)

func _valid_founding_draft(draft: AonwClientReadModels.CityFoundingDraftView) -> bool:
	return draft == null or (
		not draft.founder_unit_id.is_empty()
		and _valid_coordinate(draft.center)
		and _valid_coordinate_set(draft.controlled_hexes)
	)

func _valid_coordinate_set(coordinates: Array[Vector2i]) -> bool:
	var seen: Dictionary = {}
	for coordinate in coordinates:
		if not _valid_coordinate(coordinate) or seen.has(coordinate):
			return false
		seen[coordinate] = true
	return true

func _valid_coordinate(coordinate: Vector2i) -> bool:
	return bool(_coordinate_exists.call(coordinate))

func _ordered_entities(values: Array, coordinate_key: bool) -> bool:
	var keys: Array = []
	for value in values:
		if value == null:
			return false
		keys.append(_entity_key(value, coordinate_key))
	return _ordered_keys(keys, coordinate_key)

func _ordered_keys(keys: Array, coordinate_key: bool) -> bool:
	var previous: Variant = null
	for key in keys:
		if not _valid_key(key, coordinate_key):
			return false
		if previous != null and not _key_less(previous, key, coordinate_key):
			return false
		previous = key
	return true

func _valid_key(key: Variant, coordinate_key: bool) -> bool:
	if coordinate_key:
		return key is Vector2i and _valid_coordinate(key)
	return key is String and not key.is_empty()

func _key_less(left: Variant, right: Variant, coordinate_key: bool) -> bool:
	if coordinate_key:
		return left.x < right.x or (left.x == right.x and left.y < right.y)
	return left < right

func _entity_key(value: Variant, coordinate_key: bool) -> Variant:
	return value.coordinate if coordinate_key else value.id

func _patch_changes_state(
	patch: AonwClientReadModels.ViewPatch,
	before: AonwClientReadModels.SnapshotView,
) -> bool:
	return (
		patch.turn != before.turn
		or patch.turn_lifecycle != null
		or patch.outcome != null
		or patch.diplomacy != null
		or not _same_pending_action(patch.pending_action, before.pending_action)
		or not _same_founding_draft(patch.city_founding_draft, before.city_founding_draft)
		or not patch.upserted_units.is_empty()
		or not patch.removed_unit_ids.is_empty()
		or not patch.upserted_cities.is_empty()
		or not patch.removed_city_ids.is_empty()
		or not patch.upserted_artifacts.is_empty()
		or not patch.removed_artifact_ids.is_empty()
		or not patch.upserted_field_improvements.is_empty()
		or not patch.removed_field_improvement_coordinates.is_empty()
		or not patch.upserted_roads.is_empty()
		or not patch.removed_road_coordinates.is_empty()
	)

func _same_pending_action(
	left: AonwClientReadModels.PendingActionView,
	right: AonwClientReadModels.PendingActionView,
) -> bool:
	if left == right:
		return true
	return (
		left != null
		and right != null
		and left.kind == right.kind
		and left.city_id == right.city_id
		and left.unit_id == right.unit_id
		and left.improvement == right.improvement
		and left.restore_movement_units == right.restore_movement_units
		and left.has_defender == right.has_defender
		and (not left.has_defender or left.defender == right.defender)
	)

func _same_founding_draft(
	left: AonwClientReadModels.CityFoundingDraftView,
	right: AonwClientReadModels.CityFoundingDraftView,
) -> bool:
	return left == right or (
		left != null
		and right != null
		and left.founder_unit_id == right.founder_unit_id
		and left.center == right.center
		and left.controlled_hexes == right.controlled_hexes
	)

func _unit_values(values: Dictionary) -> Array[AonwClientReadModels.UnitView]:
	var result: Array[AonwClientReadModels.UnitView] = []
	for key in _sorted_keys(values, false):
		result.append(values[key])
	result.make_read_only()
	return result

func _city_values(values: Dictionary) -> Array[AonwClientReadModels.CityView]:
	var result: Array[AonwClientReadModels.CityView] = []
	for key in _sorted_keys(values, false):
		result.append(values[key])
	result.make_read_only()
	return result

func _artifact_values(values: Dictionary) -> Array[AonwClientReadModels.ArtifactView]:
	var result: Array[AonwClientReadModels.ArtifactView] = []
	for key in _sorted_keys(values, false):
		result.append(values[key])
	result.make_read_only()
	return result

func _improvement_values(
	values: Dictionary,
) -> Array[AonwClientReadModels.FieldImprovementView]:
	var result: Array[AonwClientReadModels.FieldImprovementView] = []
	for key in _sorted_keys(values, true):
		result.append(values[key])
	result.make_read_only()
	return result

func _road_values(values: Dictionary) -> Array[AonwClientReadModels.RoadView]:
	var result: Array[AonwClientReadModels.RoadView] = []
	for key in _sorted_keys(values, true):
		result.append(values[key])
	result.make_read_only()
	return result

func _sorted_keys(values: Dictionary, coordinate_key: bool) -> Array:
	var keys := values.keys()
	if coordinate_key:
		keys.sort_custom(_coordinate_less)
	else:
		keys.sort()
	return keys

func _coordinate_less(left: Vector2i, right: Vector2i) -> bool:
	return left.x < right.x or (left.x == right.x and left.y < right.y)

func _success(value: AonwClientReadModels.SnapshotView, changed: bool) -> Dictionary:
	return {"ok": true, "value": value, "changed": changed}

func _resync_required(message: String) -> Dictionary:
	return ClientFailure.result(RESYNC_REQUIRED, message)
