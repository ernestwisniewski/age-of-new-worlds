extends SceneTree
## Native Terrain3D smoke test for ALL bundles, not a hardcoded Dravonia clone.
## No persistent writes unless explicitly invoked with -- --save.

const PreviewScene := preload("res://scenes/terrain_authoring/reference_terrain.tscn")
const BUNDLE_ROOT := "res://assets/maps"
var _failures := PackedStringArray()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var map_ids := DirAccess.get_directories_at(BUNDLE_ROOT)
	map_ids.sort()
	var tested := 0
	var save_requested := "--save" in OS.get_cmdline_user_args()
	for map_id in map_ids:
		var bundle := BUNDLE_ROOT.path_join(map_id)
		if not FileAccess.file_exists(bundle.path_join("map.json")):
			continue
		var preview = PreviewScene.instantiate()
		preview.source_map_id = map_id
		preview.frame_on_open = false
		root.add_child(preview)
		for _frame in 30:
			await process_frame
			if preview.preview_ready or not preview.preview_error.is_empty():
				break
		if not preview.preview_ready:
			_failures.append("%s: %s" % [map_id, preview.preview_error])
		else:
			tested += 1
			var artifact: AonwTerrainCompiledArtifact = preview.artifact()
			if artifact.map_id != map_id:
				_failures.append("%s: loaded the wrong map" % map_id)
			var mask: Image = preview.reconstruction["water_mask"]
			for y in range(0, artifact.height, 11):
				for x in range(0, artifact.width, 11):
					var pixel := Vector2i(x, y)
					var actual: float = preview.height_at(pixel)
					if not is_finite(actual):
						_failures.append("%s: non-finite native terrain at %s" % [map_id, pixel])
					elif mask.get_pixelv(pixel).r >= 0.5 and absf(actual) > 0.0005:
						_failures.append("%s: native water is not zero at %s" % [map_id, pixel])
			if save_requested:
				var saved: Dictionary = preview.save_draft()
				if not saved["ok"]:
					_failures.append("%s: %s" % [map_id, saved["message"]])
			print("Reference map checked: %s (%dx%d)" % [map_id, artifact.width, artifact.height])
		root.remove_child(preview)
		preview.free()
		await process_frame
	if tested == 0:
		_failures.append("No reference map bundles were tested")
	for failure in _failures:
		push_error(failure)
	print("Reference maps: %d checked; %d failures" % [tested, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
