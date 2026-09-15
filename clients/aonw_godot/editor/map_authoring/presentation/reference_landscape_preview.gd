@tool
extends "res://editor/map_authoring/presentation/map_reference_preview.gd"
## Adds replaceable PBR scans and Tree3D instances to the existing reference session.
## Native terrain editing, undo, reference alignment and persistence remain authoritative.

const SurfacePlan := preload("res://editor/map_authoring/infrastructure/terrain/reference_surface_plan.gd")
const SurfaceMaterial := preload("res://editor/map_authoring/presentation/reference_surface_material.gd")
const ForestRenderer := preload("res://editor/map_authoring/presentation/reference_forest.gd")

## Optional atlas-sized grayscale coverage: white forest, black clearing.
## It refines visual placement only and cannot override water or excluded terrain.
@export var forest_guide: Texture2D

var landscape_status := ""
var tree_count := 0
var _surface_plan: RefCounted
var _surface_material: ShaderMaterial
var _forest_root: Node3D
var _forest_timer: Timer
var _forest_signature := ""
var _forest_candidates: Array = []
var _material_warning := ""
var _forest_warning := ""

func rebuild_reference() -> Dictionary:
	var result := super.rebuild_reference()
	if not result["ok"]:
		return result
	var inputs := Inputs.new().load_inputs(source_map_id, map_bundle_root)
	if not inputs["ok"]:
		return _report_failure(str(inputs["message"]))
	var reference_image: Image = inputs["image"]
	if reference_image == null:
		return _report_failure("The reference atlas has no image data")
	if reference_image.is_compressed():
		reference_image = reference_image.duplicate()
		if reference_image.decompress() != OK:
			return _report_failure("Cannot decode the reference atlas")
	var guide: Image
	if forest_guide != null:
		guide = forest_guide.get_image()
		if guide == null or (guide.is_compressed() and guide.decompress() != OK):
			return _report_failure("Cannot decode the forest guide")
	var plan := SurfacePlan.new()
	var configured := plan.configure(artifact(), reference_image, inputs["document"],
		reconstruction["water_mask"], inputs["has_reference"], guide)
	if not configured["ok"]:
		return _report_failure(str(configured["message"]))
	_surface_plan = plan
	_forest_signature = ""
	var value := artifact()
	var material := SurfaceMaterial.build(plan.surface_masks(), _reference_texture,
		Vector2(value.width - 1, value.height - 1) * value.sample_spacing_meters, inputs["has_reference"])
	_material_warning = ""
	_surface_material = null
	if material["ok"]:
		_surface_material = material["material"]
		_surface_material.set_shader_parameter("water_mask", ImageTexture.create_from_image(reconstruction["water_mask"]))
		_relief_material = _surface_material
	else:
		_material_warning = str(material["message"])
		push_warning(_material_warning)
	_apply_presentation(false)
	refresh_overlays()
	_update_landscape_status()
	result["warning"] = _material_warning
	return result

func _apply_presentation(update_camera: bool = true) -> void:
	super._apply_presentation(update_camera)
	if _surface_material != null:
		var values := parameter_values()
		for key in ["ground_scale", "ground_normal_strength", "ground_reference_tint"]:
			_surface_material.set_shader_parameter(key, values[key])
	_queue_forest(false)

func refresh_overlays() -> void:
	super.refresh_overlays()
	_queue_forest(true)

func _apply_visibility() -> void:
	super._apply_visibility()
	if is_instance_valid(_forest_root):
		# A fully opaque reference is a comparison view, not a second forest layer.
		_forest_root.visible = not (reference_visible and _has_reference and reference_opacity >= 0.99)

func _update_opacity(layer: MeshInstance3D, value: float) -> void:
	super._update_opacity(layer, value)
	_apply_visibility()

func show_oblique_view() -> void:
	super.show_oblique_view()
	set_reference_visible(false)
	set_parameter_change({"key": "relief_lighting", "value": 1.0})

func _forest_parameters() -> Dictionary:
	# Pending elevation/seed edits must not leak into the applied landscape.
	var values := Parameters.normalized(terrain_parameters, _source_maximum)
	var result := {"seed": values["seed"]}
	for key in ["tree_density", "tree_spacing", "tree_height", "tree_max_slope", "tree_reference_strength", "tree_draw_distance"]:
		result[key] = values[key]
	return result

func _queue_forest(force_snap: bool) -> void:
	if _surface_plan == null or not preview_ready or not is_inside_tree():
		return
	var signature := JSON.stringify(_forest_parameters())
	if not force_snap and signature == _forest_signature:
		return
	if _forest_timer == null:
		_forest_timer = Timer.new()
		_forest_timer.one_shot = true
		_forest_timer.wait_time = 0.25
		add_child(_forest_timer)
		_forest_timer.timeout.connect(_rebuild_forest)
	_forest_timer.start()

func _rebuild_forest() -> void:
	if _surface_plan == null or not preview_ready:
		return
	var values := _forest_parameters()
	var signature := JSON.stringify(values)
	if signature != _forest_signature:
		_forest_candidates = _surface_plan.call("forest_candidates", values)
		_forest_signature = signature
	var result: Dictionary
	if _forest_candidates.is_empty():
		var empty := Node3D.new()
		empty.name = "ReferenceForest"
		result = {"ok": true, "root": empty, "count": 0}
	else:
		result = ForestRenderer.new().build(_forest_candidates, _terrain.data,
			artifact().sample_spacing_meters, values)
	_forest_warning = ""
	if is_instance_valid(_forest_root):
		remove_child(_forest_root)
		_forest_root.queue_free()
	_forest_root = null
	tree_count = 0
	if result["ok"]:
		_forest_root = result["root"]
		add_child(_forest_root) # owner stays null: the derived forest is not serialized.
		tree_count = int(result["count"])
	else:
		_forest_warning = str(result["message"])
		push_warning(_forest_warning)
	_apply_visibility()
	_update_landscape_status()
	preview_state_changed.emit()

func _update_landscape_status() -> void:
	landscape_status = "PBR ground | Tree3D trees: %d" % tree_count
	if not _material_warning.is_empty():
		landscape_status = _material_warning
	if not _forest_warning.is_empty():
		landscape_status += "\n" + _forest_warning
	var help := get_node_or_null("PreviewHUD/Help") as Label
	if help != null:
		help.text = source_map_id.to_upper() + " | 1: reference  2: landscape  R: compare  G: grid\n" + landscape_status
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	for message in [_material_warning, _forest_warning]:
		if not message.is_empty():
			warnings.append(message)
	return warnings
