@tool
extends "res://editor/map_authoring/presentation/terrain_authoring_surface.gd"
## Owns one native authoring session. The dock and scene use this same API.

const Inputs := preload("res://editor/map_authoring/infrastructure/terrain/reference_terrain_inputs.gd")
const Parameters := preload("res://editor/map_authoring/application/reference_terrain_parameters.gd")
const Store := preload("res://editor/map_authoring/infrastructure/terrain/terrain_authoring_store.gd")
const Session := preload("res://editor/map_authoring/application/reference_terrain_session.gd")
const Builder := preload("res://editor/map_authoring/infrastructure/terrain/reference_terrain_builder.gd")
const ReliefShader := preload("res://editor/map_authoring/presentation/reference_relief.gdshader")
const PreviewCamera := preload("res://editor/map_authoring/presentation/reference_preview_camera.gd")

signal preview_state_changed

@export_dir var map_bundle_root := "res://assets/maps"
## Applied options only. Pending geometry never masquerades as the saved recipe.
@export_storage var terrain_parameters: Dictionary = {}
@export_dir var workspace_root := "res://assets/generated_maps"
@export var frame_on_open := true
@export var water_guide: Texture2D
@export var ridge_guide: Texture2D
## Kept as migration inputs for scenes saved by the first Dravonia implementation.
@export_storage var relief_seed := 73129
@export_storage var mountain_height_scale := 1.65
@export_storage var reference_influence := 0.9
@export_storage var relief_lighting := 0.85
@export_tool_button("Rebuild pending terrain", "Terrain3D") var rebuild_button: Callable = rebuild_from_inspector
@export_tool_button("Save terrain draft and water mask", "Save") var draft_button: Callable = save_reconstruction_draft

var preview_error := ""
var preview_ready := false
var reconstruction: Dictionary = {}
var _pending_parameters: Dictionary = {}
var _relief_material: ShaderMaterial
var _opening := false
var _has_reference := false
var _source_maximum := 18.5
var _opened_map_id := ""

func _ready() -> void:
	super._ready()
	set_process_unhandled_key_input(not Engine.is_editor_hint())
	var hud := get_node_or_null("PreviewHUD") as CanvasLayer
	if hud != null:
		hud.visible = not Engine.is_editor_hint()
	_open_preview.call_deferred()

func _exit_tree() -> void:
	if _session != null and _session.has_method("close"):
		_session.call("close")

func _open_preview() -> void:
	var result := await ensure_reference_session()
	if not is_instance_valid(self):
		return
	if not result["ok"]:
		push_error(str(result["message"]))
		var help := get_node_or_null("PreviewHUD/Help") as Label
		if help != null:
			help.text = str(result["message"])

func ensure_reference_session() -> Dictionary:
	while _opening:
		await get_tree().process_frame
		if not is_instance_valid(self):
			return {"ok": false, "message": "Authoring scene was closed"}
	if preview_ready:
		return {"ok": true}
	for _frame in 8:
		if terrain().data != null:
			return rebuild_reference()
		await get_tree().process_frame
		if not is_instance_valid(self):
			return {"ok": false, "message": "Authoring scene was closed"}
	return _report_failure("Terrain3D data is unavailable; check the native extension.")

func parameter_values() -> Dictionary:
	var values := Parameters.normalized(terrain_parameters, _source_maximum)
	if terrain_parameters.is_empty():
		values.merge({"seed": float(relief_seed), "mountain_scale": mountain_height_scale,
			"reference_strength": reference_influence, "relief_lighting": relief_lighting}, true)
	values.merge(_pending_parameters, true)
	return values

func has_pending_geometry() -> bool:
	return not _pending_parameters.is_empty()

func set_parameter_change(change: Dictionary) -> void:
	var key := str(change.get("key", ""))
	var value: Variant = change.get("value")
	var error := Parameters.validate({key: value})
	if not error.is_empty():
		_report_failure(error)
		return
	var descriptor := Parameters.descriptor(key)
	if descriptor[6] == "terrain":
		if is_equal_approx(float(value), float(Parameters.normalized(terrain_parameters, _source_maximum)[key])):
			_pending_parameters.erase(key)
		else:
			_pending_parameters[key] = float(value)
	else:
		if terrain_parameters.is_empty():
			terrain_parameters = Parameters.normalized({}, _source_maximum)
		terrain_parameters[key] = float(value)
		_apply_presentation(descriptor[6] == "camera")
	preview_state_changed.emit()

func discard_pending_parameters() -> void:
	_pending_parameters.clear()
	preview_state_changed.emit()

func rebuild_reference() -> Dictionary:
	if _opening:
		return {"ok": false, "message": "Terrain reconstruction is already running"}
	if not _safe_map_id(source_map_id) or (preview_ready and source_map_id != _opened_map_id):
		return _report_failure("Open a separate map scene rather than changing a live session's map ID.")
	if terrain().data == null:
		return _report_failure("Terrain3D data is not ready")
	_opening = true
	preview_state_changed.emit()
	var inputs := Inputs.new().load_inputs(source_map_id, map_bundle_root)
	if not inputs["ok"]:
		return _report_failure(str(inputs["message"]))
	var source: AonwTerrainCompiledArtifact = inputs["artifact"]
	_source_maximum = source.max_terrain_height_meters
	var options := parameter_values()
	var error := Parameters.validate(options)
	if not error.is_empty():
		return _report_failure(error)
	var guides := _guides()
	if not guides["ok"]:
		return _report_failure(str(guides["message"]))
	var next := Builder.new().build_reference(source, inputs["image"], inputs["document"],
		73129, 1.65, 1.0, guides["images"], options, inputs["has_reference"])
	if not next["ok"]:
		return _report_failure(str(next["message"]))
	if preview_ready and reconstruction["workspace_key"] == next["workspace_key"]:
		terrain_parameters = options
		_pending_parameters.clear()
		_opening = false
		preview_error = ""
		preview_state_changed.emit()
		return {"ok": true, "unchanged": true}
	var natural: AonwTerrainCompiledArtifact = next["artifact"]
	var next_root := workspace_root.path_join(source_map_id).path_join("reference_terrain/" + str(next["workspace_key"]))
	var persistence := Store.new(next_root)
	var preflight := persistence.load_revision(natural.identity())
	if not preflight["ok"]:
		return _report_failure(str(preflight["message"]))
	# Complete computation and target validation before saving/detaching the old draft.
	var old_session := _session
	var old_artifact := _artifact
	var old_texture := _reference_texture
	var old_reader := _artifact_reader
	if old_session != null:
		var saved := save_draft()
		if not saved["ok"]:
			return _report_failure("Previous draft could not be saved; terrain was not replaced: " + str(saved["message"]))
		old_session.terrain_changed.disconnect(_on_terrain_changed)
		old_session.call("close")
	_session = null
	var display_texture: Texture2D = inputs["texture"]
	if display_texture == null:
		display_texture = ImageTexture.create_from_image(next["biome_image"])
	var session := Session.new(terrain().data, natural, persistence)
	var opened := super.open_session(session, natural, display_texture, inputs["reader"])
	if not opened["ok"]:
		session.close()
		_session = null
		if old_session != null:
			var restored := super.open_session(old_session, old_artifact, old_texture, old_reader)
			if not restored["ok"]:
				preview_ready = false
				return _report_failure("New session failed and restoration failed; the previous draft remains on disk.")
		return _report_failure(str(opened["message"]))
	authoring_root = next_root
	compiled_artifact_directory = source.directory
	reconstruction = next
	terrain_parameters = options
	_pending_parameters.clear()
	_has_reference = inputs["has_reference"]
	_opened_map_id = source_map_id
	_relief_material = ShaderMaterial.new()
	_relief_material.shader = ReliefShader
	_relief_material.set_shader_parameter("reference_texture", display_texture)
	_relief_material.set_shader_parameter("biome_texture", ImageTexture.create_from_image(next["biome_image"]))
	_relief_material.set_shader_parameter("raster_extent", Vector2(natural.width - 1, natural.height - 1) * natural.sample_spacing_meters)
	preview_ready = true
	_opening = false
	preview_error = ""
	refresh_overlays()
	_apply_presentation()
	if frame_on_open:
		_frame_camera(false)
	var help := get_node_or_null("PreviewHUD/Help") as Label
	if help != null:
		help.text = source_map_id.to_upper() + " | 1: reference top  2: strategic  R: reference/material  G: grid\nRight drag: orbit  Middle/Shift-right: pan  Wheel: dolly"
	if not str(inputs["warning"]).is_empty():
		push_warning(inputs["warning"])
	preview_state_changed.emit()
	update_configuration_warnings()
	return {"ok": true, "workspace": authoring_root, "warning": inputs["warning"]}

func _guides() -> Dictionary:
	var images := {}
	for pair in [["water", water_guide], ["ridges", ridge_guide]]:
		var texture: Texture2D = pair[1]
		if texture == null:
			continue
		var image := texture.get_image()
		if image == null or (image.is_compressed() and image.decompress() != OK):
			return {"ok": false, "message": "Cannot decode " + str(pair[0]) + " guide"}
		images[pair[0]] = image
	return {"ok": true, "images": images}

func open_session(
	session: AonwTerrainAuthoringSession, artifact_value: AonwTerrainCompiledArtifact,
	reference_texture: Texture2D, artifact_reader: AonwTerrainCompiledArtifactReader,
) -> Dictionary:
	if artifact_value == null or artifact_value.generator_version != Builder.REFERENCE_VERSION:
		return {"ok": false, "message": "Use ensure_reference_session for reference reconstruction."}
	return super.open_session(session, artifact_value, reference_texture, artifact_reader)

func has_reference_texture() -> bool:
	return _has_reference

func refresh_overlays() -> void:
	super.refresh_overlays()
	if _reference != null and _relief_material != null:
		_reference.material_override = _relief_material
		_reference.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_apply_visibility()

func _apply_visibility() -> void:
	super._apply_visibility()
	# One opaque draped material blends between the reference and semantic ground.
	if _reference != null and _relief_material != null:
		_reference.visible = true
		_relief_material.set_shader_parameter("reference_visible", reference_visible and _has_reference)

func _update_opacity(layer: MeshInstance3D, value: float) -> void:
	super._update_opacity(layer, value)
	if _relief_material != null and layer != null and layer.name == &"ReferenceTexture":
		_relief_material.set_shader_parameter("reference_opacity", value)
	preview_state_changed.emit()

func _apply_presentation(update_camera: bool = true) -> void:
	var p := parameter_values()
	if _relief_material != null:
		for key in ["relief_lighting", "rock_slope"]:
			_relief_material.set_shader_parameter(key, p[key])
		_relief_material.set_shader_parameter("reference_opacity", reference_opacity)
		_relief_material.set_shader_parameter("reference_visible", reference_visible and _has_reference)
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		sun.rotation_degrees = Vector3(-float(p["sun_elevation"]), float(p["sun_heading"]), 0.0)
		sun.light_energy = p["sun_energy"]
	var environment := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if environment != null and environment.environment != null:
		environment.environment.ambient_light_energy = p["ambient_energy"]
	var camera := get_node_or_null("PreviewCamera") as PreviewCamera
	if camera != null and update_camera:
		camera.configure_view(p["camera_pitch"], p["camera_yaw"], p["camera_zoom"], p["camera_fov"])

func save_draft() -> Dictionary:
	if not preview_ready:
		return {"ok": false, "message": "Reference terrain is not ready"}
	var saved := super.save_draft()
	if not saved["ok"]:
		return saved
	var mask: Image = reconstruction["water_mask"]
	var error := mask.save_png(authoring_root.path_join("water_mask.png"))
	if error != OK:
		return {"ok": false, "message": "Terrain saved, but water-mask export failed: " + error_string(error)}
	var file := FileAccess.open(authoring_root.path_join("reference_recipe.json"), FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Terrain saved, but recipe export failed"}
	file.store_string(JSON.stringify(reconstruction["recipe"], "\t") + "\n")
	file.flush()
	if file.get_error() != OK:
		return {"ok": false, "message": "Terrain saved, but recipe write failed"}
	return saved

func refresh_generated_artifact() -> Dictionary:
	return rebuild_reference()

func rescale_generated_artifact() -> Dictionary:
	return {"ok": false, "message": "Set the presentation height and rebuild; canonical rescale is not used here."}

func refresh_logical_map_artifact() -> Dictionary:
	return {"ok": false, "message": "Recompile JSON inputs and update the atlas identity before rebuilding reference terrain."}

func publish() -> Dictionary:
	return {"ok": false, "message": "Reference drafts are not runtime terrain contracts. Save draft instead."}

func rebuild_from_inspector() -> void:
	var result := rebuild_reference()
	if not result["ok"]:
		push_error(result["message"])

func save_reconstruction_draft() -> void:
	var result := save_draft()
	if not result["ok"]:
		push_error(result["message"])

func show_top_view() -> void:
	set_parameter_change({"key": "relief_lighting", "value": 0.0})
	set_reference_visible(true)
	set_reference_opacity(1.0)
	_frame_camera(true)

func show_oblique_view() -> void:
	set_parameter_change({"key": "relief_lighting", "value": 0.85})
	_apply_presentation()
	_frame_camera(false)

func toggle_reference() -> void:
	set_reference_visible(not reference_visible)
	preview_state_changed.emit()

func toggle_grid() -> void:
	set_grid_visible(not grid_visible)
	preview_state_changed.emit()

func _frame_camera(top_down: bool) -> void:
	var camera := get_node_or_null("PreviewCamera") as PreviewCamera
	if camera != null and artifact() != null:
		var value := artifact()
		camera.frame_terrain(Vector2(value.width - 1, value.height - 1) * value.sample_spacing_meters,
			value.max_terrain_height_meters, top_down)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: show_top_view()
		KEY_2: show_oblique_view()
		KEY_R: toggle_reference()
		KEY_G: toggle_grid()
		_: return
	get_viewport().set_input_as_handled()

func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray([preview_error]) if not preview_error.is_empty() else PackedStringArray()

func _report_failure(message: String) -> Dictionary:
	_opening = false
	preview_error = message
	preview_state_changed.emit()
	update_configuration_warnings()
	return {"ok": false, "message": message}

func _safe_map_id(value: String) -> bool:
	if value.is_empty():
		return false
	for character in value:
		if character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-":
			return false
	return true

func record_camera_navigation() -> void:
	var camera := get_node_or_null("PreviewCamera") as PreviewCamera
	if camera == null:
		return
	terrain_parameters.merge(camera.view_parameters(), true)
	preview_state_changed.emit()
	if Engine.is_editor_hint():
		EditorInterface.mark_scene_as_unsaved()

func set_reference_visible(value: bool) -> void:
	super.set_reference_visible(value)
	preview_state_changed.emit()

func set_grid_visible(value: bool) -> void:
	super.set_grid_visible(value)
	preview_state_changed.emit()

func set_constraints_visible(value: bool) -> void:
	super.set_constraints_visible(value)
	preview_state_changed.emit()

func set_city_marker_visible(value: bool) -> void:
	super.set_city_marker_visible(value)
	preview_state_changed.emit()

func set_city_marker_coordinate(value: Vector2i) -> void:
	super.set_city_marker_coordinate(value)
	preview_state_changed.emit()
