class_name AonwTextDocumentReader
extends RefCounted

func read(source_path: String) -> Dictionary:
	var absolute_path := resolve_path(source_path)
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"message": "cannot open %s" % absolute_path,
		}
	return {
		"ok": true,
		"document": file.get_as_text(),
	}

static func resolve_path(source_path: String) -> String:
	if source_path.begins_with("res://") or source_path.begins_with("user://"):
		return ProjectSettings.globalize_path(source_path)
	return source_path
