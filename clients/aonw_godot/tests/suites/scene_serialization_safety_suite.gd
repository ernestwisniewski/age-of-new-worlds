extends RefCounted

const Detector := preload(
	"res://editor/map_authoring/infrastructure/scene_serialization_detector.gd"
)
const Repair := preload(
	"res://editor/map_authoring/infrastructure/scene_serialization_repair.gd"
)
const OwnershipPolicy := preload(
	"res://editor/map_authoring/application/scene_ownership_policy.gd"
)
const Validator := preload(
	"res://editor/map_authoring/application/scene_serialization_validator.gd"
)
const SceneFactory := preload(
	"res://editor/map_authoring/presentation/terrain_authoring_scene_factory.gd"
)

var _failures: Array[String]
var _test_root: String
var _detector := Detector.new()
var _policy := OwnershipPolicy.new()
var _validator := Validator.new()

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_root = "res://.godot/scene_safety_test/%s" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_root))
	_test_validator_and_read_only_detector()
	_test_repair_preview_and_explicit_apply()
	_test_clean_scene_round_trips(7, 7, true)
	_test_clean_scene_round_trips(40, 30, false)

func _test_validator_and_read_only_detector() -> void:
	var scene_path := _test_root.path_join("unsafe_fixture.tscn")
	var fixture := _unsafe_fixture()
	var root: Node = fixture["root"]
	var surface: Node = fixture["surface"]
	var validation := _validator.result_for(root)
	_check(not validation["ok"], "pre-save validator rejects owned transient rendering nodes")
	_check(
		_problem_codes(validation["problems"]).has("transient_node_owned"),
		"pre-save failure is a typed transient ownership Problem",
	)
	_check(_save_root(root, scene_path) == OK, "unsafe serialization fixture can be reproduced")
	root.free()
	var hash_before := FileAccess.get_sha256(scene_path)
	var report := _detector.inspect(scene_path)
	_check(report["ok"], "read-only scene detector inspects an exact fixture path")
	_check(
		report["dangerous_resource_types"].has("Image")
		and report["dangerous_resource_types"].has("ArrayMesh")
		and report["dangerous_resource_types"].has("MultiMesh")
		and report["dangerous_resource_types"].has("ImageTexture"),
		"detector reports embedded Image, ImageTexture, ArrayMesh and MultiMesh resources",
	)
	_check(
		FileAccess.get_sha256(scene_path) == hash_before,
		"scene detector leaves source bytes unchanged",
	)
	_check(
		not _detector.inspect(_test_root.path_join("*.tscn"))["ok"],
		"scene detector rejects glob paths",
	)
	var loaded := _load_root(scene_path)
	_check(loaded != null, "unsafe fixture reopens for ownership-policy validation")
	if loaded == null:
		return
	surface = loaded.find_child("TerrainAuthoring", true, false)
	_policy.apply(loaded, surface)
	_check(
		_validator.result_for(loaded)["ok"],
		"explicit ownership policy removes the pre-save violation",
	)
	loaded.free()

func _test_repair_preview_and_explicit_apply() -> void:
	var scene_path := _test_root.path_join("repair_fixture.tscn")
	var fixture := _unsafe_fixture()
	_check(
		_save_root(fixture["root"], scene_path) == OK,
		"repair fixture can be serialized",
	)
	fixture["root"].free()
	var source_hash := FileAccess.get_sha256(scene_path)
	var repair := Repair.new()
	var preview := repair.preview(scene_path, _test_root.path_join("repair_preview"))
	_check(preview["ok"], "repair preview creates a safe candidate and manifest")
	if not preview["ok"]:
		return
	var manifest: Dictionary = preview["manifest"]
	_check(
		FileAccess.get_sha256(scene_path) == source_hash
		and manifest["sourceSha256"] == source_hash
		and manifest["backupSha256"] == source_hash,
		"repair preview preserves source bytes and creates an exact backup",
	)
	_check(
		manifest["removedTransientNodePaths"].has("TerrainAuthoring/ReferenceTexture")
		and manifest["removedTransientNodePaths"].has("TerrainAuthoring/GeneratedWorld"),
		"repair manifest names the transient nodes removed from serialization",
	)
	_check(
		preview["after"]["dangerous_resource_types"].is_empty(),
		"repair candidate contains no transient embedded rendering resource",
	)
	var candidate_root := _load_root(manifest["candidatePath"])
	_check(candidate_root != null, "repair candidate reopens")
	if candidate_root != null:
		_check(
			candidate_root.get_node_or_null("TerrainAuthoring/ManualWorld/ManualLandmark") != null
			and candidate_root.get_node_or_null("TerrainAuthoring/Terrain3D") != null,
			"repair preserves ManualWorld, manual authored nodes and Terrain3D",
		)
		_check(
			candidate_root.get_node_or_null("TerrainAuthoring/ReferenceTexture") == null
			and candidate_root.get_node_or_null("TerrainAuthoring/GeneratedWorld") == null,
			"repair candidate omits runtime reference and generated preview nodes",
		)
		candidate_root.free()
	_check(
		not repair.apply_preview(preview["manifest_path"], "0".repeat(64))["ok"],
		"repair apply rejects an unreviewed manifest identity",
	)
	var applied := repair.apply_preview(
		preview["manifest_path"],
		preview["manifest_sha256"],
	)
	_check(applied["ok"], "reviewed repair applies to one exact fixture path")
	if applied["ok"]:
		_check(
			_detector.inspect(scene_path)["dangerous_resource_types"].is_empty()
			and FileAccess.get_sha256(manifest["backupPath"]) == source_hash,
			"applied repair keeps its backup and leaves a clean scene",
		)

func _test_clean_scene_round_trips(cols: int, rows: int, with_manual_mesh: bool) -> void:
	var map_id := "fixture_%dx%d" % [cols, rows]
	var scene_path := _test_root.path_join("%s.tscn" % map_id)
	var packed := SceneFactory.new().create_scene(
		map_id,
		"res://.godot/terrain_compiled/%s" % map_id,
		_test_root.path_join("assets/%s" % map_id),
	)
	_check(packed != null, "%s clean scene can be created" % map_id)
	if packed == null:
		return
	_check(ResourceSaver.save(packed, scene_path) == OK, "%s clean scene can be saved" % map_id)
	var root := _load_root(scene_path)
	_check(root != null, "%s clean scene can be opened" % map_id)
	if root == null:
		return
	root.set_meta("fixture_dimensions", Vector2i(cols, rows))
	var surface := root.find_child("TerrainAuthoring", true, false)
	surface.reference_visible = false
	if with_manual_mesh:
		var landmark := MeshInstance3D.new()
		landmark.name = "AuthoredManualMesh"
		landmark.mesh = BoxMesh.new()
		surface.get_node("ManualWorld").add_child(landmark)
	_policy.apply(root, surface)
	_check(_validator.result_for(root)["ok"], "%s edited scene passes pre-save safety" % map_id)
	_check(_save_root(root, scene_path) == OK, "%s edited scene can be saved" % map_id)
	root.free()
	var reopened := _load_root(scene_path)
	_check(reopened != null, "%s edited scene can be reopened" % map_id)
	if reopened == null:
		return
	var reopened_surface := reopened.find_child("TerrainAuthoring", true, false)
	_check(
		reopened.get_meta("fixture_dimensions") == Vector2i(cols, rows)
		and not reopened_surface.reference_visible,
		"%s edit survives save and reopen" % map_id,
	)
	if with_manual_mesh:
		_check(
			reopened.get_node_or_null("TerrainAuthoring/ManualWorld/AuthoredManualMesh") != null,
			"%s preserves a manual authored object" % map_id,
		)
	var report := _detector.inspect(scene_path)
	_check(
		report["ok"]
		and report["byte_size"] <= Detector.REVIEW_SIZE_BYTES
		and report["dangerous_resource_types"].is_empty(),
		"%s stays below the proposed 256 KiB review threshold" % map_id,
	)
	reopened.free()

func _unsafe_fixture() -> Dictionary:
	var root := Node3D.new()
	root.name = "UnsafeFixture"
	var surface := Node3D.new()
	surface.name = "TerrainAuthoring"
	root.add_child(surface)
	surface.owner = root
	var terrain := Node3D.new()
	terrain.name = "Terrain3D"
	surface.add_child(terrain)
	terrain.owner = root
	var manual_world := Node3D.new()
	manual_world.name = "ManualWorld"
	surface.add_child(manual_world)
	manual_world.owner = root
	var landmark := Node3D.new()
	landmark.name = "ManualLandmark"
	manual_world.add_child(landmark)
	landmark.owner = root
	var reference := MeshInstance3D.new()
	reference.name = "ReferenceTexture"
	reference.mesh = _array_mesh()
	var material := StandardMaterial3D.new()
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.CORNFLOWER_BLUE)
	material.albedo_texture = ImageTexture.create_from_image(image)
	reference.material_override = material
	surface.add_child(reference)
	reference.owner = root
	var cursor := MeshInstance3D.new()
	cursor.name = "LogicalMapCursor"
	cursor.mesh = _array_mesh()
	surface.add_child(cursor)
	cursor.owner = root
	var generated_world := Node3D.new()
	generated_world.name = "GeneratedWorld"
	surface.add_child(generated_world)
	generated_world.owner = root
	var generated := MultiMeshInstance3D.new()
	generated.name = "GeneratedPreview"
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = BoxMesh.new()
	multi_mesh.instance_count = 1
	generated.multimesh = multi_mesh
	generated_world.add_child(generated)
	generated.owner = root
	return {"root": root, "surface": surface}

func _array_mesh() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3.ZERO,
		Vector3.RIGHT,
		Vector3.FORWARD,
	])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _save_root(root: Node, path: String) -> Error:
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error != OK:
		return error
	return ResourceSaver.save(packed, path)

func _load_root(path: String) -> Node:
	var packed := ResourceLoader.load(
		path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	return null if packed == null else packed.instantiate()

func _problem_codes(problems: Array) -> Array[String]:
	var result: Array[String] = []
	for problem in problems:
		result.append(String(problem.code))
	return result

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
