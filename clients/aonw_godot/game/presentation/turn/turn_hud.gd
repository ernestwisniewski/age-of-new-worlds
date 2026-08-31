class_name AonwTurnHud
extends HBoxContainer

signal end_turn_requested

@onready var _end_turn: Button = %EndTurn
@onready var _status: Label = %TurnStatus

var _turn: AonwLocalMatchViewModels.TurnView
var _command_pending := false
var _input_blocked := false

func present(value: AonwLocalMatchViewModels.TurnView) -> void:
	_turn = value
	_command_pending = false
	_refresh()

func current() -> AonwLocalMatchViewModels.TurnView:
	return _turn

func can_request_end_turn() -> bool:
	return (
		_turn != null
		and _turn.can_end_turn()
		and not _command_pending
		and not _input_blocked
	)

func set_input_blocked(value: bool) -> void:
	_input_blocked = value
	_refresh()

func begin_command() -> bool:
	if not can_request_end_turn():
		return false
	_command_pending = true
	_refresh()
	return true

func cancel_command() -> void:
	_command_pending = false
	_refresh()

func _on_end_turn_pressed() -> void:
	if can_request_end_turn():
		end_turn_requested.emit()

func _refresh() -> void:
	if _turn == null:
		_status.text = "Turn —"
		_end_turn.disabled = true
		return
	var state := "waiting"
	if _turn.is_terminal():
		state = "outcome %s" % _turn.outcome_condition
	elif _turn.pending_action != &"":
		state = "pending %s" % _turn.pending_action
	elif _turn.own_submitted:
		state = "submitted"
	elif _turn.has_own_state:
		state = str(_turn.own_state)
	_status.text = "Turn %d · %s · %d/%d submitted" % [
		_turn.number,
		state,
		_turn.submitted_count,
		_turn.required_submission_count,
	]
	_end_turn.disabled = not can_request_end_turn()
