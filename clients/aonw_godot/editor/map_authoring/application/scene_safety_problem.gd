@tool
class_name AonwSceneSafetyProblem
extends RefCounted

var code: StringName
var message: String
var node_path: String
var resource_type: String
var blocks_save: bool

func _init(
	problem_code: StringName,
	problem_message: String,
	problem_node_path := "",
	problem_resource_type := "",
	problem_blocks_save := true,
) -> void:
	code = problem_code
	message = problem_message
	node_path = problem_node_path
	resource_type = problem_resource_type
	blocks_save = problem_blocks_save

func to_dictionary() -> Dictionary:
	return {
		"code": String(code),
		"message": message,
		"nodePath": node_path,
		"resourceType": resource_type,
		"blocksSave": blocks_save,
	}
