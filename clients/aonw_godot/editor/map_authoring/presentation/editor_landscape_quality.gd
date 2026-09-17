@tool
extends RefCounted
## Editor-only draw policy. Never edits candidates, transforms, heights or recipes.
## Full quality restores the very same buffers, without regenerating any trees.

static var _static_shaders: Dictionary = {}

static func apply_forest(root: Node3D, responsive: bool, tree_limit: int) -> int:
	if root == null:
		return 0
	var groups: Array = root.get_meta(&"forest_groups", [])
	var total := 0
	for group in groups:
		total += int(group["count"])
	var limit := mini(total, maxi(0, tree_limit)) if responsive else total
	var cumulative := 0
	var assigned := 0
	var materials: Dictionary = root.get_meta(&"editor_materials", {})
	for group in groups:
		cumulative += int(group["count"])
		# Allocate one global budget proportionally, with no per-chunk rounding loss.
		# The paired trunk/canopy batches always display the same prefix.
		var next := floori(float(cumulative) * limit / maxi(total, 1))
		var count := next - assigned
		assigned = next
		for batch in group["nodes"]:
			var instance: MultiMeshInstance3D = batch
			instance.multimesh.visible_instance_count = count if responsive else -1
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if responsive else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED if responsive else GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			var full: Material = instance.get_meta(&"full_material")
			if responsive and full is ShaderMaterial:
				var key := full.get_instance_id()
				if not materials.has(key):
					var light := full.duplicate() as ShaderMaterial
					light.shader = static_shader(full.shader)
					materials[key] = light
				instance.material_override = materials[key]
			else:
				instance.material_override = full
	root.set_meta(&"editor_materials", materials)
	return assigned

static func apply_water(surface: MeshInstance3D, responsive: bool) -> void:
	if surface == null or not surface.material_override is ShaderMaterial:
		return
	var material := surface.material_override as ShaderMaterial
	if not surface.has_meta(&"full_shader"):
		surface.set_meta(&"full_shader", material.shader)
	if responsive:
		if not surface.has_meta(&"static_shader"):
			surface.set_meta(&"static_shader", static_shader(material.shader))
		material.shader = surface.get_meta(&"static_shader")
	else:
		material.shader = surface.get_meta(&"full_shader")

static func static_shader(source: Shader) -> Shader:
	# Only used with the bundled water/tree shaders. Removing TIME entirely (not
	# multiplying it by zero) lets the editor stop redrawing an otherwise idle view.
	if _static_shaders.has(source.code):
		return _static_shaders[source.code]
	var shader := Shader.new()
	var token := RegEx.new()
	token.compile("\\bTIME\\b")
	shader.code = token.sub(source.code, "0.0", true)
	_static_shaders[source.code] = shader
	return shader
