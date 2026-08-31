@tool
class_name AonwAtomicResourceStore
extends RefCounted

func save_scene(scene: PackedScene, path: String) -> Error:
	var pending_path := _pending_path(path)
	var error := ResourceSaver.save(scene, pending_path)
	if error != OK:
		return error
	return _replace_file(pending_path, path)

func write_text(path: String, content: String) -> Error:
	var pending_path := _pending_path(path)
	var file := FileAccess.open(pending_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file = null
	return _replace_file(pending_path, path)

func _replace_file(pending_path: String, target_path: String) -> Error:
	var pending_absolute := ProjectSettings.globalize_path(pending_path)
	var target_absolute := ProjectSettings.globalize_path(target_path)
	var error := DirAccess.rename_absolute(pending_absolute, target_absolute)
	if error == OK:
		return OK
	if not FileAccess.file_exists(target_path):
		return error
	var backup_path := "%s.backup" % target_path
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	error = DirAccess.rename_absolute(target_absolute, backup_absolute)
	if error != OK:
		return error
	error = DirAccess.rename_absolute(pending_absolute, target_absolute)
	if error != OK:
		DirAccess.rename_absolute(backup_absolute, target_absolute)
		return error
	DirAccess.remove_absolute(backup_absolute)
	return OK

func _pending_path(path: String) -> String:
	return "%s.pending.%s" % [path.get_basename(), path.get_extension()]
