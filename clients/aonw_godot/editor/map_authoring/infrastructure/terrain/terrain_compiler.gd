@tool
class_name AonwTerrainCompiler
extends RefCounted

func compile_profiles() -> Dictionary:
	var script_path := ProjectSettings.globalize_path(
		"res://../../tool/compile_godot_terrain.sh"
	)
	var output: Array = []
	var exit_code := OS.execute(
		"/bin/bash",
		PackedStringArray([script_path]),
		output,
		true,
	)
	if exit_code == 0:
		return {"ok": true}
	var diagnostics := "\n".join(output).strip_edges()
	return {
		"ok": false,
		"message": "terrain compilation failed%s" % (
			": %s" % diagnostics if not diagnostics.is_empty() else ""
		),
	}
