class_name AonwClientReadModels
extends RefCounted

class Stamp:
	extends RefCounted
	var revision: int
	var state_digest: String
	var map_hash: String
	var ruleset_hash: String

class EngineFeatureSet:
	extends RefCounted
	var features: Array[StringName]

	func supports(feature: StringName) -> bool:
		return feature in features

	func missing(required: Array[StringName]) -> Array[StringName]:
		var result: Array[StringName] = []
		for feature in required:
			if not supports(feature):
				result.append(feature)
		result.make_read_only()
		return result

class AiTurnResult:
	extends RefCounted
	var stamp: Stamp
	var actor_player_id: String
	var executed_commands: int
	var completed_turn: bool

class ReplayVerification:
	extends RefCounted
	var entry_count: int
	var final_event_offset: int
	var final_stamp: Stamp

class UnitView:
	extends RefCounted
	var id: String
	var owner_player_id: String
	var kind: String
	var display_name: String
	var coordinate: Vector2i
	var movement_units: int
	var posture: String
	var has_hit_points: bool
	var hit_points: int
	var has_carried_artifact_id: bool
	var carried_artifact_id: String
	var owned_details: OwnedUnitDetailsView
	# Compatibility conveniences derived from owned_details.
	var worker_build_charges: int
	var worker_job: WorkerJobView
	var has_worker_assignment: bool
	var worker_assignment: Vector2i

class ArmyTroopView:
	extends RefCounted
	var kind: StringName
	var count: int

class PersistedMovementStepView:
	extends RefCounted
	var coordinate: Vector2i
	var enter_cost_units: int
	var cumulative_cost_units: int

class QueuedMovePathView:
	extends RefCounted
	var target: Vector2i
	var steps: Array[PersistedMovementStepView]

class MerchantTradeRouteView:
	extends RefCounted
	var origin_city_id: String
	var destination_city_id: String
	var steps: Array[PersistedMovementStepView]
	var transport_network_fingerprint: String

class CityFoundingJobView:
	extends RefCounted
	var center: Vector2i
	var controlled_hexes: Array[Vector2i]
	var remaining_turns: int
	var total_turns: int

class OwnedUnitDetailsView:
	extends RefCounted
	var army: Array[ArmyTroopView]
	var queued_path: QueuedMovePathView
	var merchant_trade_route: MerchantTradeRouteView
	var worker_job: WorkerJobView
	var city_founding_job: CityFoundingJobView
	var has_worker_assignment: bool
	var worker_assignment: Vector2i
	var has_excavating_artifact_id: bool
	var excavating_artifact_id: String
	var worker_build_charges: int
	var experience_points: int

class WorkerJobView:
	extends RefCounted
	var kind: StringName
	var target: Vector2i
	var improvement: StringName
	var remaining_turns: int
	var total_turns: int

class TurnLifecycleView:
	extends RefCounted
	var has_own_state: bool
	var own_state: StringName
	var own_submitted: bool
	var required_submission_count: int
	var submitted_count: int

class GameOutcomeView:
	extends RefCounted
	var condition: StringName
	var has_winner_player_id: bool
	var winner_player_id: String
	var score_by_player_id: Dictionary

class ArtifactLocationView:
	extends RefCounted
	var kind: StringName
	var coordinate: Vector2i
	var unit_id: String
	var city_id: String
	var remaining_turns: int

class ArtifactView:
	extends RefCounted
	var id: String
	var artifact_type: StringName
	var location: ArtifactLocationView

class DiplomaticRelationView:
	extends RefCounted
	var counterpart_player_id: String
	var status: StringName
	var relation_score: int
	var has_status_expires_on_turn: bool
	var status_expires_on_turn: int
	var has_last_changed_turn: bool
	var last_changed_turn: int
	var last_change_reason: StringName

class DiplomaticProposalView:
	extends RefCounted
	var id: String
	var from_player_id: String
	var to_player_id: String
	var kind: StringName
	var created_turn: int
	var expires_on_turn: int
	var gold_payment: int

class DiplomaticMessageView:
	extends RefCounted
	var id: String
	var from_player_id: String
	var to_player_id: String
	var topic: StringName
	var category: StringName
	var created_turn: int
	var expires_on_turn: int
	var response: StringName
	var has_responded_turn: bool
	var responded_turn: int
	var relation_score_delta: int
	var has_relation_score_after: bool
	var relation_score_after: int
	var has_promise_due_turn: bool
	var promise_due_turn: int
	var promise_broken: bool

class ResourceTradeAgreementView:
	extends RefCounted
	var id: String
	var exporter_player_id: String
	var importer_player_id: String
	var resource: StringName
	var gold_per_turn: int
	var remaining_turns: int
	var amount_per_turn: int
	var exchange_group_id: String

class DiplomacyView:
	extends RefCounted
	var relations: Array[DiplomaticRelationView]
	var proposals: Array[DiplomaticProposalView]
	var messages: Array[DiplomaticMessageView]
	var resource_trade_agreements: Array[ResourceTradeAgreementView]

class CityFoundingDraftView:
	extends RefCounted
	var founder_unit_id: String
	var center: Vector2i
	var controlled_hexes: Array[Vector2i]

class OwnedCityPlanningView:
	extends RefCounted
	var population: int
	var stored_food: int
	var max_hexes: int
	var territory_radius: int
	var worked_hexes: Array[Vector2i]
	var buildings: Array[StringName]
	var wonders: Array[StringName]
	var production_queue: CityProductionQueueView
	var production_overflow: int
	var specialization: StringName
	var has_preferred_expansion_hex: bool
	var preferred_expansion_hex: Vector2i

class CityProductionTargetView:
	extends RefCounted
	var kind: StringName
	var value: StringName

class CityProductionQueueView:
	extends RefCounted
	var target: CityProductionTargetView
	var invested_production: int
	var resource_allocation: Dictionary

class CityView:
	extends RefCounted
	var id: String
	var owner_player_id: String
	var display_name: String
	var center: Vector2i
	var visible_controlled_hexes: Array[Vector2i]
	var has_hit_points: bool
	var hit_points: int
	var owned_details: OwnedCityPlanningView
	# Compatibility alias for existing presentation code.
	var owned_planning: OwnedCityPlanningView

class FieldImprovementView:
	extends RefCounted
	var coordinate: Vector2i
	var improvement: StringName

class RoadView:
	extends RefCounted
	var coordinate: Vector2i
	var condition: StringName

class MovementStep:
	extends RefCounted
	var coordinate: Vector2i
	var enter_cost_units: int
	var cumulative_cost_units: int

class ReachableTile:
	extends RefCounted
	var coordinate: Vector2i
	var cost_units: int
	var exhausts_movement: bool

class UnitMovedEvent:
	extends RefCounted
	var kind := &"unitMoved"
	var unit_id: String
	var from: Vector2i
	var to: Vector2i

class CommandEvent:
	extends RefCounted
	var kind: StringName

class PendingActionView:
	extends RefCounted
	var kind: StringName
	var city_id: String
	var unit_id: String
	var improvement: StringName
	var restore_movement_units: int
	var has_defender: bool
	var defender: Vector2i

class SnapshotView:
	extends RefCounted
	var stamp: Stamp
	var turn: int
	var outcome: GameOutcomeView
	var turn_lifecycle: TurnLifecycleView
	var pending_action: PendingActionView
	var city_founding_draft: CityFoundingDraftView
	var diplomacy: DiplomacyView
	var units: Array[UnitView]
	var cities: Array[CityView]
	var artifacts: Array[ArtifactView]
	var field_improvements: Array[FieldImprovementView]
	var roads: Array[RoadView]

class ReachableView:
	extends RefCounted
	var stamp: Stamp
	var unit_id: String
	var available_movement_units: int
	var tiles: Array[ReachableTile]

class RoutePlanView:
	extends RefCounted
	var stamp: Stamp
	var unit_id: String
	var target: Vector2i
	var destination: Vector2i
	var total_cost_units: int
	var available_movement_units: int
	var remaining_movement_units: int
	var steps: Array[MovementStep]

class ViewPatch:
	extends RefCounted
	var from_revision: int
	var to_revision: int
	var turn: int
	var turn_lifecycle: TurnLifecycleView
	var outcome: GameOutcomeView
	var upserted_units: Array[UnitView]
	var removed_unit_ids: Array[String]
	var upserted_cities: Array[CityView]
	var removed_city_ids: Array[String]
	var upserted_artifacts: Array[ArtifactView]
	var removed_artifact_ids: Array[String]
	var upserted_field_improvements: Array[FieldImprovementView]
	var removed_field_improvement_coordinates: Array[Vector2i]
	var upserted_roads: Array[RoadView]
	var removed_road_coordinates: Array[Vector2i]
	var pending_action: PendingActionView
	var city_founding_draft: CityFoundingDraftView
	var diplomacy: DiplomacyView

class MovementEvidence:
	extends RefCounted
	var unit_id: String
	var from: Vector2i
	var steps: Array[MovementStep]

class TurnKernelEvidence:
	extends RefCounted
	var processors: Array[StringName]
	var founded_city_ids: Array[String]
	var combat_execution_count: int
	var reset_unit_ids: Array[String]
	var movement_execution_count: int
	var invalidated_order_unit_ids: Array[String]
	var finished_auto_explore_unit_ids: Array[String]

class CommandResult:
	extends RefCounted
	var stamp: Stamp
	var accepted: bool
	var rejection: StringName
	var events: Array
	var patch: ViewPatch
	var evidence: Variant
