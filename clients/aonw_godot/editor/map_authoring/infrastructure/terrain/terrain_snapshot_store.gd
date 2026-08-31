class_name AonwTerrainSnapshotStore
extends RefCounted

const AtomicResourceStore := preload(
	"res://editor/map_authoring/infrastructure/atomic_resource_store.gd"
)
const SNAPSHOT_MANIFEST_FILE := "terrain_snapshot.json"
const WORKSPACE_DIRECTORY := "workspace"
const SNAPSHOT_FIELDS := [
	"mapId",
	"mapContentHash",
	"authoringProfileHash",
	"generatedBaseHash",
	"generatorVersion",
	"rasterWidth",
	"rasterHeight",
	"sampleSpacingMeters",
	"terrainRevision",
	"snapshotHash",
	"terrainFiles",
]
const POINTER_FIELDS := [
	"mapId",
	"mapContentHash",
	"authoringProfileHash",
	"generatedBaseHash",
	"generatorVersion",
	"rasterWidth",
	"rasterHeight",
	"sampleSpacingMeters",
	"terrainRevision",
	"snapshotHash",
	"terrainDataDirectory",
]

var _root: String
var _atomic_store := AtomicResourceStore.new()

func _init(root: String) -> void:
	_root = root

func pointer_path(file_name: String) -> String:
	return _root.path_join(file_name)

func snapshot_directory(collection: String, snapshot_hash: String) -> String:
	return _root.path_join(collection).path_join(snapshot_hash)

func read_current(file_name: String, collection: String) -> Dictionary:
	var pointer_result := _read_manifest(pointer_path(file_name), POINTER_FIELDS)
	if not pointer_result["ok"]:
		return pointer_result
	var pointer: Dictionary = pointer_result["manifest"]
	if not _valid_snapshot_metadata(pointer):
		return _failure("current terrain snapshot metadata is invalid")
	var directory := snapshot_directory(collection, str(pointer["snapshotHash"]))
	if str(pointer["terrainDataDirectory"]) != directory:
		return _failure("current terrain pointer is outside its snapshot directory")
	var snapshot_result := validate_snapshot(directory, str(pointer["snapshotHash"]))
	if not snapshot_result["ok"]:
		return snapshot_result
	if not _same_snapshot_metadata(pointer, snapshot_result["manifest"]):
		return _failure("current terrain pointer does not match its snapshot manifest")
	return {
		"ok": true,
		"pointer": pointer,
		"manifest": snapshot_result["manifest"],
		"data_directory": directory,
	}

func write_current(file_name: String, manifest: Dictionary, directory: String) -> Dictionary:
	var pointer := _snapshot_pointer(manifest, directory)
	var path := pointer_path(file_name)
	var error := _atomic_store.write_text(path, _json_text(pointer))
	if error != OK:
		return _failure("cannot switch current terrain snapshot: %s" % error_string(error))
	return {"ok": true, "manifest_path": path}

func prepare_empty_workspace() -> Dictionary:
	var workspace_path := _root.path_join(WORKSPACE_DIRECTORY)
	var error := _reset_directory(workspace_path)
	return (
		{"ok": true, "data_directory": workspace_path}
		if error == OK
		else _failure("cannot prepare Terrain3D workspace: %s" % error_string(error))
	)

func restore_workspace(snapshot_path: String) -> Dictionary:
	var workspace := prepare_empty_workspace()
	if not workspace["ok"]:
		return workspace
	var copy_result := _copy_terrain_files(snapshot_path, workspace["data_directory"])
	if not copy_result["ok"]:
		return copy_result
	return workspace

func create_snapshot(
	data: Terrain3DData,
	metadata: Dictionary,
	collection: String,
) -> Dictionary:
	var collection_path := _root.path_join(collection)
	var error := _ensure_directory(collection_path)
	if error != OK:
		return _failure("cannot create terrain snapshot directory: %s" % error_string(error))
	var workspace := _save_workspace(data)
	if not workspace["ok"]:
		return workspace
	var pending_path := _pending_directory(collection_path)
	error = _ensure_directory(pending_path)
	if error != OK:
		return _failure("cannot create pending terrain snapshot: %s" % error_string(error))
	var files_result := _copy_terrain_files(workspace["data_directory"], pending_path)
	if not files_result["ok"]:
		_discard_directory(pending_path)
		return files_result
	var manifest := metadata.duplicate()
	manifest["terrainFiles"] = files_result["files"]
	manifest["snapshotHash"] = _snapshot_hash(manifest)
	var manifest_error := _write_text(
		pending_path.path_join(SNAPSHOT_MANIFEST_FILE),
		_json_text(manifest),
	)
	if manifest_error != OK:
		_discard_directory(pending_path)
		return _failure("cannot write terrain snapshot manifest: %s" % error_string(manifest_error))
	return _commit_snapshot(pending_path, collection_path, manifest)

func promote_snapshot(
	source_path: String,
	snapshot_hash: String,
	collection: String,
) -> Dictionary:
	var source_validation := validate_snapshot(source_path, snapshot_hash)
	if not source_validation["ok"]:
		return source_validation
	var collection_path := _root.path_join(collection)
	var error := _ensure_directory(collection_path)
	if error != OK:
		return _failure("cannot create published terrain directory: %s" % error_string(error))
	var target_path := collection_path.path_join(snapshot_hash)
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(target_path)):
		var copy_result := _copy_snapshot(source_path, collection_path)
		if not copy_result["ok"]:
			return copy_result
	var target_validation := validate_snapshot(target_path, snapshot_hash)
	if not target_validation["ok"]:
		return _failure("published immutable terrain snapshot is invalid")
	return {
		"ok": true,
		"manifest": target_validation["manifest"],
		"data_directory": target_path,
	}

func validate_snapshot(directory: String, expected_hash: String) -> Dictionary:
	var manifest_result := _read_manifest(
		directory.path_join(SNAPSHOT_MANIFEST_FILE),
		SNAPSHOT_FIELDS,
	)
	if not manifest_result["ok"]:
		return manifest_result
	var manifest: Dictionary = manifest_result["manifest"]
	if not _valid_snapshot_metadata(manifest):
		return _failure("terrain snapshot metadata is invalid")
	if str(manifest["snapshotHash"]) != expected_hash:
		return _failure("terrain snapshot hash does not match its directory")
	var files_result := _validate_terrain_files(directory, manifest["terrainFiles"])
	if not files_result["ok"]:
		return files_result
	if _snapshot_hash(manifest) != expected_hash:
		return _failure("terrain snapshot content hash does not match")
	return {"ok": true, "manifest": manifest}

func _commit_snapshot(
	pending_path: String,
	collection_path: String,
	manifest: Dictionary,
) -> Dictionary:
	var snapshot_hash := str(manifest["snapshotHash"])
	var validation := validate_snapshot(pending_path, snapshot_hash)
	if not validation["ok"]:
		_discard_directory(pending_path)
		return validation
	var target_path := collection_path.path_join(snapshot_hash)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(target_path)):
		_discard_directory(pending_path)
		validation = validate_snapshot(target_path, snapshot_hash)
		if not validation["ok"]:
			return _failure("existing immutable terrain snapshot is invalid")
	else:
		var error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(pending_path),
			ProjectSettings.globalize_path(target_path),
		)
		if error != OK:
			_discard_directory(pending_path)
			return _failure("cannot commit terrain snapshot: %s" % error_string(error))
	return {
		"ok": true,
		"manifest": manifest,
		"snapshot_hash": snapshot_hash,
		"data_directory": target_path,
	}

func _copy_snapshot(source_path: String, collection_path: String) -> Dictionary:
	var pending_path := _pending_directory(collection_path)
	var error := _ensure_directory(pending_path)
	if error != OK:
		return _failure("cannot create pending published snapshot: %s" % error_string(error))
	var source := DirAccess.open(ProjectSettings.globalize_path(source_path))
	if source == null:
		_discard_directory(pending_path)
		return _failure("cannot open draft terrain snapshot")
	for file_name in source.get_files():
		error = DirAccess.copy_absolute(
			ProjectSettings.globalize_path(source_path.path_join(file_name)),
			ProjectSettings.globalize_path(pending_path.path_join(file_name)),
		)
		if error != OK:
			_discard_directory(pending_path)
			return _failure("cannot copy terrain snapshot: %s" % error_string(error))
	var manifest_result := _read_manifest(
		pending_path.path_join(SNAPSHOT_MANIFEST_FILE),
		SNAPSHOT_FIELDS,
	)
	if not manifest_result["ok"]:
		_discard_directory(pending_path)
		return manifest_result
	return _commit_snapshot(pending_path, collection_path, manifest_result["manifest"])

func _save_workspace(data: Terrain3DData) -> Dictionary:
	var workspace := prepare_empty_workspace()
	if not workspace["ok"]:
		return workspace
	var regions: Array[Terrain3DRegion] = data.get_regions_active()
	if regions.is_empty():
		return _failure("Terrain3D has no active terrain regions")
	for region in regions:
		region.set_modified(true)
		data.save_region(region.get_location(), workspace["data_directory"])
	var files_result := _terrain_files(workspace["data_directory"])
	if not files_result["ok"]:
		return files_result
	if files_result["files"].size() != regions.size():
		return _failure("Terrain3D workspace does not contain every active region")
	return workspace

func _copy_terrain_files(source_path: String, target_path: String) -> Dictionary:
	var files_result := _terrain_files(source_path, true)
	if not files_result["ok"]:
		return files_result
	for record in files_result["files"]:
		var file_name := str(record["file"])
		var error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(source_path.path_join(file_name)),
			ProjectSettings.globalize_path(target_path.path_join(file_name)),
		)
		if error != OK:
			return _failure("cannot copy Terrain3D region: %s" % error_string(error))
	return _terrain_files(target_path)

func _terrain_files(directory: String, allow_snapshot_manifest: bool = false) -> Dictionary:
	var access := DirAccess.open(ProjectSettings.globalize_path(directory))
	if access == null:
		return _failure("cannot inspect Terrain3D snapshot directory")
	var file_names := access.get_files()
	file_names.sort()
	var files: Array[Dictionary] = []
	for file_name in file_names:
		if allow_snapshot_manifest and file_name == SNAPSHOT_MANIFEST_FILE:
			continue
		if not _is_terrain_file(file_name):
			return _failure("Terrain3D snapshot contains an unexpected file: %s" % file_name)
		files.append(_file_record(directory, file_name))
	if files.is_empty():
		return _failure("Terrain3D did not persist any terrain region")
	return {"ok": true, "files": files}

func _validate_terrain_files(directory: String, value: Variant) -> Dictionary:
	if value is not Array or value.is_empty():
		return _failure("terrain snapshot has no region records")
	var expected_names: Array[String] = []
	for record_value in value:
		if record_value is not Dictionary:
			return _failure("terrain snapshot region record is invalid")
		var record: Dictionary = record_value
		if not _has_exact_fields(record, ["file", "sha256", "size"]):
			return _failure("terrain snapshot region fields are invalid")
		var file_name := str(record["file"])
		if not _is_terrain_file(file_name) or expected_names.has(file_name):
			return _failure("terrain snapshot region name is invalid")
		if not _same_file_record(_file_record(directory, file_name), record):
			return _failure("terrain snapshot region content does not match: %s" % file_name)
		expected_names.append(file_name)
	return _verify_snapshot_file_set(directory, expected_names)

func _verify_snapshot_file_set(directory: String, expected_names: Array[String]) -> Dictionary:
	var access := DirAccess.open(ProjectSettings.globalize_path(directory))
	if access == null:
		return _failure("cannot inspect terrain snapshot file set")
	var actual_names := access.get_files()
	actual_names.erase(SNAPSHOT_MANIFEST_FILE)
	actual_names.sort()
	expected_names.sort()
	return (
		{"ok": true}
		if Array(actual_names) == expected_names
		else _failure("terrain snapshot file set is incomplete")
	)

func _file_record(directory: String, file_name: String) -> Dictionary:
	var path := directory.path_join(file_name)
	var file := FileAccess.open(path, FileAccess.READ)
	return {
		"file": file_name,
		"sha256": FileAccess.get_sha256(path),
		"size": file.get_length() if file != null else -1,
	}

func _same_file_record(actual: Dictionary, expected: Dictionary) -> bool:
	return (
		str(actual["file"]) == str(expected["file"])
		and str(actual["sha256"]) == str(expected["sha256"])
		and int(actual["size"]) == int(expected["size"])
	)

func _snapshot_hash(manifest: Dictionary) -> String:
	var parts: Array[String] = [
		str(manifest.get("mapId", "")),
		str(manifest.get("mapContentHash", "")),
		str(manifest.get("authoringProfileHash", "")),
		str(manifest.get("generatedBaseHash", "")),
		str(manifest.get("generatorVersion", "")),
		str(int(manifest.get("rasterWidth", 0))),
		str(int(manifest.get("rasterHeight", 0))),
		str(float(manifest.get("sampleSpacingMeters", 0.0))),
		str(int(manifest.get("terrainRevision", -1))),
	]
	for record in manifest.get("terrainFiles", []):
		parts.append(
			"%s:%s:%s"
			% [record.get("file"), record.get("sha256"), int(record.get("size", -1))]
		)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update("\n".join(parts).to_utf8_buffer())
	return context.finish().hex_encode()

func _snapshot_pointer(manifest: Dictionary, directory: String) -> Dictionary:
	var pointer := {}
	for field in POINTER_FIELDS:
		pointer[field] = directory if field == "terrainDataDirectory" else manifest[field]
	return pointer

func _valid_snapshot_metadata(value: Dictionary) -> bool:
	if str(value.get("mapId", "")).is_empty():
		return false
	for field in ["mapContentHash", "authoringProfileHash", "generatedBaseHash"]:
		if not _is_sha256(value.get(field)):
			return false
	return (
		int(value.get("terrainRevision", -1)) >= 0
		and _is_sha256(value.get("snapshotHash"))
		and not str(value.get("generatorVersion", "")).is_empty()
		and int(value.get("rasterWidth", 0)) > 0
		and int(value.get("rasterHeight", 0)) > 0
		and value.get("sampleSpacingMeters") is float
		and is_finite(value["sampleSpacingMeters"])
		and float(value["sampleSpacingMeters"]) > 0.0
	)

func _same_snapshot_metadata(pointer: Dictionary, manifest: Dictionary) -> bool:
	for field in POINTER_FIELDS:
		if field != "terrainDataDirectory" and pointer.get(field) != manifest.get(field):
			return false
	return true

func _read_manifest(path: String, expected_fields: Array) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("terrain authoring manifest is missing: %s" % path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary or not _has_exact_fields(parsed, expected_fields):
		return _failure("terrain authoring manifest is invalid: %s" % path)
	return {"ok": true, "manifest": parsed}

func _is_terrain_file(file_name: String) -> bool:
	return (
		file_name.get_file() == file_name
		and file_name.begins_with("terrain3d_")
		and file_name.get_extension() == "res"
	)

func _is_sha256(value: Variant) -> bool:
	return (
		value is String
		and value.length() == 64
		and value.to_lower() == value
		and value.is_valid_hex_number(false)
	)

func _has_exact_fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

func _pending_directory(parent: String) -> String:
	return parent.path_join(".pending_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()])

func _ensure_directory(path: String) -> Error:
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func _reset_directory(path: String) -> Error:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		_discard_directory(path)
	return _ensure_directory(path)

func _write_text(path: String, content: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	return OK

func _json_text(value: Dictionary) -> String:
	return JSON.stringify(value, "  ", false) + "\n"

func _discard_directory(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	var directory := DirAccess.open(absolute)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(absolute.path_join(file_name))
	for child in directory.get_directories():
		_discard_directory(path.path_join(child))
	DirAccess.remove_absolute(absolute)

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
