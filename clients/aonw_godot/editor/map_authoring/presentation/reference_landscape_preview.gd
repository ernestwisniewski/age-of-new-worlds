@tool
extends "res://editor/map_authoring/presentation/map_reference_preview.gd"
## Derived presentation, sharing one reference transform, native heightfield and water mask.
const SurfacePlan := preload("res://editor/map_authoring/infrastructure/terrain/reference_surface_plan.gd")
const SurfaceMaterial := preload("res://editor/map_authoring/presentation/reference_surface_material.gd")
const ForestRenderer := preload("res://editor/map_authoring/presentation/reference_forest.gd")
const MeshNormals := preload("res://editor/map_authoring/presentation/reference_mesh_normals.gd")
const WaterSurface := preload("res://editor/map_authoring/presentation/reference_water_surface.gd")

const ProfileMigration := preload("res://editor/map_authoring/application/landscape_profile_migration.gd")
@export_storage var landscape_profile_revision := 0

const CityLayout := preload("res://editor/map_authoring/infrastructure/terrain/city_hex_layout.gd")
const CityPreview := preload("res://editor/map_authoring/presentation/city_hex_preview.gd")

## Optional future city/rock/building mockup: metre-authored, Y-up, centred at origin.
@export var city_preview_scene: PackedScene:
	set(value):
		city_preview_scene = value
		_queue_forest(true)
var _city_preview_root: Node3D
var _city_layout: Dictionary = {}
var _city_warning := ""

## Atlas-sized coverage: white woodland, black clearing. Exclusions still apply.
@export var forest_guide: Texture2D
var landscape_status := ""
var landscape_ready := false
var tree_count := 0
var _surface_plan: RefCounted
var _surface_material: ShaderMaterial
var _water_surface: MeshInstance3D
var _forest_root: Node3D
var _forest_timer: Timer
var _mask_timer: Timer
var _mask_signature := ""
var _forest_signature := ""
var _forest_candidates: Array = []
var _masks: Dictionary = {}
var _material_warning := ""
var _forest_warning := ""

func _ready() -> void:
	if landscape_profile_revision < 1:
		terrain_parameters = ProfileMigration.migrate(terrain_parameters)
		landscape_profile_revision = 1
	super._ready()

func rebuild_reference() -> Dictionary:
	# Validate an optional guide before the native session can be replaced.
	var guide: Image
	if forest_guide != null:
		guide = forest_guide.get_image()
		if guide == null or (guide.is_compressed() and guide.decompress() != OK):
			return _report_failure("Cannot decode the forest guide")
		if guide.is_empty():
			return _report_failure("The forest guide is empty")
	var result := super.rebuild_reference()
	if not result["ok"]:
		return result
	landscape_ready = false
	var reference_image: Image = _reference_inputs["image"]
	var plan := SurfacePlan.new()
	var configured := plan.configure(artifact(), reference_image, _reference_inputs["document"],
		reconstruction["water_mask"], _has_reference, guide)
	if not configured["ok"]:
		return _report_failure(str(configured["message"]))
	_surface_plan = plan
	_refresh_materials()
	refresh_overlays()
	_update_landscape_status()
	result["warning"] = _material_warning
	return result

func _refresh_materials() -> void:
	var values := parameter_values()
	values["seed"] = Parameters.normalized(terrain_parameters, _source_maximum)["seed"]
	_masks = _surface_plan.call("surface_masks", values)
	_mask_signature = _mask_key()
	_forest_signature = ""
	var value := artifact()
	var extent := Vector2(value.width - 1, value.height - 1) * value.sample_spacing_meters
	var material := SurfaceMaterial.build(_masks, _reference_texture, extent, _has_reference)
	_material_warning = ""
	_surface_material = null
	if is_instance_valid(_water_surface):
		remove_child(_water_surface)
		_water_surface.queue_free()
	_water_surface = null
	if material["ok"]:
		_surface_material = material["material"]
		_surface_material.set_shader_parameter("water_mask", ImageTexture.create_from_image(reconstruction["water_mask"]))
		_relief_material = _surface_material
		_water_surface = WaterSurface.build(_masks, extent, _has_reference)
		add_child(_water_surface)
	else:
		_material_warning = str(material["message"])
		push_warning(_material_warning)
	if _reference != null:
		_reference.material_override = _relief_material
	_apply_presentation(false)
	_apply_visibility()

func _mask_key() -> String:
	var values := parameter_values()
	var key := [values["surface_reference_strength"], values["tree_canopy_threshold"]]
	for name in ["forest_distribution", "forest_patch_size", "forest_patch_coverage", "forest_edge_softness"]:
		key.append(values[name])
	# Pending geometry seeds must not reshuffle the applied forest before Apply.
	key.append(Parameters.normalized(terrain_parameters, _source_maximum)["seed"])
	return JSON.stringify(key)

func _apply_presentation(update_camera: bool = true) -> void:
	super._apply_presentation(update_camera)
	var values := parameter_values()
	if _surface_material != null:
		for key in ["ground_scale", "ground_normal_strength", "ground_reference_tint", "water_depth", "water_bed_slope"]:
			_surface_material.set_shader_parameter(key, values[key])
	WaterSurface.apply(_water_surface, values)
	if _surface_plan != null and is_inside_tree() and _mask_signature != _mask_key():
		if _mask_timer == null:
			_mask_timer = Timer.new()
			_mask_timer.one_shot = true
			_mask_timer.wait_time = 0.3
			add_child(_mask_timer)
			_mask_timer.timeout.connect(_refresh_materials)
		landscape_ready = false
		if _forest_timer != null:
			_forest_timer.stop()
		_mask_timer.start()
		return
	_queue_forest(false)

func refresh_overlays() -> void:
	super.refresh_overlays()
	_update_surface_normals()
	_queue_forest(true)

func _refresh_overlays_deferred() -> void:
	super._refresh_overlays_deferred()
	_update_surface_normals()
	# The native brush updates mesh vertices directly, bypassing refresh_overlays().
	_queue_forest(true)

func _apply_visibility() -> void:
	super._apply_visibility()
	var reference_only := reference_visible and _has_reference and reference_opacity >= 0.99
	if is_instance_valid(_forest_root):
		_forest_root.visible = not reference_only
	if is_instance_valid(_water_surface):
		_water_surface.visible = not reference_only
	if is_instance_valid(_city_preview_root):
		_city_preview_root.visible = not reference_only
		var guides := _city_preview_root.get_node_or_null("FootprintGuides") as Node3D
		if guides != null:
			guides.visible = city_marker_visible
			if _city_marker != null:
				_city_marker.visible = false # The draped guide replaces the flat legacy disk.
	if _reference != null:
		_reference.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if _surface_material != null and not reference_only else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_reference.extra_cull_margin = 30.0
	if _terrain != null:
		# Data/collision/CPU picking remain native. Drawing both coincident surfaces
		# caused z-fighting and exposed unused square native regions outside the map.
		_terrain.visible = _surface_material == null

func _update_opacity(layer: MeshInstance3D, value: float) -> void:
	super._update_opacity(layer, value)
	_apply_visibility()

func show_oblique_view() -> void:
	super.show_oblique_view()
	set_reference_visible(false)
	set_parameter_change({"key": "relief_lighting", "value": 1.0})

func _forest_parameters() -> Dictionary:
	var values := Parameters.normalized(terrain_parameters, _source_maximum)
	var result := {"seed": values["seed"]}
	for key in ["tree_density", "tree_spacing", "tree_height", "tree_max_slope", "tree_reference_strength", "tree_draw_distance", "tree_conifer_share", "forest_distribution", "forest_patch_size", "forest_patch_coverage", "forest_edge_softness", "forest_tree_budget"]:
		result[key] = values[key]
	for field in Parameters.FIELDS:
		if field[6] == "city":
			result[field[0]] = values[field[0]]
	result["city_column"] = city_marker_coordinate.x
	result["city_row"] = city_marker_coordinate.y
	return CityLayout.forest_parameters(artifact(), result)

func _queue_forest(force_snap: bool) -> void:
	if _surface_plan == null or not preview_ready or not is_inside_tree():
		return
	if _mask_timer != null and not _mask_timer.is_stopped():
		landscape_ready = false
		return
	if not force_snap and JSON.stringify(_forest_parameters()) == _forest_signature:
		return
	landscape_ready = false
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
	_city_layout = CityLayout.prepare(artifact(), city_marker_coordinate, values,
		reconstruction["water_mask"], _terrain.data, _reference_inputs["document"])
	_city_warning = str(_city_layout.get("message", ""))
	var city_preview := CityPreview.build(_city_layout, artifact(), _terrain.data, city_preview_scene)
	if is_instance_valid(_city_preview_root):
		remove_child(_city_preview_root)
		_city_preview_root.queue_free()
	_city_preview_root = city_preview["root"]
	add_child(_city_preview_root)
	if not str(city_preview["warning"]).is_empty():
		_city_warning = city_preview["warning"]
	var result: Dictionary
	if _forest_candidates.is_empty():
		var empty := Node3D.new()
		empty.name = "ReferenceForest"
		result = {"ok": true, "root": empty, "count": 0}
	else:
		result = ForestRenderer.new().build(_forest_candidates, _terrain.data, artifact().sample_spacing_meters, values, _city_layout)
	_forest_warning = ""
	if is_instance_valid(_forest_root):
		remove_child(_forest_root)
		_forest_root.queue_free()
	_forest_root = null
	tree_count = 0
	if result["ok"]:
		_forest_root = result["root"]
		add_child(_forest_root)
		tree_count = int(result["count"])
	else:
		_forest_warning = str(result["message"])
		push_warning(_forest_warning)
	landscape_ready = _surface_material != null and _forest_warning.is_empty()
	_apply_visibility()
	_update_landscape_status()
	preview_state_changed.emit()

func _update_landscape_status() -> void:
	landscape_status = "PBR landscape | Tree3D: %d | shoreline water" % tree_count
	if not _material_warning.is_empty():
		landscape_status = _material_warning
	if not _forest_warning.is_empty():
		landscape_status += "\n" + _forest_warning
	if not _city_warning.is_empty():
		landscape_status += "\nCity preview: " + _city_warning
	var scale_values := _forest_parameters()
	if artifact() != null and scale_values["city_scale_enabled"] >= 0.5:
		landscape_status += "\nCity hex: %.0f model m | trees %.2f map m" % [scale_values["city_hex_diameter"], scale_values["tree_height"]]
	if _surface_plan != null:
		var stats: Dictionary = _surface_plan.get("forest_statistics")
		if bool(stats.get("budget_limited", false)):
			landscape_status += " | forest budget active"
	var help := get_node_or_null("PreviewHUD/Help") as Label
	if help != null:
		help.text = source_map_id.to_upper() + " | 1: reference  2: landscape  R: compare  G: grid\n" + landscape_status
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super._get_configuration_warnings()
	for message in [_material_warning, _forest_warning, _city_warning]:
		if not message.is_empty():
			warnings.append(message)
	return warnings

func _validate_presentation_inputs(inputs: Dictionary) -> String:
	if forest_guide == null:
		return ""
	var image := forest_guide.get_image()
	var reference: Image = inputs["image"]
	if image == null or reference == null or image.get_size() != reference.get_size():
		return "Forest guide dimensions must match the reference atlas; the current terrain was not replaced."
	return ""

func _update_surface_normals() -> void:
	if _reference != null and artifact() != null:
		MeshNormals.update(_reference.mesh, artifact().width, artifact().height)

func city_site_layout() -> Dictionary:
	return _city_layout.duplicate(true)

func set_city_marker_coordinate(value: Vector2i) -> void:
	super.set_city_marker_coordinate(value)
	_queue_forest(true)

func set_city_marker_visible(value: bool) -> void:
	super.set_city_marker_visible(value)
	_apply_visibility()
