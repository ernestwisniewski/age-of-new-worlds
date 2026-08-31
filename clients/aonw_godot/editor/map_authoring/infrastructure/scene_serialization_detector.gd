@tool
class_name AonwSceneSerializationDetector
extends RefCounted

const Problem := preload(
	"res://editor/map_authoring/application/scene_safety_problem.gd"
)
const REVIEW_SIZE_BYTES := 256 * 1024
const TRANSIENT_RESOURCE_TYPES := {
	"Image": true,
	"ImageTexture": true,
	"ArrayMesh": true,
	"MultiMesh": true,
}

func inspect(scene_path: String) -> Dictionary:
	if not _is_exact_scene_path(scene_path):
		return _failure(
			scene_path,
			&"scene_path_not_exact",
			"Scene inspection requires one exact .tscn path without glob syntax.",
		)
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return _failure(
			scene_path,
			&"scene_read_failed",
			"The scene could not be opened read-only: %s" % error_string(FileAccess.get_open_error()),
		)
	var byte_size := file.get_length()
	var type_counts := {}
	var transient_block_bytes := 0
	var current_type := ""
	var current_block_bytes := 0
	while not file.eof_reached():
		var before := file.get_position()
		var line := file.get_line()
		var line_bytes := file.get_position() - before
		if line.begins_with("["):
			if TRANSIENT_RESOURCE_TYPES.has(current_type):
				transient_block_bytes += current_block_bytes
			current_type = _sub_resource_type(line)
			current_block_bytes = 0
			if not current_type.is_empty():
				type_counts[current_type] = int(type_counts.get(current_type, 0)) + 1
		current_block_bytes += line_bytes
	if TRANSIENT_RESOURCE_TYPES.has(current_type):
		transient_block_bytes += current_block_bytes
	file = null
	var dangerous_counts := {}
	var problems: Array = []
	for resource_type in type_counts:
		if not TRANSIENT_RESOURCE_TYPES.has(resource_type):
			continue
		dangerous_counts[resource_type] = type_counts[resource_type]
		problems.append(Problem.new(
			&"embedded_transient_resource",
			"The scene embeds transient %s resources." % resource_type,
			"",
			resource_type,
		))
	var estimated_size := maxi(0, byte_size - transient_block_bytes)
	var exceeds_review_size := byte_size > REVIEW_SIZE_BYTES
	if exceeds_review_size:
		problems.append(Problem.new(
			&"scene_size_review",
			"The scene exceeds the proposed 256 KiB review threshold.",
			"",
			"",
			false,
		))
	return {
		"ok": true,
		"path": scene_path,
		"sha256": FileAccess.get_sha256(scene_path),
		"byte_size": byte_size,
		"embedded_resource_types": type_counts,
		"dangerous_resource_types": dangerous_counts,
		"estimated_repaired_byte_size": estimated_size,
		"review_size_bytes": REVIEW_SIZE_BYTES,
		"exceeds_review_size": exceeds_review_size,
		"problems": problems,
	}

func _sub_resource_type(line: String) -> String:
	if not line.begins_with("[sub_resource type=\""):
		return ""
	return line.get_slice("\"", 1)

func _is_exact_scene_path(path: String) -> bool:
	return (
		not path.is_empty()
		and path.get_extension().to_lower() == "tscn"
		and not path.contains("*")
		and not path.contains("?")
		and not path.contains("[")
		and not path.contains("]")
	)

func _failure(path: String, code: StringName, message: String) -> Dictionary:
	return {
		"ok": false,
		"path": path,
		"message": message,
		"problems": [Problem.new(code, message)],
	}
