@tool
class_name AonwSceneSerializationRepair
extends RefCounted

const AtomicResourceStore := preload(
	"res://editor/map_authoring/infrastructure/atomic_resource_store.gd"
)
const Detector := preload(
	"res://editor/map_authoring/infrastructure/scene_serialization_detector.gd"
)
const OwnershipPolicy := preload(
	"res://editor/map_authoring/application/scene_ownership_policy.gd"
)
const Validator := preload(
	"res://editor/map_authoring/application/scene_serialization_validator.gd"
)

var _atomic_store := AtomicResourceStore.new()
var _detector := Detector.new()
var _policy := OwnershipPolicy.new()
var _validator := Validator.new()

func preview(scene_path: String, output_directory: String) -> Dictionary:
	var before := _detector.inspect(scene_path)
	if not before["ok"]:
		return before
	if output_directory.is_empty() or _contains_glob(output_directory):
		return _failure("Repair preview requires one exact output directory.")
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(output_directory)
	)
	if directory_error != OK:
		return _failure("Repair preview directory could not be created.")
	var source_hash: String = before["sha256"]
	var stem := scene_path.get_file().get_basename()
	var identity := source_hash.left(12)
	var backup_path := output_directory.path_join("%s.%s.before.tscn" % [stem, identity])
	var candidate_path := output_directory.path_join("%s.%s.repaired.tscn" % [stem, identity])
	var manifest_path := output_directory.path_join("%s.%s.repair.json" % [stem, identity])
	var backup_error := _copy_exact(scene_path, backup_path)
	if backup_error != OK:
		return _failure("Repair backup could not be created: %s" % error_string(backup_error))
	var packed := ResourceLoader.load(
		scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	if packed == null:
		return _failure("Repair source could not be loaded after its backup was created.")
	var root := packed.instantiate()
	var surface := root.find_child("TerrainAuthoring", true, false)
	if surface == null:
		root.free()
		return _failure("Repair source has no TerrainAuthoring surface.")
	var stable_before := _policy.persistent_identities(root, surface)
	var removed_paths := _policy.transient_owned_paths(root, surface)
	var ownership_changes := _policy.apply(root, surface)
	var validation := _validator.result_for(root)
	if not validation["ok"]:
		root.free()
		return _failure("Repair candidate still violates scene ownership policy.")
	var candidate := PackedScene.new()
	var save_error := candidate.pack(root)
	root.free()
	if save_error == OK:
		save_error = ResourceSaver.save(candidate, candidate_path)
	if save_error != OK:
		return _failure("Repair candidate could not be saved: %s" % error_string(save_error))
	var verification := _verify_candidate(candidate_path, stable_before)
	if not verification["ok"]:
		return verification
	var after := _detector.inspect(candidate_path)
	if not after["ok"]:
		return after
	var manifest := {
		"schemaVersion": 1,
		"sourcePath": scene_path,
		"backupPath": backup_path,
		"candidatePath": candidate_path,
		"sourceSha256": source_hash,
		"backupSha256": FileAccess.get_sha256(backup_path),
		"candidateSha256": after["sha256"],
		"beforeByteSize": before["byte_size"],
		"afterByteSize": after["byte_size"],
		"beforeEmbeddedResourceTypes": before["embedded_resource_types"],
		"afterEmbeddedResourceTypes": after["embedded_resource_types"],
		"estimatedRepairedByteSize": before["estimated_repaired_byte_size"],
		"removedTransientNodePaths": removed_paths,
		"ownershipChanges": ownership_changes,
		"stableNodeIdentities": stable_before,
	}
	var manifest_error := _atomic_store.write_text(
		manifest_path,
		JSON.stringify(manifest, "\t", true),
	)
	if manifest_error != OK:
		return _failure("Repair manifest could not be saved: %s" % error_string(manifest_error))
	if FileAccess.get_sha256(scene_path) != source_hash:
		return _failure("Repair preview changed its source scene unexpectedly.")
	return {
		"ok": true,
		"manifest_path": manifest_path,
		"manifest_sha256": FileAccess.get_sha256(manifest_path),
		"manifest": manifest,
		"before": before,
		"after": after,
	}

func apply_preview(manifest_path: String, expected_manifest_sha256: String) -> Dictionary:
	if not _is_exact_manifest_path(manifest_path):
		return _failure("Repair apply requires one exact .repair.json manifest path.")
	if FileAccess.get_sha256(manifest_path) != expected_manifest_sha256:
		return _failure("Repair manifest identity changed after review.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		return _failure("Repair manifest is malformed.")
	var source_path := str(parsed.get("sourcePath", ""))
	var backup_path := str(parsed.get("backupPath", ""))
	var candidate_path := str(parsed.get("candidatePath", ""))
	if not _is_exact_scene_path(source_path) or not _is_exact_scene_path(candidate_path):
		return _failure("Repair manifest does not identify exact scene files.")
	if FileAccess.get_sha256(source_path) != str(parsed.get("sourceSha256", "")):
		return _failure("Repair source changed after preview; create a new preview.")
	if FileAccess.get_sha256(backup_path) != str(parsed.get("backupSha256", "")):
		return _failure("Repair backup identity does not match its manifest.")
	if FileAccess.get_sha256(candidate_path) != str(parsed.get("candidateSha256", "")):
		return _failure("Repair candidate identity does not match its manifest.")
	var pending_path := "%s.aonw-repair-pending.tscn" % source_path.get_basename()
	var rollback_path := "%s.aonw-repair-rollback.tscn" % source_path.get_basename()
	var copy_error := _copy_exact(candidate_path, pending_path)
	if copy_error != OK:
		return _failure("Repair candidate could not be staged.")
	var source_absolute := ProjectSettings.globalize_path(source_path)
	var pending_absolute := ProjectSettings.globalize_path(pending_path)
	var rollback_absolute := ProjectSettings.globalize_path(rollback_path)
	var rename_error := DirAccess.rename_absolute(source_absolute, rollback_absolute)
	if rename_error != OK:
		DirAccess.remove_absolute(pending_absolute)
		return _failure("Repair source could not be moved to rollback staging.")
	rename_error = DirAccess.rename_absolute(pending_absolute, source_absolute)
	if rename_error != OK:
		DirAccess.rename_absolute(rollback_absolute, source_absolute)
		return _failure("Repair candidate could not replace its source.")
	DirAccess.remove_absolute(rollback_absolute)
	return {
		"ok": true,
		"scene_path": source_path,
		"sha256": FileAccess.get_sha256(source_path),
		"backup_path": backup_path,
	}

func _verify_candidate(candidate_path: String, stable_before: Array[String]) -> Dictionary:
	var packed := ResourceLoader.load(
		candidate_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	if packed == null:
		return _failure("Repair candidate cannot be reopened.")
	var root := packed.instantiate()
	var surface := root.find_child("TerrainAuthoring", true, false)
	if surface == null:
		root.free()
		return _failure("Repair candidate lost TerrainAuthoring.")
	var stable_after := _policy.persistent_identities(root, surface)
	var validation := _validator.result_for(root)
	root.free()
	if stable_after != stable_before:
		return _failure("Repair candidate changed stable authored node identities.")
	if not validation["ok"]:
		return _failure("Repair candidate failed the pre-save validator.")
	return {"ok": true}

func _copy_exact(source_path: String, target_path: String) -> Error:
	if FileAccess.file_exists(target_path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(target_path))
		if remove_error != OK:
			return remove_error
	return DirAccess.copy_absolute(
		ProjectSettings.globalize_path(source_path),
		ProjectSettings.globalize_path(target_path),
	)

func _contains_glob(path: String) -> bool:
	return path.contains("*") or path.contains("?") or path.contains("[") or path.contains("]")

func _is_exact_scene_path(path: String) -> bool:
	return not _contains_glob(path) and path.get_extension().to_lower() == "tscn"

func _is_exact_manifest_path(path: String) -> bool:
	return not _contains_glob(path) and path.ends_with(".repair.json")

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
