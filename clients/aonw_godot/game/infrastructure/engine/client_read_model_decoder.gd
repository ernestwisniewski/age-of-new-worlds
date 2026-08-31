extends RefCounted

const ReadModels := preload("res://game/application/session/client_read_models.gd")
const ClientEventSchema := preload("res://game/infrastructure/engine/client_event_schema.gd")
const ClientCommandSchema := preload("res://game/infrastructure/engine/client_command_schema.gd")
const UNIT_KINDS := [
	"commander", "warrior", "archer", "settler", "worker", "merchant", "scout",
	"spearman", "cavalry", "catapult", "heavyInfantry", "fieldCannon", "rifleman",
	"tank", "scoutShip", "warship", "reconPlane",
]
const UNIT_POSTURES := ["active", "fortified", "autoExploring", "autoWorking"]
const TROOP_KINDS := ["warrior", "archer", "settler"]
const CITY_SPECIALIZATIONS := ["growth", "industry", "commerce", "science", "military"]
const CITY_PROJECTS := ["wealth", "research"]
const WONDER_TYPES := [
	"greatLibrary", "hangingGardens", "greatWall", "petra", "centralBank",
	"imperialUniversity", "grandCathedral", "motherFactory", "nationalObservatory",
	"svalbardSeedVault", "grandExposition",
]
const CITY_BUILDINGS := [
	"granary", "waterMill", "workshop", "storehouse", "housing", "merchantHall",
	"stonemason", "barracks", "marketplace", "port", "aqueduct", "forge", "stable",
	"bank", "buildersGuild", "factory", "lighthouse", "trainingGrounds", "townHall",
	"monument", "archive", "academy", "university", "observatory", "laboratory",
	"reactor", "courthouse", "court", "governorsOffice", "surveyorsOffice",
	"planningOffice", "apothecary", "publicBaths", "hospital", "ministries", "walls",
	"armory", "siegeWorkshop", "citadel", "warCollege", "conscriptionOffice",
	"borderFort", "airfield", "artisansGuild", "masterWorkshop", "steelworks",
	"railDepot", "powerPlant", "assemblyPlant", "refinery", "mapRoom", "shipyard",
	"dryDock", "navalAcademy", "harborCustoms", "museum", "parliament",
	"broadcastTower", "worldFairGrounds",
]
const PLAYER_TURN_STATES := ["active", "finished"]
const GAME_OUTCOME_CONDITIONS := [
	"ongoing", "conquest", "domination", "cultural", "score", "resignation", "draw",
]
const ARTIFACT_TYPES := [
	"ancientImperialCrown", "astronomersTablets", "prophetMask", "heroSword",
	"merchantsSeal", "firstPeoplesChronicle", "templeReliquary", "queensMirror",
]
const DIPLOMATIC_RELATION_STATUSES := ["friendly", "neutral", "hostile", "truce", "war"]
const DIPLOMATIC_RELATION_CHANGE_REASONS := [
	"manual", "unitAttack", "cityAttack", "declarationOfWar", "proposalAccepted",
	"truceExpired", "messageResponse", "promiseBroken",
]
const DIPLOMATIC_PROPOSAL_KINDS := ["friendship", "truce"]
const DIPLOMATIC_MESSAGE_CATEGORIES := [
	"warning", "complaint", "request", "praise", "threat", "cooperation",
]
const DIPLOMATIC_MESSAGE_TOPICS := [
	"troopsNearCities", "citiesTooClose", "blockedRoutes", "withdrawScouts",
	"avoidEscalation", "commonEnemy", "expansionProvocation", "peacefulPraise",
]
const DIPLOMATIC_MESSAGE_RESPONSES := ["conciliatory", "neutral", "evasive", "aggressive"]
const RESOURCE_TYPES := [
	"wheat", "fish", "deer", "sheep", "rice", "cow", "apple", "banana", "citrus",
	"gold", "silver", "gems", "silk", "spices", "cotton", "grapes", "ivory",
	"pearls", "coffee", "cocoa", "tobacco", "sugar", "iron", "coal", "oil",
	"aluminium", "uranium", "horses", "marble",
]
const TRANSPORT_CONDITIONS := ["operational", "pillaged"]
const FIELD_IMPROVEMENTS := [
	"farm", "riverFarm", "mine", "lumberMill", "pasture", "camp", "quarry",
	"fishingBoats", "orchard", "plantation", "vineyard", "tradingPost",
	"prospectorCamp", "horseRanch", "pearlDivers", "coalShaft", "oilWell",
	"bauxiteMine", "uraniumMine",
]
static func decode_stamp(raw: Variant) -> AonwClientReadModels.Stamp:
	if not _has_exact_fields(raw, [
		"revision", "stateDigest", "mapHash", "rulesetHash",
	]):
		return null
	if not _strings(raw, ["stateDigest", "mapHash", "rulesetHash"]):
		return null
	if not _integers(raw, ["revision"], true):
		return null
	var result := ReadModels.Stamp.new()
	result.revision = int(raw["revision"])
	result.state_digest = raw["stateDigest"]
	result.map_hash = raw["mapHash"]
	result.ruleset_hash = raw["rulesetHash"]
	return result

static func decode_snapshot(raw: Variant) -> AonwClientReadModels.SnapshotView:
	if not _has_exact_fields(raw, [
		"stamp", "turn", "outcome", "turnLifecycle", "pendingAction", "cityFoundingDraft",
		"diplomacy", "units", "cities", "artifacts", "fieldImprovements", "roads",
	]):
		return null
	if not _arrays(raw, ["units", "cities", "artifacts", "fieldImprovements", "roads"]):
		return null
	if not _integers(raw, ["turn"], true) or int(raw["turn"]) < 1:
		return null
	var stamp := decode_stamp(raw["stamp"])
	var outcome := _decode_game_outcome(raw["outcome"])
	var turn_lifecycle := _decode_turn_lifecycle(raw["turnLifecycle"])
	var pending_action := _decode_pending_action(raw["pendingAction"])
	var city_founding_draft := _decode_city_founding_draft(raw["cityFoundingDraft"])
	var diplomacy := _decode_diplomacy(raw["diplomacy"])
	if (
		stamp == null
		or outcome == null
		or turn_lifecycle == null
		or diplomacy == null
		or (raw["pendingAction"] != null and pending_action == null)
		or (raw["cityFoundingDraft"] != null and city_founding_draft == null)
	):
		return null
	var units: Array[AonwClientReadModels.UnitView] = []
	var previous_id := ""
	for value in raw["units"]:
		var unit := _decode_unit(value)
		if unit == null or (not previous_id.is_empty() and unit.id <= previous_id):
			return null
		units.append(unit)
		previous_id = unit.id
	units.make_read_only()
	var cities: Variant = _decode_cities(raw["cities"])
	var artifacts: Variant = _decode_artifacts(raw["artifacts"])
	var field_improvements: Variant = _decode_field_improvements(raw["fieldImprovements"])
	var roads: Variant = _decode_roads(raw["roads"])
	if cities == null or artifacts == null or field_improvements == null or roads == null:
		return null
	var result := ReadModels.SnapshotView.new()
	result.stamp = stamp
	result.turn = int(raw["turn"])
	result.outcome = outcome
	result.turn_lifecycle = turn_lifecycle
	result.pending_action = pending_action
	result.city_founding_draft = city_founding_draft
	result.diplomacy = diplomacy
	result.units = units
	result.cities = cities
	result.artifacts = artifacts
	result.field_improvements = field_improvements
	result.roads = roads
	return result

static func decode_reachable(raw: Variant) -> AonwClientReadModels.ReachableView:
	if not _has_exact_fields(raw, [
		"type", "stamp", "unitId", "availableMovementUnits", "tiles",
	]) or raw["type"] != "reachable" or not raw["tiles"] is Array:
		return null
	if not raw["unitId"] is String or raw["unitId"].is_empty():
		return null
	if not _integers(raw, ["availableMovementUnits"], true):
		return null
	var stamp := decode_stamp(raw["stamp"])
	if stamp == null:
		return null
	var tiles: Array[AonwClientReadModels.ReachableTile] = []
	for tile in raw["tiles"]:
		if not _has_exact_fields(tile, ["coordinate", "costUnits", "exhaustsMovement"]):
			return null
		if not tile["exhaustsMovement"] is bool:
			return null
		if not _integers(tile, ["costUnits"], true):
			return null
		var coordinate: Variant = _decode_coordinate(tile["coordinate"])
		if coordinate == null:
			return null
		var tile_view := ReadModels.ReachableTile.new()
		tile_view.coordinate = coordinate
		tile_view.cost_units = int(tile["costUnits"])
		tile_view.exhausts_movement = tile["exhaustsMovement"]
		tiles.append(tile_view)
	tiles.make_read_only()
	var result := ReadModels.ReachableView.new()
	result.stamp = stamp
	result.unit_id = raw["unitId"]
	result.available_movement_units = int(raw["availableMovementUnits"])
	result.tiles = tiles
	return result

static func decode_route_plan(raw: Variant) -> AonwClientReadModels.RoutePlanView:
	if not _has_exact_fields(raw, [
		"type", "stamp", "unitId", "target", "destination", "totalCostUnits",
		"availableMovementUnits", "remainingMovementUnits", "steps",
	]) or raw["type"] != "routePlan" or not raw["steps"] is Array:
		return null
	if not raw["unitId"] is String or raw["unitId"].is_empty():
		return null
	if not _integers(raw, [
		"totalCostUnits", "availableMovementUnits", "remainingMovementUnits",
	], true):
		return null
	var stamp := decode_stamp(raw["stamp"])
	var target: Variant = _decode_coordinate(raw["target"])
	var destination: Variant = _decode_coordinate(raw["destination"])
	if stamp == null or target == null or destination == null:
		return null
	var steps: Variant = _decode_steps(raw["steps"])
	if (
		steps == null
		or steps.is_empty()
		or steps[0].enter_cost_units != 0
		or steps[0].cumulative_cost_units != 0
		or steps[-1].coordinate != destination
		or steps[-1].cumulative_cost_units != int(raw["totalCostUnits"])
		or int(raw["remainingMovementUnits"]) > int(raw["availableMovementUnits"])
	):
		return null
	var result := ReadModels.RoutePlanView.new()
	result.stamp = stamp
	result.unit_id = raw["unitId"]
	result.target = target
	result.destination = destination
	result.total_cost_units = int(raw["totalCostUnits"])
	result.available_movement_units = int(raw["availableMovementUnits"])
	result.remaining_movement_units = int(raw["remainingMovementUnits"])
	result.steps = steps
	return result

static func decode_command(raw: Variant) -> AonwClientReadModels.CommandResult:
	if not _has_exact_fields(raw, [
		"stamp", "outcome", "events", "evidence", "viewPatch",
	]):
		return null
	var stamp := decode_stamp(raw["stamp"])
	var patch := _decode_patch(raw["viewPatch"])
	if not raw["events"] is Array:
		return null
	var events: Variant = _decode_events(raw["events"])
	var evidence: Variant = _decode_evidence(raw["evidence"])
	if stamp == null or patch == null or (raw["evidence"] != null and evidence == null):
		return null
	if events == null:
		return null
	var outcome: Variant = raw["outcome"]
	if not outcome is Dictionary:
		return null
	var accepted := false
	var rejection := &""
	match outcome.get("status", ""):
		"accepted":
			if not _has_exact_fields(outcome, ["status"]):
				return null
			accepted = true
		"rejected":
			if (
				not _has_exact_fields(outcome, ["status", "code"])
				or not outcome["code"] is String
				or not ClientCommandSchema.REJECTION_CODES.has(outcome["code"])
			):
				return null
			rejection = StringName(outcome["code"])
		_:
			return null
	var result := ReadModels.CommandResult.new()
	result.stamp = stamp
	result.accepted = accepted
	result.rejection = rejection
	result.events = events
	result.patch = patch
	result.evidence = evidence
	return result

static func _decode_unit(raw: Variant) -> AonwClientReadModels.UnitView:
	if not _has_exact_fields(raw, [
		"id", "ownerPlayerId", "kind", "name", "coordinate", "movementUnits", "posture",
		"hitPoints", "carriedArtifactId", "ownedDetails",
	]):
		return null
	if not _strings(raw, ["id", "ownerPlayerId", "kind", "name", "posture"]):
		return null
	if (
		raw["id"].is_empty()
		or raw["ownerPlayerId"].is_empty()
		or raw["name"].is_empty()
		or not UNIT_KINDS.has(raw["kind"])
		or not UNIT_POSTURES.has(raw["posture"])
	):
		return null
	if (
		not _integers(raw, ["movementUnits"], true)
		or not _is_nullable_integer(raw["hitPoints"], true)
		or (
			raw["carriedArtifactId"] != null
			and (not raw["carriedArtifactId"] is String or raw["carriedArtifactId"].is_empty())
		)
	):
		return null
	var coordinate: Variant = _decode_coordinate(raw["coordinate"])
	var owned_details := _decode_owned_unit_details(raw["ownedDetails"])
	if (
		coordinate == null
		or (raw["ownedDetails"] != null and owned_details == null)
	):
		return null
	var result := ReadModels.UnitView.new()
	result.id = raw["id"]
	result.owner_player_id = raw["ownerPlayerId"]
	result.kind = raw["kind"]
	result.display_name = raw["name"]
	result.coordinate = coordinate
	result.movement_units = int(raw["movementUnits"])
	result.posture = raw["posture"]
	result.has_hit_points = raw["hitPoints"] != null
	if result.has_hit_points:
		result.hit_points = int(raw["hitPoints"])
	result.has_carried_artifact_id = raw["carriedArtifactId"] != null
	if result.has_carried_artifact_id:
		result.carried_artifact_id = raw["carriedArtifactId"]
	result.owned_details = owned_details
	if owned_details != null:
		result.worker_build_charges = owned_details.worker_build_charges
		result.worker_job = owned_details.worker_job
		result.has_worker_assignment = owned_details.has_worker_assignment
		if result.has_worker_assignment:
			result.worker_assignment = owned_details.worker_assignment
	return result

static func _decode_owned_unit_details(
	raw: Variant,
) -> AonwClientReadModels.OwnedUnitDetailsView:
	if raw == null:
		return null
	if not _has_exact_fields(raw, [
		"army", "queuedPath", "merchantTradeRoute", "workerJob", "cityFoundingJob",
		"workerAssignment", "excavatingArtifactId", "workerBuildCharges", "experiencePoints",
	]):
		return null
	if (
		not raw["army"] is Array
		or not _integers(raw, ["workerBuildCharges", "experiencePoints"], true)
		or (
			raw["excavatingArtifactId"] != null
			and (
				not raw["excavatingArtifactId"] is String
				or raw["excavatingArtifactId"].is_empty()
			)
		)
	):
		return null
	var army: Array[AonwClientReadModels.ArmyTroopView] = []
	for value: Variant in raw["army"]:
		if (
			not _has_exact_fields(value, ["kind", "count"])
			or not value["kind"] is String
			or not TROOP_KINDS.has(value["kind"])
			or not _integers(value, ["count"], true)
		):
			return null
		var troop := ReadModels.ArmyTroopView.new()
		troop.kind = StringName(value["kind"])
		troop.count = int(value["count"])
		army.append(troop)
	army.make_read_only()
	var queued_path := _decode_queued_path(raw["queuedPath"])
	var merchant_route := _decode_merchant_route(raw["merchantTradeRoute"])
	var worker_job := _decode_worker_job(raw["workerJob"])
	var founding_job := _decode_city_founding_job(raw["cityFoundingJob"])
	var worker_assignment: Variant = null
	if raw["workerAssignment"] != null:
		worker_assignment = _decode_coordinate(raw["workerAssignment"])
	if (
		(raw["queuedPath"] != null and queued_path == null)
		or (raw["merchantTradeRoute"] != null and merchant_route == null)
		or (raw["workerJob"] != null and worker_job == null)
		or (raw["cityFoundingJob"] != null and founding_job == null)
		or (raw["workerAssignment"] != null and worker_assignment == null)
	):
		return null
	var result := ReadModels.OwnedUnitDetailsView.new()
	result.army = army
	result.queued_path = queued_path
	result.merchant_trade_route = merchant_route
	result.worker_job = worker_job
	result.city_founding_job = founding_job
	result.has_worker_assignment = worker_assignment != null
	if result.has_worker_assignment:
		result.worker_assignment = worker_assignment
	result.has_excavating_artifact_id = raw["excavatingArtifactId"] != null
	if result.has_excavating_artifact_id:
		result.excavating_artifact_id = raw["excavatingArtifactId"]
	result.worker_build_charges = int(raw["workerBuildCharges"])
	result.experience_points = int(raw["experiencePoints"])
	return result

static func _decode_queued_path(raw: Variant) -> AonwClientReadModels.QueuedMovePathView:
	if raw == null:
		return null
	if (
		not _has_exact_fields(raw, ["targetCol", "targetRow", "steps"])
		or not _integers(raw, ["targetCol", "targetRow"], false)
		or not raw["steps"] is Array
	):
		return null
	var steps: Variant = _decode_persisted_steps(raw["steps"])
	if steps == null:
		return null
	var result := ReadModels.QueuedMovePathView.new()
	result.target = Vector2i(int(raw["targetCol"]), int(raw["targetRow"]))
	result.steps = steps
	return result

static func _decode_merchant_route(
	raw: Variant,
) -> AonwClientReadModels.MerchantTradeRouteView:
	if raw == null:
		return null
	if not _has_exact_fields(raw, [
		"originCityId", "destinationCityId", "steps", "transportNetworkFingerprint",
	]):
		return null
	if not _strings(raw, [
		"originCityId", "destinationCityId", "transportNetworkFingerprint",
	]) or not raw["steps"] is Array:
		return null
	if raw["originCityId"].is_empty() or raw["destinationCityId"].is_empty():
		return null
	var steps: Variant = _decode_persisted_steps(raw["steps"])
	if steps == null:
		return null
	var result := ReadModels.MerchantTradeRouteView.new()
	result.origin_city_id = raw["originCityId"]
	result.destination_city_id = raw["destinationCityId"]
	result.steps = steps
	result.transport_network_fingerprint = raw["transportNetworkFingerprint"]
	return result

static func _decode_persisted_steps(raw: Array) -> Variant:
	var steps: Array[AonwClientReadModels.PersistedMovementStepView] = []
	for value: Variant in raw:
		if (
			not _has_exact_fields(value, [
				"col", "row", "enterCostUnits", "cumulativeCostUnits",
			])
			or not _integers(value, ["col", "row"], false)
			or not _integers(value, ["enterCostUnits", "cumulativeCostUnits"], true)
		):
			return null
		var step := ReadModels.PersistedMovementStepView.new()
		step.coordinate = Vector2i(int(value["col"]), int(value["row"]))
		step.enter_cost_units = int(value["enterCostUnits"])
		step.cumulative_cost_units = int(value["cumulativeCostUnits"])
		steps.append(step)
	steps.make_read_only()
	return steps

static func _decode_city_founding_job(
	raw: Variant,
) -> AonwClientReadModels.CityFoundingJobView:
	if raw == null:
		return null
	if not _has_exact_fields(raw, [
		"center", "controlledHexes", "remainingTurns", "totalTurns",
	]) or not raw["controlledHexes"] is Array:
		return null
	if not _integers(raw, ["remainingTurns", "totalTurns"], true):
		return null
	var center: Variant = _decode_coordinate(raw["center"])
	var controlled: Variant = _decode_coordinates(raw["controlledHexes"])
	if center == null or controlled == null:
		return null
	var result := ReadModels.CityFoundingJobView.new()
	result.center = center
	result.controlled_hexes = controlled
	result.remaining_turns = int(raw["remainingTurns"])
	result.total_turns = int(raw["totalTurns"])
	return result

static func _decode_worker_job(raw: Variant) -> AonwClientReadModels.WorkerJobView:
	if raw == null:
		return null
	if not raw is Dictionary or not raw.get("type") is String:
		return null
	var fields := ["type", "target", "remainingTurns", "totalTurns"]
	if raw["type"] == "fieldImprovement":
		fields.insert(2, "improvement")
	elif raw["type"] != "roadConstruction":
		return null
	if not _has_exact_fields(raw, fields):
		return null
	if not _integers(raw, ["remainingTurns", "totalTurns"], true):
		return null
	var target: Variant = _decode_coordinate(raw["target"])
	if target == null:
		return null
	var improvement := &""
	if raw["type"] == "fieldImprovement":
		if not raw["improvement"] is String or not FIELD_IMPROVEMENTS.has(raw["improvement"]):
			return null
		improvement = StringName(raw["improvement"])
	var result := ReadModels.WorkerJobView.new()
	result.kind = StringName(raw["type"])
	result.target = target
	result.improvement = improvement
	result.remaining_turns = int(raw["remainingTurns"])
	result.total_turns = int(raw["totalTurns"])
	return result

static func _decode_turn_lifecycle(raw: Variant) -> AonwClientReadModels.TurnLifecycleView:
	if not _has_exact_fields(raw, [
		"ownState", "ownSubmitted", "requiredSubmissionCount", "submittedCount",
	]):
		return null
	if not raw["ownSubmitted"] is bool:
		return null
	if not _integers(raw, ["requiredSubmissionCount", "submittedCount"], true):
		return null
	if (
		raw["ownState"] != null
		and (not raw["ownState"] is String or not PLAYER_TURN_STATES.has(raw["ownState"]))
	):
		return null
	var result := ReadModels.TurnLifecycleView.new()
	result.has_own_state = raw["ownState"] != null
	if raw["ownState"] != null:
		result.own_state = StringName(raw["ownState"])
	result.own_submitted = raw["ownSubmitted"]
	result.required_submission_count = int(raw["requiredSubmissionCount"])
	result.submitted_count = int(raw["submittedCount"])
	return result

static func _decode_game_outcome(raw: Variant) -> AonwClientReadModels.GameOutcomeView:
	if not _has_exact_fields(raw, ["condition", "winnerPlayerId", "scoreByPlayerId"]):
		return null
	if not raw["condition"] is String or not GAME_OUTCOME_CONDITIONS.has(raw["condition"]):
		return null
	if (
		raw["winnerPlayerId"] != null
		and (not raw["winnerPlayerId"] is String or raw["winnerPlayerId"].is_empty())
	):
		return null
	if not raw["scoreByPlayerId"] is Dictionary:
		return null
	var scores: Dictionary = {}
	for player_id: Variant in raw["scoreByPlayerId"]:
		var score: Variant = raw["scoreByPlayerId"][player_id]
		if not player_id is String or player_id.is_empty() or not _is_integer(score, true):
			return null
		scores[player_id] = int(score)
	scores.make_read_only()
	var result := ReadModels.GameOutcomeView.new()
	result.condition = StringName(raw["condition"])
	result.has_winner_player_id = raw["winnerPlayerId"] != null
	if raw["winnerPlayerId"] != null:
		result.winner_player_id = raw["winnerPlayerId"]
	result.score_by_player_id = scores
	return result

static func _decode_artifacts(raw: Array) -> Variant:
	var artifacts: Array[AonwClientReadModels.ArtifactView] = []
	var previous_id := ""
	for value: Variant in raw:
		var artifact := _decode_artifact(value)
		if artifact == null or (not previous_id.is_empty() and artifact.id <= previous_id):
			return null
		artifacts.append(artifact)
		previous_id = artifact.id
	artifacts.make_read_only()
	return artifacts

static func _decode_artifact(raw: Variant) -> AonwClientReadModels.ArtifactView:
	if not _has_exact_fields(raw, ["id", "type", "location"]):
		return null
	if (
		not raw["id"] is String
		or raw["id"].is_empty()
		or not raw["type"] is String
		or not ARTIFACT_TYPES.has(raw["type"])
	):
		return null
	var location := _decode_artifact_location(raw["location"])
	if location == null:
		return null
	var result := ReadModels.ArtifactView.new()
	result.id = raw["id"]
	result.artifact_type = StringName(raw["type"])
	result.location = location
	return result

static func _decode_artifact_location(raw: Variant) -> AonwClientReadModels.ArtifactLocationView:
	if not raw is Dictionary or not raw.get("kind") is String:
		return null
	var result := ReadModels.ArtifactLocationView.new()
	result.kind = StringName(raw["kind"])
	match raw["kind"]:
		"map":
			if not _has_exact_fields(raw, ["kind", "coordinate"]):
				return null
			var coordinate: Variant = _decode_coordinate(raw["coordinate"])
			if coordinate == null:
				return null
			result.coordinate = coordinate
		"carried":
			if not _has_exact_fields(raw, ["kind", "unitId"]) or not _valid_unit_id(raw["unitId"]):
				return null
			result.unit_id = raw["unitId"]
		"stored":
			if (
				not _has_exact_fields(raw, ["kind", "cityId"])
				or not raw["cityId"] is String
				or raw["cityId"].is_empty()
			):
				return null
			result.city_id = raw["cityId"]
		"excavation":
			if not _has_exact_fields(raw, ["kind", "unitId", "coordinate", "remainingTurns"]):
				return null
			if (
				not _valid_unit_id(raw["unitId"])
				or not _integers(raw, ["remainingTurns"], true)
				or int(raw["remainingTurns"]) == 0
			):
				return null
			var coordinate: Variant = _decode_coordinate(raw["coordinate"])
			if coordinate == null:
				return null
			result.unit_id = raw["unitId"]
			result.coordinate = coordinate
			result.remaining_turns = int(raw["remainingTurns"])
		_:
			return null
	return result

static func _decode_diplomacy(raw: Variant) -> AonwClientReadModels.DiplomacyView:
	if not _has_exact_fields(raw, [
		"relations", "proposals", "messages", "resourceTradeAgreements",
	]):
		return null
	if not _arrays(raw, ["relations", "proposals", "messages", "resourceTradeAgreements"]):
		return null
	var relations: Array[AonwClientReadModels.DiplomaticRelationView] = []
	for value: Variant in raw["relations"]:
		var relation := _decode_diplomatic_relation(value)
		if relation == null:
			return null
		relations.append(relation)
	var proposals: Array[AonwClientReadModels.DiplomaticProposalView] = []
	for value: Variant in raw["proposals"]:
		var proposal := _decode_diplomatic_proposal(value)
		if proposal == null:
			return null
		proposals.append(proposal)
	var messages: Array[AonwClientReadModels.DiplomaticMessageView] = []
	for value: Variant in raw["messages"]:
		var message := _decode_diplomatic_message(value)
		if message == null:
			return null
		messages.append(message)
	var agreements: Array[AonwClientReadModels.ResourceTradeAgreementView] = []
	for value: Variant in raw["resourceTradeAgreements"]:
		var agreement := _decode_resource_trade_agreement(value)
		if agreement == null:
			return null
		agreements.append(agreement)
	relations.make_read_only()
	proposals.make_read_only()
	messages.make_read_only()
	agreements.make_read_only()
	var result := ReadModels.DiplomacyView.new()
	result.relations = relations
	result.proposals = proposals
	result.messages = messages
	result.resource_trade_agreements = agreements
	return result

static func _decode_diplomatic_relation(
	raw: Variant,
) -> AonwClientReadModels.DiplomaticRelationView:
	if not _has_exact_fields(raw, [
		"counterpartPlayerId", "status", "relationScore", "statusExpiresOnTurn",
		"lastChangedTurn", "lastChangeReason",
	]):
		return null
	if (
		not raw["counterpartPlayerId"] is String
		or raw["counterpartPlayerId"].is_empty()
		or not raw["status"] is String
		or not DIPLOMATIC_RELATION_STATUSES.has(raw["status"])
		or not _is_integer(raw["relationScore"], false)
		or int(raw["relationScore"]) < -100
		or int(raw["relationScore"]) > 100
		or not _is_nullable_integer(raw["statusExpiresOnTurn"], true)
		or not _is_nullable_integer(raw["lastChangedTurn"], true)
	):
		return null
	if (
		raw["lastChangeReason"] != null
		and (
			not raw["lastChangeReason"] is String
			or not DIPLOMATIC_RELATION_CHANGE_REASONS.has(raw["lastChangeReason"])
		)
	):
		return null
	var result := ReadModels.DiplomaticRelationView.new()
	result.counterpart_player_id = raw["counterpartPlayerId"]
	result.status = StringName(raw["status"])
	result.relation_score = int(raw["relationScore"])
	result.has_status_expires_on_turn = raw["statusExpiresOnTurn"] != null
	if result.has_status_expires_on_turn:
		result.status_expires_on_turn = int(raw["statusExpiresOnTurn"])
	result.has_last_changed_turn = raw["lastChangedTurn"] != null
	if result.has_last_changed_turn:
		result.last_changed_turn = int(raw["lastChangedTurn"])
	if raw["lastChangeReason"] != null:
		result.last_change_reason = StringName(raw["lastChangeReason"])
	return result

static func _decode_diplomatic_proposal(
	raw: Variant,
) -> AonwClientReadModels.DiplomaticProposalView:
	if not _has_exact_fields(raw, [
		"id", "fromPlayerId", "toPlayerId", "kind", "createdTurn", "expiresOnTurn",
		"goldPayment",
	]):
		return null
	if not _strings(raw, ["id", "fromPlayerId", "toPlayerId", "kind"]):
		return null
	if (
		raw["id"].is_empty()
		or raw["fromPlayerId"].is_empty()
		or raw["toPlayerId"].is_empty()
		or raw["fromPlayerId"] == raw["toPlayerId"]
		or not DIPLOMATIC_PROPOSAL_KINDS.has(raw["kind"])
		or not _integers(raw, ["createdTurn", "expiresOnTurn"], true)
		or int(raw["expiresOnTurn"]) <= int(raw["createdTurn"])
		or not _integers(raw, ["goldPayment"], true)
	):
		return null
	var result := ReadModels.DiplomaticProposalView.new()
	result.id = raw["id"]
	result.from_player_id = raw["fromPlayerId"]
	result.to_player_id = raw["toPlayerId"]
	result.kind = StringName(raw["kind"])
	result.created_turn = int(raw["createdTurn"])
	result.expires_on_turn = int(raw["expiresOnTurn"])
	result.gold_payment = int(raw["goldPayment"])
	return result

static func _decode_diplomatic_message(
	raw: Variant,
) -> AonwClientReadModels.DiplomaticMessageView:
	if not _has_exact_fields(raw, [
		"id", "fromPlayerId", "toPlayerId", "topic", "category", "createdTurn",
		"expiresOnTurn", "response", "respondedTurn", "relationScoreDelta",
		"relationScoreAfter", "promiseDueTurn", "promiseBroken",
	]):
		return null
	if not _strings(raw, ["id", "fromPlayerId", "toPlayerId", "topic", "category"]):
		return null
	if (
		raw["id"].is_empty()
		or raw["fromPlayerId"].is_empty()
		or raw["toPlayerId"].is_empty()
		or raw["fromPlayerId"] == raw["toPlayerId"]
		or not DIPLOMATIC_MESSAGE_TOPICS.has(raw["topic"])
		or not DIPLOMATIC_MESSAGE_CATEGORIES.has(raw["category"])
		or StringName(raw["category"]) != _message_category(raw["topic"])
		or not _integers(raw, ["createdTurn", "expiresOnTurn"], true)
		or int(raw["expiresOnTurn"]) <= int(raw["createdTurn"])
		or not _integers(raw, ["relationScoreDelta"], false)
		or not _is_nullable_integer(raw["respondedTurn"], true)
		or not _is_nullable_integer(raw["relationScoreAfter"], false)
		or not _is_nullable_integer(raw["promiseDueTurn"], true)
		or not raw["promiseBroken"] is bool
	):
		return null
	if (raw["response"] != null) != (raw["respondedTurn"] != null):
		return null
	if (
		raw["relationScoreAfter"] != null
		and (
			int(raw["relationScoreAfter"]) < -100
			or int(raw["relationScoreAfter"]) > 100
		)
	):
		return null
	if raw["promiseDueTurn"] != null and raw["response"] == null:
		return null
	if raw["promiseBroken"] and raw["promiseDueTurn"] == null:
		return null
	if (
		raw["response"] != null
		and (
			not raw["response"] is String
			or not DIPLOMATIC_MESSAGE_RESPONSES.has(raw["response"])
		)
	):
		return null
	var result := ReadModels.DiplomaticMessageView.new()
	result.id = raw["id"]
	result.from_player_id = raw["fromPlayerId"]
	result.to_player_id = raw["toPlayerId"]
	result.topic = StringName(raw["topic"])
	result.category = StringName(raw["category"])
	result.created_turn = int(raw["createdTurn"])
	result.expires_on_turn = int(raw["expiresOnTurn"])
	if raw["response"] != null:
		result.response = StringName(raw["response"])
	result.has_responded_turn = raw["respondedTurn"] != null
	if result.has_responded_turn:
		result.responded_turn = int(raw["respondedTurn"])
	result.relation_score_delta = int(raw["relationScoreDelta"])
	result.has_relation_score_after = raw["relationScoreAfter"] != null
	if result.has_relation_score_after:
		result.relation_score_after = int(raw["relationScoreAfter"])
	result.has_promise_due_turn = raw["promiseDueTurn"] != null
	if result.has_promise_due_turn:
		result.promise_due_turn = int(raw["promiseDueTurn"])
	result.promise_broken = raw["promiseBroken"]
	return result

static func _decode_resource_trade_agreement(
	raw: Variant,
) -> AonwClientReadModels.ResourceTradeAgreementView:
	if not _has_exact_fields(raw, [
		"id", "exporterPlayerId", "importerPlayerId", "resource", "goldPerTurn",
		"remainingTurns", "amountPerTurn", "exchangeGroupId",
	]):
		return null
	if not _strings(raw, ["id", "exporterPlayerId", "importerPlayerId", "resource"]):
		return null
	if (
		raw["id"].is_empty()
		or raw["exporterPlayerId"].is_empty()
		or raw["importerPlayerId"].is_empty()
		or raw["exporterPlayerId"] == raw["importerPlayerId"]
		or not RESOURCE_TYPES.has(raw["resource"])
		or not _integers(raw, ["goldPerTurn"], true)
		or not _integers(raw, ["remainingTurns", "amountPerTurn"], true)
		or int(raw["remainingTurns"]) == 0
		or int(raw["amountPerTurn"]) == 0
	):
		return null
	if (
		raw["exchangeGroupId"] != null
		and (not raw["exchangeGroupId"] is String or raw["exchangeGroupId"].is_empty())
	):
		return null
	var result := ReadModels.ResourceTradeAgreementView.new()
	result.id = raw["id"]
	result.exporter_player_id = raw["exporterPlayerId"]
	result.importer_player_id = raw["importerPlayerId"]
	result.resource = StringName(raw["resource"])
	result.gold_per_turn = int(raw["goldPerTurn"])
	result.remaining_turns = int(raw["remainingTurns"])
	result.amount_per_turn = int(raw["amountPerTurn"])
	if raw["exchangeGroupId"] != null:
		result.exchange_group_id = raw["exchangeGroupId"]
	return result

static func _message_category(topic: String) -> StringName:
	match topic:
		"troopsNearCities":
			return &"warning"
		"citiesTooClose":
			return &"complaint"
		"blockedRoutes", "withdrawScouts":
			return &"request"
		"avoidEscalation", "commonEnemy":
			return &"cooperation"
		"expansionProvocation":
			return &"threat"
		"peacefulPraise":
			return &"praise"
	return &""

static func _decode_city_founding_draft(
	raw: Variant,
) -> AonwClientReadModels.CityFoundingDraftView:
	if raw == null:
		return null
	if not _has_exact_fields(raw, ["founderUnitId", "center", "controlledHexes"]):
		return null
	if not raw["founderUnitId"] is String or raw["founderUnitId"].is_empty():
		return null
	if not raw["controlledHexes"] is Array:
		return null
	var center: Variant = _decode_coordinate(raw["center"])
	var controlled_hexes: Variant = _decode_coordinates(raw["controlledHexes"])
	if center == null or controlled_hexes == null:
		return null
	var result := ReadModels.CityFoundingDraftView.new()
	result.founder_unit_id = raw["founderUnitId"]
	result.center = center
	result.controlled_hexes = controlled_hexes
	return result

static func _decode_cities(raw: Array) -> Variant:
	var cities: Array[AonwClientReadModels.CityView] = []
	var previous_id := ""
	for value in raw:
		var city := _decode_city(value)
		if city == null or (not previous_id.is_empty() and city.id <= previous_id):
			return null
		cities.append(city)
		previous_id = city.id
	cities.make_read_only()
	return cities

static func _decode_city(raw: Variant) -> AonwClientReadModels.CityView:
	if not _has_exact_fields(raw, [
		"id", "ownerPlayerId", "name", "center", "visibleControlledHexes", "hitPoints",
		"ownedDetails",
	]):
		return null
	if not _strings(raw, ["id", "ownerPlayerId", "name"]):
		return null
	if raw["id"].is_empty() or raw["ownerPlayerId"].is_empty() or raw["name"].is_empty():
		return null
	if not raw["visibleControlledHexes"] is Array:
		return null
	if not _is_nullable_integer(raw["hitPoints"], true):
		return null
	var center: Variant = _decode_coordinate(raw["center"])
	var controlled_hexes: Variant = _decode_coordinates(raw["visibleControlledHexes"])
	var details := _decode_owned_city_details(raw["ownedDetails"])
	if (
		center == null
		or controlled_hexes == null
		or (raw["ownedDetails"] != null and details == null)
	):
		return null
	var result := ReadModels.CityView.new()
	result.id = raw["id"]
	result.owner_player_id = raw["ownerPlayerId"]
	result.display_name = raw["name"]
	result.center = center
	result.visible_controlled_hexes = controlled_hexes
	result.has_hit_points = raw["hitPoints"] != null
	if result.has_hit_points:
		result.hit_points = int(raw["hitPoints"])
	result.owned_details = details
	result.owned_planning = details
	return result

static func _decode_owned_city_details(
	raw: Variant,
) -> AonwClientReadModels.OwnedCityPlanningView:
	if raw == null:
		return null
	if not _has_exact_fields(raw, [
		"population", "storedFood", "maxHexes", "territoryRadius", "workedHexes",
		"buildings", "wonders", "productionQueue", "productionOverflow", "specialization",
		"preferredExpansionHex",
	]):
		return null
	if (
		not _integers(raw, [
			"population", "storedFood", "maxHexes", "territoryRadius", "productionOverflow",
		], true)
		or not raw["workedHexes"] is Array
		or not raw["buildings"] is Array
		or not raw["wonders"] is Array
		or (
			raw["specialization"] != null
			and (
				not raw["specialization"] is String
				or not CITY_SPECIALIZATIONS.has(raw["specialization"])
			)
		)
	):
		return null
	var worked_hexes: Variant = _decode_coordinates(raw["workedHexes"])
	var buildings: Variant = _decode_named_values(raw["buildings"], CITY_BUILDINGS)
	var wonders: Variant = _decode_named_values(raw["wonders"], WONDER_TYPES)
	var production_queue := _decode_city_production_queue(raw["productionQueue"])
	var preferred_expansion: Variant = null
	if raw["preferredExpansionHex"] != null:
		preferred_expansion = _decode_coordinate(raw["preferredExpansionHex"])
	if (
		worked_hexes == null
		or buildings == null
		or wonders == null
		or (raw["productionQueue"] != null and production_queue == null)
		or (raw["preferredExpansionHex"] != null and preferred_expansion == null)
	):
		return null
	var result := ReadModels.OwnedCityPlanningView.new()
	result.population = int(raw["population"])
	result.stored_food = int(raw["storedFood"])
	result.max_hexes = int(raw["maxHexes"])
	result.territory_radius = int(raw["territoryRadius"])
	result.worked_hexes = worked_hexes
	result.buildings = buildings
	result.wonders = wonders
	result.production_queue = production_queue
	result.production_overflow = int(raw["productionOverflow"])
	if raw["specialization"] != null:
		result.specialization = StringName(raw["specialization"])
	result.has_preferred_expansion_hex = preferred_expansion != null
	if preferred_expansion != null:
		result.preferred_expansion_hex = preferred_expansion
	return result

static func _decode_named_values(raw: Array, allowed: Array) -> Variant:
	var values: Array[StringName] = []
	for value: Variant in raw:
		if not value is String or not allowed.has(value):
			return null
		values.append(StringName(value))
	values.make_read_only()
	return values

static func _decode_city_production_queue(
	raw: Variant,
) -> AonwClientReadModels.CityProductionQueueView:
	if raw == null:
		return null
	if not _has_exact_fields(raw, ["target", "investedProduction", "resourceAllocation"]):
		return null
	if (
		not _integers(raw, ["investedProduction"], true)
		or not raw["resourceAllocation"] is Dictionary
	):
		return null
	var target := _decode_city_production_target(raw["target"])
	if target == null:
		return null
	var allocation: Dictionary = {}
	for resource: Variant in raw["resourceAllocation"]:
		var amount: Variant = raw["resourceAllocation"][resource]
		if not resource is String or not RESOURCE_TYPES.has(resource) or not _is_integer(amount, true):
			return null
		allocation[StringName(resource)] = int(amount)
	allocation.make_read_only()
	var result := ReadModels.CityProductionQueueView.new()
	result.target = target
	result.invested_production = int(raw["investedProduction"])
	result.resource_allocation = allocation
	return result

static func _decode_city_production_target(
	raw: Variant,
) -> AonwClientReadModels.CityProductionTargetView:
	if not raw is Dictionary or not raw.get("kind") is String:
		return null
	var value_field := ""
	var allowed: Array = []
	match raw["kind"]:
		"building":
			value_field = "buildingType"
			allowed = CITY_BUILDINGS
		"unit":
			value_field = "unitType"
			allowed = UNIT_KINDS
		"project":
			value_field = "projectType"
			allowed = CITY_PROJECTS
		"wonder":
			value_field = "wonderType"
			allowed = WONDER_TYPES
		_:
			return null
	if (
		not _has_exact_fields(raw, ["kind", value_field])
		or not raw[value_field] is String
		or not allowed.has(raw[value_field])
	):
		return null
	var result := ReadModels.CityProductionTargetView.new()
	result.kind = StringName(raw["kind"])
	result.value = StringName(raw[value_field])
	return result

static func _decode_field_improvements(raw: Array) -> Variant:
	var improvements: Array[AonwClientReadModels.FieldImprovementView] = []
	for value in raw:
		var improvement := _decode_field_improvement(value)
		if improvement == null:
			return null
		improvements.append(improvement)
	improvements.make_read_only()
	return improvements

static func _decode_field_improvement(
	raw: Variant,
) -> AonwClientReadModels.FieldImprovementView:
	if not _has_exact_fields(raw, ["coordinate", "improvement"]):
		return null
	if not raw["improvement"] is String or not FIELD_IMPROVEMENTS.has(raw["improvement"]):
		return null
	var coordinate: Variant = _decode_coordinate(raw["coordinate"])
	if coordinate == null:
		return null
	var result := ReadModels.FieldImprovementView.new()
	result.coordinate = coordinate
	result.improvement = StringName(raw["improvement"])
	return result

static func _decode_roads(raw: Array) -> Variant:
	var roads: Array[AonwClientReadModels.RoadView] = []
	for value in raw:
		var road := _decode_road(value)
		if road == null:
			return null
		roads.append(road)
	roads.make_read_only()
	return roads

static func _decode_road(raw: Variant) -> AonwClientReadModels.RoadView:
	if not _has_exact_fields(raw, ["coordinate", "condition"]):
		return null
	if not raw["condition"] is String or not TRANSPORT_CONDITIONS.has(raw["condition"]):
		return null
	var coordinate: Variant = _decode_coordinate(raw["coordinate"])
	if coordinate == null:
		return null
	var result := ReadModels.RoadView.new()
	result.coordinate = coordinate
	result.condition = StringName(raw["condition"])
	return result

static func _decode_coordinates(raw: Array) -> Variant:
	var coordinates: Array[Vector2i] = []
	for value in raw:
		var coordinate: Variant = _decode_coordinate(value)
		if coordinate == null:
			return null
		coordinates.append(coordinate)
	coordinates.make_read_only()
	return coordinates

static func _decode_string_ids(raw: Array) -> Variant:
	var ids: Array[String] = []
	for value in raw:
		if not value is String or value.is_empty():
			return null
		ids.append(value)
	ids.make_read_only()
	return ids

static func _decode_patch(raw: Variant) -> AonwClientReadModels.ViewPatch:
	if not _has_exact_fields(raw, [
		"fromRevision", "toRevision", "turn", "turnLifecycle", "outcome", "upsertedUnits",
		"removedUnitIds", "upsertedCities", "removedCityIds", "upsertedArtifacts",
		"removedArtifactIds", "upsertedFieldImprovements",
		"removedFieldImprovementCoordinates", "upsertedRoads", "removedRoadCoordinates",
		"pendingAction", "cityFoundingDraft", "diplomacy",
	]):
		return null
	if not _arrays(raw, [
		"upsertedUnits", "removedUnitIds", "upsertedCities", "removedCityIds",
		"upsertedArtifacts", "removedArtifactIds",
		"upsertedFieldImprovements", "removedFieldImprovementCoordinates",
		"upsertedRoads", "removedRoadCoordinates",
	]):
		return null
	if (
		not _integers(raw, ["fromRevision", "toRevision", "turn"], true)
		or int(raw["toRevision"]) < int(raw["fromRevision"])
		or int(raw["turn"]) == 0
	):
		return null
	var units: Array[AonwClientReadModels.UnitView] = []
	for value in raw["upsertedUnits"]:
		var unit := _decode_unit(value)
		if unit == null:
			return null
		units.append(unit)
	units.make_read_only()
	var removed: Array[String] = []
	for value in raw["removedUnitIds"]:
		if not value is String or value.is_empty():
			return null
		removed.append(value)
	removed.make_read_only()
	var turn_lifecycle := _decode_turn_lifecycle(raw["turnLifecycle"])
	var outcome := _decode_game_outcome(raw["outcome"])
	var pending_action := _decode_pending_action(raw["pendingAction"])
	var city_founding_draft := _decode_city_founding_draft(raw["cityFoundingDraft"])
	var diplomacy := _decode_diplomacy(raw["diplomacy"])
	var cities: Variant = _decode_cities(raw["upsertedCities"])
	var removed_city_ids: Variant = _decode_string_ids(raw["removedCityIds"])
	var artifacts: Variant = _decode_artifacts(raw["upsertedArtifacts"])
	var removed_artifact_ids: Variant = _decode_string_ids(raw["removedArtifactIds"])
	var field_improvements: Variant = _decode_field_improvements(
		raw["upsertedFieldImprovements"]
	)
	var removed_field_improvements: Variant = _decode_coordinates(
		raw["removedFieldImprovementCoordinates"]
	)
	var roads: Variant = _decode_roads(raw["upsertedRoads"])
	var removed_roads: Variant = _decode_coordinates(raw["removedRoadCoordinates"])
	if (
		(raw["turnLifecycle"] != null and turn_lifecycle == null)
		or (raw["outcome"] != null and outcome == null)
		or (raw["pendingAction"] != null and pending_action == null)
		or (raw["cityFoundingDraft"] != null and city_founding_draft == null)
		or (raw["diplomacy"] != null and diplomacy == null)
		or cities == null
		or removed_city_ids == null
		or artifacts == null
		or removed_artifact_ids == null
		or field_improvements == null
		or removed_field_improvements == null
		or roads == null
		or removed_roads == null
	):
		return null
	var result := ReadModels.ViewPatch.new()
	result.from_revision = int(raw["fromRevision"])
	result.to_revision = int(raw["toRevision"])
	result.turn = int(raw["turn"])
	result.turn_lifecycle = turn_lifecycle
	result.outcome = outcome
	result.upserted_units = units
	result.removed_unit_ids = removed
	result.upserted_cities = cities
	result.removed_city_ids = removed_city_ids
	result.upserted_artifacts = artifacts
	result.removed_artifact_ids = removed_artifact_ids
	result.upserted_field_improvements = field_improvements
	result.removed_field_improvement_coordinates = removed_field_improvements
	result.upserted_roads = roads
	result.removed_road_coordinates = removed_roads
	result.pending_action = pending_action
	result.city_founding_draft = city_founding_draft
	result.diplomacy = diplomacy
	return result

static func _decode_pending_action(raw: Variant) -> AonwClientReadModels.PendingActionView:
	if raw == null:
		return null
	if not raw is Dictionary or not raw.get("type") is String:
		return null
	var result := ReadModels.PendingActionView.new()
	result.kind = StringName(raw["type"])
	match raw["type"]:
		"researchSelection":
			if not _has_exact_fields(raw, ["type"]):
				return null
		"cityWorkedHexSelection", "cityExpansionSelection":
			if not _has_exact_fields(raw, ["type", "cityId"]):
				return null
			if not raw["cityId"] is String or raw["cityId"].is_empty():
				return null
			result.city_id = raw["cityId"]
		"workerActionSelection":
			if not _has_exact_fields(raw, ["type", "unitId", "improvement"]):
				return null
			if not _valid_unit_id(raw["unitId"]):
				return null
			if raw["improvement"] != null:
				if not raw["improvement"] is String or not FIELD_IMPROVEMENTS.has(raw["improvement"]):
					return null
				result.improvement = StringName(raw["improvement"])
			result.unit_id = raw["unitId"]
		"merchantTradeRouteSelection", "merchantMoveToCitySelection", "commanderMergeSelection":
			if not _has_exact_fields(raw, ["type", "unitId"]) or not _valid_unit_id(raw["unitId"]):
				return null
			result.unit_id = raw["unitId"]
		"unitTurnSkip":
			if not _has_exact_fields(raw, ["type", "unitId", "restoreMovementUnits"]):
				return null
			if not _valid_unit_id(raw["unitId"]) or not _integers(raw, ["restoreMovementUnits"], true):
				return null
			result.unit_id = raw["unitId"]
			result.restore_movement_units = int(raw["restoreMovementUnits"])
		"attackTargeting":
			if not _has_exact_fields(raw, ["type", "unitId", "defender"]):
				return null
			if not _valid_unit_id(raw["unitId"]):
				return null
			result.unit_id = raw["unitId"]
			if raw["defender"] != null:
				var defender: Variant = _decode_coordinate(raw["defender"])
				if defender == null:
					return null
				result.has_defender = true
				result.defender = defender
		_:
			return null
	return result

static func _valid_unit_id(value: Variant) -> bool:
	return value is String and not value.is_empty()

static func _decode_evidence(raw: Variant) -> Variant:
	if raw == null:
		return null
	if not raw is Dictionary or not raw.get("type") is String:
		return null
	if raw["type"] == "turnKernel":
		return _decode_turn_kernel_evidence(raw)
	if not _has_exact_fields(raw, ["type", "unitId", "from", "steps"]):
		return null
	if raw["type"] != "unitMovement" or not raw["unitId"] is String or not raw["steps"] is Array:
		return null
	var from: Variant = _decode_coordinate(raw["from"])
	var steps: Variant = _decode_steps(raw["steps"])
	if from == null or steps == null:
		return null
	var result := ReadModels.MovementEvidence.new()
	result.unit_id = raw["unitId"]
	result.from = from
	result.steps = steps
	return result

static func _decode_turn_kernel_evidence(raw: Dictionary) -> AonwClientReadModels.TurnKernelEvidence:
	if not _has_exact_fields(raw, [
		"type", "processors", "foundedCityIds", "combatExecutions", "resetUnitIds",
		"movementExecutions", "invalidatedOrderUnitIds", "finishedAutoExploreUnitIds",
	]):
		return null
	if not _arrays(raw, [
		"processors", "foundedCityIds", "combatExecutions", "resetUnitIds",
		"movementExecutions", "invalidatedOrderUnitIds", "finishedAutoExploreUnitIds",
	]):
		return null
	var processors: Array[StringName] = []
	for value in raw["processors"]:
		if not value is String or not ClientEventSchema.TURN_PROCESSORS.has(value):
			return null
		processors.append(StringName(value))
	processors.make_read_only()
	var founded: Variant = _decode_string_ids(raw["foundedCityIds"])
	var reset: Variant = _decode_string_ids(raw["resetUnitIds"])
	var invalidated: Variant = _decode_string_ids(raw["invalidatedOrderUnitIds"])
	var finished: Variant = _decode_string_ids(raw["finishedAutoExploreUnitIds"])
	if founded == null or reset == null or invalidated == null or finished == null:
		return null
	for execution in raw["combatExecutions"]:
		if not execution is Dictionary:
			return null
	for execution in raw["movementExecutions"]:
		if not _valid_movement_execution(execution):
			return null
	var result := ReadModels.TurnKernelEvidence.new()
	result.processors = processors
	result.founded_city_ids = founded
	result.combat_execution_count = raw["combatExecutions"].size()
	result.reset_unit_ids = reset
	result.movement_execution_count = raw["movementExecutions"].size()
	result.invalidated_order_unit_ids = invalidated
	result.finished_auto_explore_unit_ids = finished
	return result

static func _valid_movement_execution(raw: Variant) -> bool:
	if not _has_exact_fields(raw, ["unitId", "from", "steps"]):
		return false
	if not _valid_unit_id(raw["unitId"]) or not raw["steps"] is Array:
		return false
	return _decode_coordinate(raw["from"]) != null and _decode_steps(raw["steps"]) != null

static func _decode_steps(raw: Array) -> Variant:
	var steps: Array[AonwClientReadModels.MovementStep] = []
	for value in raw:
		if not _has_exact_fields(value, [
			"coordinate", "enterCostUnits", "cumulativeCostUnits",
		]):
			return null
		if not _integers(value, ["enterCostUnits", "cumulativeCostUnits"], true):
			return null
		var coordinate: Variant = _decode_coordinate(value["coordinate"])
		if coordinate == null:
			return null
		var step := ReadModels.MovementStep.new()
		step.coordinate = coordinate
		step.enter_cost_units = int(value["enterCostUnits"])
		step.cumulative_cost_units = int(value["cumulativeCostUnits"])
		steps.append(step)
	steps.make_read_only()
	return steps

static func _decode_events(raw: Array) -> Variant:
	var events: Array = []
	for value in raw:
		if not value is Dictionary or not value.get("type") is String:
			return null
		if not ClientEventSchema.FIELDS.has(value["type"]):
			return null
		var fields: Array = ClientEventSchema.FIELDS[value["type"]]
		if not _has_exact_fields(value, fields):
			return null
		if value["type"] == "unitMoved":
			if not _valid_unit_id(value["unitId"]):
				return null
			var from: Variant = _decode_coordinate(value["from"])
			var to: Variant = _decode_coordinate(value["to"])
			if from == null or to == null:
				return null
			var movement := ReadModels.UnitMovedEvent.new()
			movement.unit_id = value["unitId"]
			movement.from = from
			movement.to = to
			events.append(movement)
			continue
		var event := ReadModels.CommandEvent.new()
		event.kind = StringName(value["type"])
		events.append(event)
	events.make_read_only()
	return events

static func _decode_coordinate(raw: Variant) -> Variant:
	if not _has_exact_fields(raw, ["col", "row"]):
		return null
	if not _integers(raw, ["col", "row"], false):
		return null
	return Vector2i(int(raw["col"]), int(raw["row"]))

static func _integers(raw: Dictionary, fields: Array, non_negative: bool) -> bool:
	for field in fields:
		if not _is_integer(raw[field], non_negative):
			return false
	return true

static func _is_integer(value: Variant, non_negative: bool) -> bool:
	if not value is int and not value is float:
		return false
	var integer := int(value)
	return float(integer) == float(value) and (not non_negative or integer >= 0)

static func _is_nullable_integer(value: Variant, non_negative: bool) -> bool:
	return value == null or _is_integer(value, non_negative)

static func _strings(raw: Dictionary, fields: Array) -> bool:
	for field in fields:
		if not raw[field] is String:
			return false
	return true

static func _arrays(raw: Dictionary, fields: Array) -> bool:
	for field in fields:
		if not raw[field] is Array:
			return false
	return true

static func _has_exact_fields(raw: Variant, fields: Array) -> bool:
	if not raw is Dictionary or raw.size() != fields.size():
		return false
	for field in fields:
		if not raw.has(field):
			return false
	return true
