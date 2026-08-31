@tool
class_name AonwTerrainAuthoringSurface
extends Node3D

const OverlayBuilder := preload(
	"res://game/presentation/map/terrain_overlay_mesh_builder.gd"
)
const HexGridGeometry := preload(
	"res://game/presentation/map/geometry/hex_grid_geometry.gd"
)
const TerrainSpaceTransform := preload(
	"res://game/application/terrain/terrain_space_transform.gd"
)
const GeneratedWorldBuilder := preload(
	"res://editor/map_authoring/presentation/generated_world_builder.gd"
)

const INVALID_HEX := Vector2i(-1, -1)

@export var source_map_id := ""
@export_dir var compiled_artifact_directory := ""
@export_dir var authoring_root := ""
@export var map_content_hash := ""
@export var authoring_profile_hash := ""
@export var generated_base_hash := ""
@export var generator_version := ""
@export var terrain_revision := 0
@export var reference_visible := true
@export_range(0.0, 1.0, 0.01) var reference_opacity := 0.65
@export var grid_visible := true
@export_range(0.0, 1.0, 0.01) var grid_opacity := 0.72
@export_range(0.01, 2.0, 0.01) var grid_width := 0.35
@export var constraints_visible := false
@export var city_marker_visible := true
@export var city_marker_coordinate := Vector2i(-1, -1)
@export var terrain_material: Terrain3DMaterial
@export var terrain_assets: Terrain3DAssets

var _overlay_builder := OverlayBuilder.new()
var _generated_world_builder := GeneratedWorldBuilder.new()
var _artifact_reader: AonwTerrainCompiledArtifactReader
var _artifact: AonwTerrainCompiledArtifact
var _session: AonwTerrainAuthoringSession
var _terrain: Terrain3D
var _reference: MeshInstance3D
var _grid: MeshInstance3D
var _minimum_debug: MeshInstance3D
var _maximum_debug: MeshInstance3D
var _city_marker: MeshInstance3D
var _logical_cursor: MeshInstance3D
var _generated_world: Node3D
var _manual_world: Node3D
var _reference_texture: Texture2D
var _overlay_refresh_queued := false
var _pending_changed_pixels := Rect2i()
var _logical_geometry: AonwHexGridGeometry
var _logical_space: AonwTerrainSpaceTransform
var _logical_cursor_coordinate := INVALID_HEX
var _logical_paint_active := false
var _generated_placements: Array = []

func _ready() -> void:
	_ensure_nodes()

func configure(
	map_id: String,
	artifact_directory: String,
	session_root: String,
) -> void:
	source_map_id = map_id
	compiled_artifact_directory = artifact_directory
	authoring_root = session_root
	_ensure_nodes()

func terrain() -> Terrain3D:
	_ensure_nodes()
	return _terrain

func artifact() -> AonwTerrainCompiledArtifact:
	return _artifact

func generated_world() -> Node3D:
	_ensure_nodes()
	return _generated_world

func manual_world() -> Node3D:
	_ensure_nodes()
	return _manual_world

func present_generated_decorations(placements: Array) -> void:
	_generated_placements = placements.duplicate(true)
	_refresh_generated_world()

func clear_generated_decorations() -> void:
	_generated_placements.clear()
	_refresh_generated_world()

func is_session_open() -> bool:
	return _session != null

func open_session(
	session: AonwTerrainAuthoringSession,
	artifact_value: AonwTerrainCompiledArtifact,
	reference_texture: Texture2D,
	artifact_reader: AonwTerrainCompiledArtifactReader,
) -> Dictionary:
	if _session != null:
		return {"ok": true}
	assert(session != null, "Terrain authoring session is required")
	assert(artifact_value != null, "Compiled terrain artifact is required")
	assert(artifact_reader != null, "Compiled terrain artifact reader is required")
	_ensure_nodes()
	_artifact = artifact_value
	_reference_texture = reference_texture
	_artifact_reader = artifact_reader
	_terrain.vertex_spacing = _artifact.sample_spacing_meters
	_session = session
	var open_result := _session.open()
	if not open_result["ok"]:
		_session = null
		return open_result
	if not _session.terrain_changed.is_connected(_on_terrain_changed):
		_session.terrain_changed.connect(_on_terrain_changed)
	if city_marker_coordinate.x < 0 or city_marker_coordinate.y < 0:
		city_marker_coordinate = Vector2i(_artifact.cols / 2, _artifact.rows / 2)
	_configure_logical_interaction()
	_sync_metadata()
	refresh_overlays()
	_refresh_generated_world()
	return {"ok": true}

func set_reference_visible(value: bool) -> void:
	reference_visible = value and _reference_texture != null
	_ensure_nodes()
	_reference.visible = value

func set_reference_opacity(value: float) -> void:
	reference_opacity = clampf(value, 0.0, 1.0)
	_update_opacity(_reference, reference_opacity)

func set_grid_visible(value: bool) -> void:
	grid_visible = value
	_ensure_nodes()
	_grid.visible = value

func set_grid_opacity(value: float) -> void:
	grid_opacity = clampf(value, 0.0, 1.0)
	_update_opacity(_grid, grid_opacity)

func set_constraints_visible(value: bool) -> void:
	constraints_visible = value
	_ensure_nodes()
	if value:
		_ensure_constraint_meshes()
	if _minimum_debug != null:
		_minimum_debug.visible = value
	if _maximum_debug != null:
		_maximum_debug.visible = value

func set_city_marker_visible(value: bool) -> void:
	city_marker_visible = value
	_ensure_nodes()
	_city_marker.visible = value

func set_city_marker_coordinate(value: Vector2i) -> void:
	city_marker_coordinate = value
	_refresh_city_marker()

func set_logical_paint_active(value: bool) -> void:
	_logical_paint_active = value
	_ensure_nodes()
	_logical_cursor.visible = value and _logical_cursor.mesh != null
	if not value:
		_logical_cursor_coordinate = INVALID_HEX
		_logical_cursor.mesh = null

func set_logical_paint_cursor(coordinate: Vector2i) -> void:
	_logical_cursor_coordinate = coordinate
	_refresh_logical_cursor()

func pick_logical_hex(camera: Camera3D, screen_position: Vector2) -> Vector2i:
	if (
		camera == null
		or _session == null
		or _logical_geometry == null
		or _logical_space == null
	):
		return INVALID_HEX
	var inverse := global_transform.affine_inverse()
	var local_origin := inverse * camera.project_ray_origin(screen_position)
	var local_direction := (
		inverse.basis * camera.project_ray_normal(screen_position)
	).normalized()
	if local_direction.is_zero_approx():
		return INVALID_HEX
	var intersection := _terrain.get_intersection(local_origin, local_direction, false)
	if not intersection.is_finite():
		return INVALID_HEX
	return logical_hex_at_local_position(intersection)

func logical_hex_at_local_position(local_position: Vector3) -> Vector2i:
	if _logical_geometry == null or _logical_space == null:
		return INVALID_HEX
	var coordinate := _logical_geometry.tile_at_point(
		_logical_space.terrain_local_to_logical(local_position)
	)
	return coordinate if _logical_geometry.contains(coordinate) else INVALID_HEX

func change_height(history: UndoRedo, pixel: Vector2i, requested_height: float) -> bool:
	if _session == null:
		return false
	return _session.change_height(history, pixel, requested_height)

func set_height(pixel: Vector2i, requested_height: float) -> float:
	assert(_session != null, "Terrain authoring session is not open")
	return _session.set_height(pixel, requested_height)

func height_at(pixel: Vector2i) -> float:
	assert(_session != null, "Terrain authoring session is not open")
	return _session.height_at(pixel)

func clamp_changed_region(changed_pixels: Rect2i) -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	return _session.clamp_changed_region(changed_pixels)

func validate_for_publish() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	return _session.validate_for_publish()

func save_draft() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	var result := _session.save_draft()
	_sync_metadata()
	return result

func publish() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	var result := _session.publish()
	_sync_metadata()
	return result

func refresh_generated_artifact() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	var artifact_result := _artifact_reader.load_artifact(
		compiled_artifact_directory,
		source_map_id,
	)
	if not artifact_result["ok"]:
		return artifact_result
	var result := _session.refresh_generated_artifact(artifact_result["artifact"])
	if not result["ok"]:
		return result
	_artifact = artifact_result["artifact"]
	_configure_logical_interaction()
	_sync_metadata()
	refresh_overlays()
	_refresh_generated_world()
	return result

func rescale_generated_artifact() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	var artifact_result := _artifact_reader.load_artifact(
		compiled_artifact_directory,
		source_map_id,
	)
	if not artifact_result["ok"]:
		return artifact_result
	var result := _session.rescale_generated_artifact(artifact_result["artifact"])
	if not result["ok"]:
		return result
	_artifact = artifact_result["artifact"]
	_configure_logical_interaction()
	_sync_metadata()
	refresh_overlays()
	_refresh_generated_world()
	return result

func migrate_logical_map_artifact() -> Dictionary:
	if _session == null:
		return _failure("terrain authoring session is not open")
	var artifact_result := _artifact_reader.load_artifact(
		compiled_artifact_directory,
		source_map_id,
	)
	if not artifact_result["ok"]:
		return artifact_result
	var result := _session.migrate_logical_map_artifact(artifact_result["artifact"])
	if not result["ok"]:
		return result
	_artifact = artifact_result["artifact"]
	_configure_logical_interaction()
	_sync_metadata()
	refresh_overlays()
	_refresh_generated_world()
	return result

func invalidate_reference_texture() -> void:
	_reference_texture = null
	reference_visible = false
	_ensure_nodes()
	_reference.mesh = null
	_reference.visible = false

func has_reference_texture() -> bool:
	return _reference_texture != null

func refresh_overlays() -> void:
	if _session == null or _artifact == null:
		return
	_reference.mesh = (
		_overlay_builder.reference_mesh(
			_artifact,
			_terrain.data,
			_reference_texture,
			reference_opacity,
		)
		if _reference_texture != null
		else null
	)
	_reference.transform = Transform3D.IDENTITY
	_grid.mesh = _overlay_builder.grid_mesh(
		_artifact,
		_terrain.data,
		grid_width,
		grid_opacity,
	)
	if _minimum_debug != null:
		_minimum_debug.mesh = null
	if _maximum_debug != null:
		_maximum_debug.mesh = null
	if constraints_visible:
		_ensure_constraint_meshes()
	_refresh_city_marker()
	_refresh_logical_cursor()
	_apply_visibility()

func _ensure_nodes() -> void:
	_terrain = get_node_or_null("Terrain3D") as Terrain3D
	if _terrain == null:
		_terrain = Terrain3D.new()
		_terrain.name = "Terrain3D"
		add_child(_terrain)
	_terrain.free_editor_textures = false
	if terrain_material == null:
		terrain_material = Terrain3DMaterial.new()
	terrain_material.world_background = Terrain3DMaterial.WorldBackground.NONE
	if terrain_assets == null:
		terrain_assets = Terrain3DAssets.new()
	_terrain.material = terrain_material
	_terrain.assets = terrain_assets
	_reference = _mesh_node("ReferenceTexture")
	_grid = _mesh_node("HexGrid")
	_minimum_debug = _existing_constraint_node("MinimumHeightDebug")
	_maximum_debug = _existing_constraint_node("MaximumHeightDebug")
	_city_marker = _mesh_node("CityCoreMarker")
	_logical_cursor = _mesh_node("LogicalMapCursor")
	_logical_cursor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_generated_world = _world_node("GeneratedWorld")
	_manual_world = _world_node("ManualWorld")
	_apply_visibility()

func _mesh_node(node_name: StringName) -> MeshInstance3D:
	var node := get_node_or_null(NodePath(node_name)) as MeshInstance3D
	if node == null:
		node = MeshInstance3D.new()
		node.name = node_name
		add_child(node)
	return node

func _existing_constraint_node(node_name: StringName) -> MeshInstance3D:
	var node := get_node_or_null(NodePath(node_name)) as MeshInstance3D
	if node == null or node.mesh != null:
		return node
	remove_child(node)
	node.free()
	return null

func _world_node(node_name: StringName) -> Node3D:
	var node := get_node_or_null(NodePath(node_name)) as Node3D
	if node == null:
		node = Node3D.new()
		node.name = node_name
		add_child(node)
	return node

func _refresh_city_marker() -> void:
	if _artifact == null or _terrain == null or _terrain.data == null:
		return
	if (
		city_marker_coordinate.x < 0
		or city_marker_coordinate.x >= _artifact.cols
		or city_marker_coordinate.y < 0
		or city_marker_coordinate.y >= _artifact.rows
	):
		_city_marker.mesh = null
		return
	var marker := _overlay_builder.city_marker(
		_artifact,
		_terrain.data,
		city_marker_coordinate,
	)
	_city_marker.mesh = marker["mesh"]
	_city_marker.position = marker["position"]
	_city_marker.visible = city_marker_visible

func _configure_logical_interaction() -> void:
	if _artifact == null:
		_logical_geometry = null
		_logical_space = null
		return
	_logical_geometry = HexGridGeometry.new(
		_artifact.cols,
		_artifact.rows,
		_artifact.hex_radius_meters,
	)
	_logical_space = TerrainSpaceTransform.new(_artifact)

func _refresh_logical_cursor() -> void:
	if _logical_cursor == null:
		return
	_logical_cursor.mesh = (
		_overlay_builder.logical_cursor_mesh(
			_artifact,
			_terrain.data,
			_logical_cursor_coordinate,
		)
		if (
			_logical_paint_active
			and _artifact != null
			and _terrain != null
			and _terrain.data != null
		)
		else null
	)
	_logical_cursor.visible = _logical_paint_active and _logical_cursor.mesh != null

func _refresh_generated_world() -> void:
	_ensure_nodes()
	if _artifact == null or _terrain == null or _terrain.data == null:
		return
	_generated_world_builder.rebuild(
		_generated_world,
		_artifact,
		_terrain.data,
		_generated_placements,
	)

func _ensure_constraint_meshes() -> void:
	if _artifact == null:
		return
	if _minimum_debug == null:
		_minimum_debug = _mesh_node("MinimumHeightDebug")
	if _maximum_debug == null:
		_maximum_debug = _mesh_node("MaximumHeightDebug")
	if _minimum_debug.mesh == null:
		_minimum_debug.mesh = _overlay_builder.constraint_mesh(
			_artifact,
			_artifact.minimum_image,
			Color(0.15, 0.45, 1.0, 0.22),
			-OverlayBuilder.CONSTRAINT_OFFSET,
		)
	if _maximum_debug.mesh == null:
		_maximum_debug.mesh = _overlay_builder.constraint_mesh(
			_artifact,
			_artifact.maximum_image,
			Color(1.0, 0.2, 0.15, 0.22),
			OverlayBuilder.CONSTRAINT_OFFSET,
		)

func _on_terrain_changed(changed_pixels: Rect2i) -> void:
	_sync_metadata()
	_pending_changed_pixels = (
		_pending_changed_pixels.merge(changed_pixels)
		if _pending_changed_pixels.has_area()
		else changed_pixels
	)
	if _overlay_refresh_queued:
		return
	_overlay_refresh_queued = true
	_refresh_overlays_deferred.call_deferred()

func _refresh_overlays_deferred() -> void:
	_overlay_refresh_queued = false
	var changed_pixels := _pending_changed_pixels
	_pending_changed_pixels = Rect2i()
	if not changed_pixels.has_area() or _artifact == null:
		return
	_overlay_builder.refresh_reference_heights(
		_reference.mesh,
		_artifact,
		_terrain.data,
		changed_pixels,
	)
	_overlay_builder.refresh_grid_heights(
		_grid.mesh,
		_artifact,
		_terrain.data,
		changed_pixels,
	)
	if _city_marker_intersects(changed_pixels):
		_refresh_city_marker()
	_refresh_logical_cursor()

func _city_marker_intersects(changed_pixels: Rect2i) -> bool:
	if _city_marker == null or _city_marker.mesh == null:
		return false
	var space := AonwTerrainSpaceTransform.new(_artifact)
	var pixel := space.terrain_local_to_raster_pixel(_city_marker.position)
	return changed_pixels.grow(1).has_point(pixel)

func _sync_metadata() -> void:
	if _artifact == null:
		return
	map_content_hash = _artifact.map_content_hash
	authoring_profile_hash = _artifact.authoring_profile_hash
	generated_base_hash = _artifact.generated_base_hash
	generator_version = _artifact.generator_version
	terrain_revision = _session.terrain_revision() if _session != null else terrain_revision

func _apply_visibility() -> void:
	if _reference != null:
		_reference.visible = reference_visible and _reference_texture != null
	if _grid != null:
		_grid.visible = grid_visible
	if _minimum_debug != null:
		_minimum_debug.visible = constraints_visible
	if _maximum_debug != null:
		_maximum_debug.visible = constraints_visible
	if _logical_cursor != null:
		_logical_cursor.visible = _logical_paint_active and _logical_cursor.mesh != null
	if _city_marker != null:
		_city_marker.visible = city_marker_visible

func _update_opacity(layer: MeshInstance3D, value: float) -> void:
	if layer == null or layer.mesh == null or layer.mesh.get_surface_count() == 0:
		return
	var material := layer.mesh.surface_get_material(0) as StandardMaterial3D
	if material == null:
		return
	var color := material.albedo_color
	color.a = value
	material.albedo_color = color

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
