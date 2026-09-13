@tool
extends "res://editor/map_authoring/presentation/terrain_authoring_surface.gd"
## All-map Terrain3D authoring. Never modifies a canonical map or an old draft.

const ArtifactRepository := preload("res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd")
const AtlasRepository := preload("res://game/infrastructure/map/tile_atlas_repository.gd")
const MapIdentity := preload("res://game/application/map/read_model/map_view.gd")
const Store := preload("res://editor/map_authoring/infrastructure/terrain/terrain_authoring_store.gd")
const Session := preload("res://editor/map_authoring/application/terrain_authoring_session.gd")
const Builder := preload("res://editor/map_authoring/infrastructure/terrain/reference_terrain_builder.gd")
const ReliefShader := preload("res://editor/map_authoring/presentation/reference_relief.gdshader")
const PreviewCamera := preload("res://editor/map_authoring/presentation/reference_preview_camera.gd")

@export_group("Reference reconstruction - save and reopen to apply")
@export_dir var map_bundle_root := "res://assets/maps"
@export var relief_seed := 73129
@export_range(0.5, 3.0, 0.05) var mountain_height_scale := 1.65
@export_range(0.0, 1.0, 0.05) var reference_influence := 1.0
## Optional atlas-sized, lossless guides: white is water / ridge, black is land / valley.
@export var water_guide: Texture2D
@export var ridge_guide: Texture2D
@export_group("Reference preview")
@export_range(0.0, 1.0, 0.01) var relief_lighting := 0.65:
	set(value):
		relief_lighting = clampf(value, 0.0, 1.0)
		if _relief_material != null:
			_relief_material.set_shader_parameter("relief_lighting", relief_lighting)
@export var frame_on_open := true
@export_tool_button("Top view / original colours", "Camera3D") var top_view: Callable = show_top_view
@export_tool_button("Oblique / shaded relief", "Camera3D") var oblique_view: Callable = show_oblique_view
@export_tool_button("Toggle reference / clay", "Terrain3D") var reference_toggle: Callable = toggle_reference
@export_tool_button("Toggle hex grid", "Grid") var grid_toggle: Callable = toggle_grid
@export_tool_button("Save terrain draft and water mask", "Save") var draft_save: Callable = save_reconstruction_draft

var preview_error := ""
var preview_ready := false
var reconstruction: Dictionary = {}
var _relief_material: ShaderMaterial
var _data_wait_frames := 0
var _opening := false
var _opened_map_id := ""

func _ready() -> void:
	super._ready()
	set_process_unhandled_key_input(not Engine.is_editor_hint())
	var hud := get_node_or_null("PreviewHUD") as CanvasLayer
	if hud != null:
		hud.visible = not Engine.is_editor_hint()
	_open_preview.call_deferred()

func _open_preview() -> void:
	if not is_inside_tree() or preview_ready or _opening or not preview_error.is_empty():
		return
	if not _safe_map_id(source_map_id):
		_preview_failed("Select a map ID containing only letters, digits, underscores or hyphens.")
		return
	var native_terrain := terrain()
	if native_terrain.data == null:
		_data_wait_frames += 1
		if _data_wait_frames > 8:
			_preview_failed("Terrain3D data is unavailable. Check the native extension.")
			return
		get_tree().process_frame.connect(_open_preview, CONNECT_ONE_SHOT)
		return
	_opening = true
	_opened_map_id = source_map_id
	var bundle := map_bundle_root.path_join(source_map_id)
	var document_file := FileAccess.open(bundle.path_join("map.json"), FileAccess.READ)
	if document_file == null:
		_preview_failed("Cannot read map bundle: " + bundle)
		return
	var document: Variant = JSON.parse_string(document_file.get_as_text())
	if document is not Dictionary:
		_preview_failed("Map bundle contains invalid map.json")
		return
	# Prefer freshly compiled authoring data. A broken cache is reported, not
	# silently replaced by older packaged terrain belonging to another revision.
	var cached := "res://.godot/terrain_compiled".path_join(source_map_id)
	compiled_artifact_directory = (
		cached if FileAccess.file_exists(cached.path_join("terrain_compile.json"))
		else "res://assets/terrain_compiled".path_join(source_map_id)
	)
	var reader := ArtifactRepository.new()
	var compiled := reader.load_artifact(compiled_artifact_directory, source_map_id)
	if not compiled["ok"]:
		_preview_failed(str(compiled["message"]))
		return
	var source: AonwTerrainCompiledArtifact = compiled["artifact"]
	var objectives: Array[AonwMapObjectiveView] = []
	var tiles: Array[AonwMapTileView] = []
	var identity := MapIdentity.new(
		StringName(source_map_id), source.map_content_hash, &"oddQFlatTop",
		source.cols, source.rows, 1.0, objectives, tiles,
	)
	var atlas := AtlasRepository.new().load_atlas(identity, bundle)
	if not atlas["ok"]:
		_preview_failed(str(atlas["message"]))
		return
	var texture: Texture2D = atlas["reference_texture"]
	var overrides := {}
	for pair in [["water", water_guide], ["ridges", ridge_guide]]:
		var guide_texture: Texture2D = pair[1]
		if guide_texture == null:
			continue
		var guide := guide_texture.get_image()
		if guide == null or (guide.is_compressed() and guide.decompress() != OK):
			_preview_failed("Cannot decode " + str(pair[0]) + " guide")
			return
		overrides[pair[0]] = guide
	reconstruction = Builder.new().build_reference(
		source, texture.get_image(), document, relief_seed,
		mountain_height_scale, reference_influence, overrides,
	)
	if not reconstruction["ok"]:
		_preview_failed(str(reconstruction["message"]))
		return
	var natural: AonwTerrainCompiledArtifact = reconstruction["artifact"]
	authoring_root = "res://assets/generated_maps".path_join(source_map_id).path_join(
		"reference_terrain/" + str(reconstruction["workspace_key"])
	)
	_relief_material = ShaderMaterial.new()
	_relief_material.shader = ReliefShader
	_relief_material.set_shader_parameter("reference_texture", texture)
	_relief_material.set_shader_parameter("relief_lighting", relief_lighting)
	_relief_material.set_shader_parameter("reference_opacity", reference_opacity)
	var session := Session.new(native_terrain.data, natural, Store.new(authoring_root))
	var opened := open_session(session, natural, texture, reader)
	if not opened["ok"]:
		_preview_failed(str(opened["message"]))
		return
	preview_ready = true
	_opening = false
	if frame_on_open:
		_frame_camera(false)
	var help := get_node_or_null("PreviewHUD/Help") as Label
	if help != null:
		help.text = source_map_id.to_upper() + " | Reference terrain\n" + (
			"1: top   2: oblique   R: reference/clay   G: grid   L: lighting\n"
			+ "Right drag: orbit   Middle / Shift-right: pan   Wheel: zoom"
		)
	print("%s reference terrain: %d changed, %d water, %d ambiguous water samples; %s" % [
		source_map_id, reconstruction["changed_samples"], reconstruction["water_samples"],
		reconstruction["ambiguous_water_samples"], authoring_root,
	])
	update_configuration_warnings()

func open_session(
	session: AonwTerrainAuthoringSession, artifact_value: AonwTerrainCompiledArtifact,
	reference_texture: Texture2D, artifact_reader: AonwTerrainCompiledArtifactReader,
) -> Dictionary:
	if artifact_value == null or artifact_value.generator_version != Builder.REFERENCE_VERSION:
		return {"ok": false, "message": "This surface opens its own reference-terrain session."}
	return super.open_session(session, artifact_value, reference_texture, artifact_reader)

func refresh_overlays() -> void:
	super.refresh_overlays()
	var reference := get_node_or_null("ReferenceTexture") as MeshInstance3D
	if reference != null and _relief_material != null:
		reference.material_override = _relief_material
		reference.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _update_opacity(layer: MeshInstance3D, value: float) -> void:
	super._update_opacity(layer, value)
	if _relief_material != null and layer != null and layer.name == &"ReferenceTexture":
		_relief_material.set_shader_parameter("reference_opacity", value)

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
	var recipe_file := FileAccess.open(authoring_root.path_join("reference_recipe.json"), FileAccess.WRITE)
	if recipe_file == null:
		return {"ok": false, "message": "Terrain saved, but reference-recipe export failed"}
	recipe_file.store_string(JSON.stringify(reconstruction["recipe"], "\t") + "\n")
	if recipe_file.get_error() != OK:
		return {"ok": false, "message": "Terrain saved, but reference-recipe write failed"}
	return saved

func refresh_generated_artifact() -> Dictionary:
	return _reopen_message()

func rescale_generated_artifact() -> Dictionary:
	return _reopen_message()

func refresh_logical_map_artifact() -> Dictionary:
	return _reopen_message()

func publish() -> Dictionary:
	return {"ok": false, "message": "Save this presentation draft; runtime publishing still uses canonical terrain contracts."}

func _reopen_message() -> Dictionary:
	return {"ok": false, "message": "Save the draft and reopen the scene to reconstruct updated sources without flattening relief."}

func show_top_view() -> void:
	relief_lighting = 0.0
	set_reference_visible(true)
	set_reference_opacity(1.0)
	_frame_camera(true)

func show_oblique_view() -> void:
	relief_lighting = 0.65
	set_reference_visible(true)
	_frame_camera(false)

func toggle_reference() -> void:
	set_reference_visible(not reference_visible)

func toggle_grid() -> void:
	set_grid_visible(not grid_visible)

func save_reconstruction_draft() -> void:
	var result := save_draft()
	if not result["ok"]:
		push_error(str(result["message"]))
	else:
		print("Reference terrain draft and water mask saved: " + authoring_root)

func _frame_camera(top_down: bool) -> void:
	var camera := get_node_or_null("PreviewCamera") as PreviewCamera
	if camera == null or artifact() == null:
		return
	var value := artifact()
	camera.frame_terrain(
		Vector2(value.width - 1, value.height - 1) * value.sample_spacing_meters,
		value.max_terrain_height_meters, top_down,
	)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: show_top_view()
		KEY_2: show_oblique_view()
		KEY_R: toggle_reference()
		KEY_G: toggle_grid()
		KEY_L: relief_lighting = 0.65 if is_zero_approx(relief_lighting) else 0.0
		_: return
	get_viewport().set_input_as_handled()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not preview_error.is_empty():
		warnings.append(preview_error)
	if preview_ready and source_map_id != _opened_map_id:
		warnings.append("Save and reopen the scene after changing the map ID.")
	return warnings

func _preview_failed(message: String) -> void:
	_opening = false
	preview_error = "Reference terrain (%s): %s" % [source_map_id, message]
	push_error(preview_error)
	update_configuration_warnings()

func _safe_map_id(value: String) -> bool:
	if value.is_empty():
		return false
	for character in value:
		if character not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-":
			return false
	return true
