@tool
extends RefCounted
## A separate water surface precisely clipped by the same mask that carved the banks.
const WATER_SHADER := preload("res://editor/map_authoring/presentation/reference_water.gdshader")

static func build(masks: Dictionary, extent: Vector2, has_reference: bool) -> MeshInstance3D:
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	for pair in [["water_profile", "water_profile"], ["water_mask", "water"], ["shore_distance", "shore_distance"], ["coverage", "coverage"], ["palette", "macro"]]:
		material.set_shader_parameter(pair[0], ImageTexture.create_from_image(masks[pair[1]]))
	material.set_shader_parameter("sample_spacing", float(masks.get("sample_spacing", 1.0)))
	material.set_shader_parameter("has_reference", has_reference)
	var mesh := PlaneMesh.new()
	mesh.size = extent
	var surface := MeshInstance3D.new()
	surface.name = "ReferenceWater"
	surface.mesh = mesh
	surface.position = Vector3(extent.x * 0.5, 0.09, extent.y * 0.5)
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface.set_meta(&"aonw_generated", true)
	return surface

static func apply(surface: MeshInstance3D, parameters: Dictionary) -> void:
	if surface == null:
		return
	var material := surface.material_override as ShaderMaterial
	for key in ["water_depth", "water_bed_slope", "water_shore_width", "water_waves", "water_reference_colour"]:
		material.set_shader_parameter(key, parameters[key])
