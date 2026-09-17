@tool
extends "res://editor/map_authoring/presentation/map_reference_preview.gd"
## Derived presentation, sharing one reference transform, native heightfield and water mask.
const SurfacePlan := preload("res://editor/map_authoring/infrastructure/terrain/reference_surface_plan.gd")
const SurfaceMaterial := preload("res://editor/map_authoring/presentation/reference_surface_material.gd")
const ForestRenderer := preload("res://editor/map_authoring/presentation/reference_forest.gd")
const MeshNormals := preload("res://editor/map_authoring/presentation/reference_mesh_normals.gd")
const WaterSurface := preload("res://editor/map_authoring/presentation/reference_water_surface.gd")

const ReferenceOverlay := preload("res://editor/map_authoring/presentation/reference_overlay_mesh_builder.gd")
const EditorQuality := preload("res://editor/map_authoring/presentation/editor_landscape_quality.gd")

## Editor-only draw settings. Play and captures always use the complete forest.
@export var editor_fast_preview := true:
	set(value):
		editor_fast_preview = value
		if is_node_ready():
			_apply_editor_quality()
@export_range(1000, 20000, 1000) var editor_tree_budget := 6000:
	set(value):
		editor_tree_budget = clampi(value, 1000, 20000)
		if is_node_ready():
			_apply_editor_quality()
var editor_visible_tree_count := 0
var _forest_renderer := ForestRenderer.new()
var _candidate_signature := ""
var _ground_reset := true
var _ground_changes := Rect2i()
var _draw_distance := -1.0
var forest_generation_count := 0

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
	_overlay_builder = ReferenceOverlay.new()
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
	# The base rebuild already refreshed the height mesh and normals. Do not
	# reconstruct the same raster/grid a second time just to change materials.
	_refresh_materials()
	_update_landscape_status()
	result["warning"] = _material_warning
	return result

func _refresh_materials() -> void:
	var values := parameter_values()
	values["seed"] = Parameters.normalized(terrain_parameters, _source_maximum)["seed"]
	_masks = _surface_plan.call("surface_masks", values)
	_mask_signature = _mask_key()
	_forest_signature = ""
	_candidate_signature = ""
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
		EditorQuality.apply_water(_water_surface, Engine.is_editor_hint() and editor_fast_preview)
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
	_apply_forest_distance(float(values["tree_draw_distance"]))
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
	_ground_reset = true
	_queue_forest(true)

func _refresh_overlays_deferred() -> void:
	var changed := _pending_changed_pixels
	super._refresh_overlays_deferred()
	if not changed.has_area():
		return
	# Accumulate brush strokes, but only resample affected tree roots after debounce.
	_ground_changes = _ground_changes.merge(changed) if _ground_changes.has_area() else changed
	var normal_area := changed if artifact().reference_transform().is_equal_approx(Transform3D.IDENTITY) else Rect2i()
	_update_surface_normals(normal_area)
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
	if not force_snap and _forest_key(_forest_parameters()) == _forest_signature:
		return
	landscape_ready = false
	if _forest_timer == null:
		_forest_timer = Timer.new()
		_forest_timer.one_shot = true
		_forest_timer.wait_time = 0.25
		add_child(_forest_timer)
		_forest_timer.timeout.connect(_rebuild_forest)
	_forest_timer.start(0.65 if Engine.is_editor_hint() else 0.25)

func _rebuild_forest() -> void:
	if _surface_plan == null or not preview_ready:
		return
	var values := _forest_parameters()
	var candidate_key := _candidate_key(values)
	if candidate_key != _candidate_signature:
		_forest_candidates = _surface_plan.call("forest_candidates", values)
		_candidate_signature = candidate_key
		_ground_reset = true
		forest_generation_count += 1
	_forest_signature = _forest_key(values)
	if _ground_reset:
		_forest_renderer.clear_ground_cache()
	else:
		_forest_renderer.invalidate_ground(_ground_changes, artifact().sample_spacing_meters)
	_ground_reset = false
	_ground_changes = Rect2i()
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
		result = _forest_renderer.build(_forest_candidates, _terrain.data, artifact().sample_spacing_meters, values, _city_layout)
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
	editor_visible_tree_count = EditorQuality.apply_forest(_forest_root, Engine.is_editor_hint() and editor_fast_preview, editor_tree_budget)
	landscape_ready = _surface_material != null and _forest_warning.is_empty()
	_apply_visibility()
	_update_landscape_status()
	preview_state_changed.emit()

func _update_landscape_status() -> void:
	landscape_status = "PBR landscape | Tree3D: %d | shoreline water" % tree_count
	if Engine.is_editor_hint() and editor_fast_preview:
		landscape_status += " | editor: %d visible, full forest in Play" % editor_visible_tree_count
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

func _update_surface_normals(changed: Rect2i = Rect2i()) -> void:
	if _reference != null and artifact() != null:
		MeshNormals.update(_reference.mesh, artifact().width, artifact().height, changed)

func city_site_layout() -> Dictionary:
	return _city_layout.duplicate(true)

func set_city_marker_coordinate(value: Vector2i) -> void:
	super.set_city_marker_coordinate(value)
	_queue_forest(true)

func set_city_marker_visible(value: bool) -> void:
	super.set_city_marker_visible(value)
	_apply_visibility()

func set_editor_fast_preview(value: bool) -> void:
	editor_fast_preview = value

func _apply_editor_quality() -> void:
	var responsive := Engine.is_editor_hint() and editor_fast_preview
	editor_visible_tree_count = EditorQuality.apply_forest(_forest_root, responsive, editor_tree_budget)
	EditorQuality.apply_water(_water_surface, responsive)
	if preview_ready:
		_update_landscape_status()
	preview_state_changed.emit()

func _apply_forest_distance(value: float) -> void:
	if is_equal_approx(value, _draw_distance):
		return
	_draw_distance = value
	if not is_instance_valid(_forest_root):
		return
	for batch in _forest_root.get_children():
		if batch is MultiMeshInstance3D:
			batch.visibility_range_end = value

static func _forest_key(values: Dictionary) -> String:
	var key := values.duplicate()
	key.erase("tree_draw_distance") # GPU visibility change, not a placement change.
	return JSON.stringify(key)

static func _candidate_key(values: Dictionary) -> String:
	var key := {}
	for name in ["seed", "tree_density", "tree_spacing", "tree_height",
		"tree_reference_strength", "tree_conifer_share", "forest_tree_budget"]:
		key[name] = values[name]
	# Biome/patch changes invalidate this key in _refresh_materials(). City and
	# slope filters run later, so neither needs a new global candidate stream.
	return JSON.stringify(key)
