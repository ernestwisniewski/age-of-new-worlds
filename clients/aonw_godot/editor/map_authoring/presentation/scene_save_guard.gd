@tool
class_name AonwSceneSaveGuard
extends RefCounted

const Validator := preload(
	"res://editor/map_authoring/application/scene_serialization_validator.gd"
)

var _validator := Validator.new()

func validate(scene_root: Node) -> Dictionary:
	return _validator.result_for(scene_root)

func first_problem_message(result: Dictionary) -> String:
	if result.get("ok", false):
		return ""
	var problems: Array = result.get("problems", [])
	if problems.is_empty():
		return str(result.get("message", "scene safety validation failed"))
	var problem: AonwSceneSafetyProblem = problems[0]
	var location := "" if problem.node_path.is_empty() else " at %s" % problem.node_path
	return "%s%s [%s]" % [problem.message, location, problem.code]
