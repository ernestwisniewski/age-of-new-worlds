@tool
extends RefCounted
## Tree3D generates six shared prototypes, never one native generator per instance.
## The native addon owns INTERNAL children; get_children(true) is intentional.

const ROOT := "res://assets/reference_materials/trees/"
# Branches3 is an entire bare-tree stamp, not foliage. Do not repeat it on
# tropical branch cards; broad/tropical forms share the actual leaf texture.
const LEAF_TEXTURES := ["Branches1.png", "Branches2.png", "Branches1.png"]
const SHADER := preload("res://editor/map_authoring/presentation/reference_tree.gdshader")
static var _prototypes: Dictionary = {}

static func load_library() -> Dictionary:
	if not _prototypes.is_empty():
		return {"ok": true, "prototypes": _prototypes}
	if not ClassDB.class_exists("Tree3D"):
		return {"ok": false, "message": "Tree3D is not loaded. Run python3 clients/aonw_godot/tool/install_reference_assets.py and restart Godot."}
	var textures := {}
	for file in ["bark.jpg", "bark_normal.png", "Branches1.png", "Branches2.png"]:
		var path: String = ROOT + file
		if not FileAccess.file_exists(path):
			return {"ok": false, "message": "Missing Tree3D texture: " + file + ". Run install_reference_assets.py."}
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			return {"ok": false, "message": "Cannot decode Tree3D texture: " + file}
		image.generate_mipmaps()
		textures[file] = ImageTexture.create_from_image(image)
	var built := {}
	for species in 3:
		for variant in 2:
			var prototype := _generate(species, variant, textures)
			if not prototype["ok"]:
				return prototype
			built[species * 2 + variant] = prototype
	_prototypes = built
	return {"ok": true, "prototypes": _prototypes}

static func _generate(species: int, variant: int, textures: Dictionary) -> Dictionary:
	var tree := ClassDB.instantiate("Tree3D") as Node3D
	if tree == null:
		return {"ok": false, "message": "Tree3D native class could not be instantiated"}
	# Counts are recursive branch levels, NOT the number of visible branches.
	var profile := {"trunk_branches_count": 5, "trunk_segments": 6,
		"trunk_height": 5, "trunk_length": 2.4, "trunk_branch_length": 2.1,
		"trunk_branch_length_falloff": 0.83, "trunk_max_radius": 0.17,
		"trunk_radius_falloff_rate": 0.68, "twig_scale": 1.6,
		"trunk_climb_rate": 0.45, "trunk_kink": 0.1, "collision_enabled": false}
	if species == 1:
		profile.merge({"trunk_height": 8, "trunk_length": 3.2, "trunk_branch_length": 1.4,
			"trunk_branch_length_falloff": 0.74, "trunk_climb_rate": 0.65,
			"trunk_drop_amount": -0.14, "twig_scale": 1.35}, true)
	elif species == 2:
		profile.merge({"trunk_length": 3.0, "trunk_branch_length": 2.7,
			"trunk_branch_length_falloff": 0.88, "twig_scale": 1.9}, true)
	for key in profile:
		tree.set(key, profile[key])
	tree.set("seed", 4181 + species * 1301 + variant * 379)
	var bark := ShaderMaterial.new()
	bark.shader = SHADER
	bark.set_shader_parameter("albedo_texture", textures["bark.jpg"])
	bark.set_shader_parameter("normal_texture", textures["bark_normal.png"])
	var leaves := ShaderMaterial.new()
	leaves.shader = SHADER
	leaves.set_shader_parameter("foliage", true)
	leaves.set_shader_parameter("albedo_texture", textures[LEAF_TEXTURES[species]])
	leaves.set_shader_parameter("tint", Color(0.78, 0.9, 0.72) if species == 1 else Color.WHITE)
	tree.set("material_trunk", bark)
	tree.set("material_twig", leaves)
	var parts: Array = []
	var bounds := AABB()
	var first := true
	for child in tree.get_children(true):
		var instance := child as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var box: AABB = instance.transform * instance.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		parts.append({"mesh": instance.mesh, "transform": instance.transform,
			"material": instance.get_active_material(0)})
	tree.free()
	if parts.size() != 2 or bounds.size.y <= 0.01:
		return {"ok": false, "message": "Tree3D did not generate a trunk and textured canopy"}
	return {"ok": true, "parts": parts, "height": bounds.size.y, "base_y": bounds.position.y}
