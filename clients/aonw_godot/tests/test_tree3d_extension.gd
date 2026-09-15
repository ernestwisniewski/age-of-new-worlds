extends SceneTree
## Real ConfigFile parsing and native loading; no Terrain3D/gameplay dependency.
const DESCRIPTOR := "res://addons/Tree3D/Tree3D.gdextension"
const FIXTURE := "res://tests/fixtures/tree3d/upstream-v1.1.0.gdextension.txt"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--expect-feature="):
			assert(OS.has_feature(argument.trim_prefix("--expect-feature=")), argument)
	var broken := ConfigFile.new()
	assert(broken.parse(FileAccess.get_file_as_string(FIXTURE)) == OK)
	# The upstream '#' line parses successfully but corrupts the next key.
	assert(not broken.has_section_key("libraries", "macos.debug"))
	var config := ConfigFile.new()
	assert(config.load(DESCRIPTOR) == OK)
	assert(config.has_section_key("infomation", "version"))
	var library_keys := config.get_section_keys("libraries")
	assert(library_keys.size() == 10)
	for key in library_keys:
		assert(not key.contains("#"), "A hash comment must not become part of a library key")
		assert(FileAccess.file_exists(str(config.get_value("libraries", key))), key)
	for build in ["debug", "release"]:
		for arch in ["arm64", "x86_64"]:
			var path := _select(config, ["macos", build, arch])
			assert(path == "res://addons/Tree3D/libTree3D.macos.template_%s.universal" % build)
			assert(FileAccess.file_exists(path))
	if not GDExtensionManager.is_extension_loaded(DESCRIPTOR):
		assert(GDExtensionManager.load_extension(DESCRIPTOR) == GDExtensionManager.LOAD_STATUS_OK)
	assert(GDExtensionManager.is_extension_loaded(DESCRIPTOR), "The native extension must actually load")
	assert(ClassDB.class_exists("Tree3D"), "Tree3D must be registered, not only parseable")
	var tree := ClassDB.instantiate("Tree3D") as Node3D
	assert(tree != null)
	tree.set("seed", 4181)
	var meshes := 0
	for child in tree.get_children(true):
		if child is MeshInstance3D and child.mesh != null:
			assert(child.mesh.get_surface_count() > 0)
			meshes += 1
	assert(meshes == 2, "Native Tree3D must produce a trunk and canopy")
	tree.free()
	print("Tree3D extension: PASS (%s, arm64=%s)" % [OS.get_name(), OS.has_feature("arm64")])
	quit(0)

func _select(config: ConfigFile, features: Array) -> String:
	# Match Godot's longest all-feature-tags match. 'universal' is a filename,
	# not a required OS feature; generic macos.debug is valid for both CPUs.
	var best := ""
	var best_size := 0
	for key in config.get_section_keys("libraries"):
		var tags := key.split(".")
		var matches := true
		for tag in tags:
			if not tag in features:
				matches = false
		if matches and tags.size() > best_size:
			best = str(config.get_value("libraries", key))
			best_size = tags.size()
	return best
