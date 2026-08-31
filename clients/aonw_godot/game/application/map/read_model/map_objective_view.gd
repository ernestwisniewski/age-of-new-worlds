class_name AonwMapObjectiveView
extends RefCounted

var _id: StringName
var _type: StringName
var _coordinate: Vector2i
var _required_hold_turns: int
var _victory_points: int
var _gold_per_turn: int

func _init(
	objective_id: StringName,
	objective_type: StringName,
	coordinate: Vector2i,
	required_hold_turns: int,
	victory_points: int,
	gold_per_turn: int,
) -> void:
	_id = objective_id
	_type = objective_type
	_coordinate = coordinate
	_required_hold_turns = required_hold_turns
	_victory_points = victory_points
	_gold_per_turn = gold_per_turn

func id() -> StringName:
	return _id

func type() -> StringName:
	return _type

func coordinate() -> Vector2i:
	return _coordinate

func required_hold_turns() -> int:
	return _required_hold_turns

func victory_points() -> int:
	return _victory_points

func gold_per_turn() -> int:
	return _gold_per_turn
