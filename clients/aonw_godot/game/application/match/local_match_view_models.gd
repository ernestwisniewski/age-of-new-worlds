class_name AonwLocalMatchViewModels
extends RefCounted

class UnitView:
	extends RefCounted
	var id: String
	var owner_player_id: String
	var kind: StringName
	var display_name: String
	var coordinate: Vector2i

class TurnView:
	extends RefCounted
	var number: int
	var has_own_state: bool
	var own_state: StringName
	var own_submitted: bool
	var required_submission_count: int
	var submitted_count: int
	var pending_action: StringName
	var outcome_condition: StringName

	func is_terminal() -> bool:
		return outcome_condition != &"ongoing"

	func can_end_turn() -> bool:
		return (
			not is_terminal()
			and pending_action == &""
			and has_own_state
			and own_state == &"active"
			and not own_submitted
		)

class ProjectionView:
	extends RefCounted
	var revision: int
	var turn: TurnView
	var units: Array[UnitView]

class ReachableTile:
	extends RefCounted
	var coordinate: Vector2i
	var cost_units: int
	var exhausts_movement: bool

class ReachableView:
	extends RefCounted
	var revision: int
	var unit_id: String
	var available_movement_units: int
	var tiles: Array[ReachableTile]

class MovementStep:
	extends RefCounted
	var coordinate: Vector2i
	var enter_cost_units: int
	var cumulative_cost_units: int

class RouteView:
	extends RefCounted
	var revision: int
	var unit_id: String
	var target: Vector2i
	var destination: Vector2i
	var total_cost_units: int
	var available_movement_units: int
	var remaining_movement_units: int
	var steps: Array[MovementStep]

class UnitTransition:
	extends RefCounted
	var upserted_units: Array[UnitView]
	var removed_unit_ids: Array[String]
	var movement_unit_id: String
	var movement_steps: Array[MovementStep]

class ActivityIdentity:
	extends RefCounted
	var revision: int
	var event_index: int

class ActivityView:
	extends RefCounted
	var identity: ActivityIdentity
	var kind: StringName

class CommandResult:
	extends RefCounted
	var accepted: bool
	var rejection: StringName
	var revision: int
	var turn: TurnView
	var unit_transition: UnitTransition
	var activities: Array[ActivityView]
