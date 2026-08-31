@tool
class_name AonwMapSurface
extends Node3D

const OverlayBuilder := preload(
	"res://game/presentation/map/terrain_overlay_mesh_builder.gd"
)
const RenderSettings := preload("res://game/presentation/map/map_render_settings.gd")

signal map_presented(world_size: Vector2, maximum_height: float)

@export var render_settings: Resource = RenderSettings.new()

var _overlay_builder := OverlayBuilder.new()
var _map: AonwMapView
var _artifact: AonwTerrainCompiledArtifact
var _projection: AonwHexMapProjection
var _reference_texture: Texture2D
var _terrain: Terrain3D
var _reference: MeshInstance3D
var _grid: MeshInstance3D
var _ignore_settings_changed := false
var _connected_settings: Resource

func _ready() -> void:
	_connect_settings()
	_ensure_layers()
	_apply_visibility()

func present(
	map: AonwMapView,
	artifact: AonwTerrainCompiledArtifact,
	reference_texture: Texture2D,
) -> void:
	assert(map != null, "MapView is required")
	assert(artifact != null, "Compiled Terrain3D artifact is required")
	assert(reference_texture != null, "Reference texture is required")
	if str(map.map_id()) != artifact.map_id or map.content_hash() != artifact.map_content_hash:
		push_error("Terrain3D artifact identity does not match MapView")
		return
	_map = map
	_artifact = artifact
	_reference_texture = reference_texture
	_ensure_layers()
	_import_base_terrain()
	_projection = AonwHexMapProjection.new(_map, _artifact, _terrain.data)
	_rebuild_overlays()
	var height_range: Vector2 = _terrain.data.get_height_range()
	map_presented.emit(_projection.world_size(), height_range.y)

func projection() -> AonwHexMapProjection:
	return _projection

func terrain() -> Terrain3D:
	_ensure_layers()
	return _terrain

func pick_ray(local_origin: Vector3, local_direction: Vector3) -> Vector2i:
	if _projection == null or local_direction.is_zero_approx():
		return AonwHexMapProjection.INVALID_HEX
	var intersection := _terrain.get_intersection(local_origin, local_direction, false)
	if not intersection.is_finite():
		return AonwHexMapProjection.INVALID_HEX
	return _projection.local_to_hex(intersection)

func set_reference_visible(value: bool) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.reference_visible = value)
	_reference.visible = render_settings.reference_visible

func set_reference_opacity(value: float) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.reference_opacity = value)
	_update_opacity(_reference, render_settings.reference_opacity)

func set_grid_visible(value: bool) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.grid_visible = value)
	_grid.visible = render_settings.grid_visible

func set_grid_opacity(value: float) -> void:
	_ensure_layers()
	_update_setting(func() -> void: render_settings.grid_opacity = value)
	_update_opacity(_grid, render_settings.grid_opacity)

func set_grid_width(value: float) -> void:
	_update_setting(func() -> void: render_settings.grid_width = value)
	_rebuild_overlays()

func _import_base_terrain() -> void:
	_clear_terrain_data()
	_terrain.vertex_spacing = _artifact.sample_spacing_meters
	var images: Array[Image]
	images.resize(Terrain3DRegion.TYPE_MAX)
	images[Terrain3DRegion.TYPE_HEIGHT] = _artifact.base_image.duplicate()
	_terrain.data.import_images(images)
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera != null:
		_terrain.set_camera(camera)

func _clear_terrain_data() -> void:
	for region in _terrain.data.get_regions_active():
		_terrain.data.remove_region(region, false)
	_terrain.data.update_maps(Terrain3DRegion.TYPE_MAX, true, false)

func _rebuild_overlays() -> void:
	if _artifact == null or _terrain == null or _reference_texture == null:
		return
	_reference.mesh = _overlay_builder.reference_mesh(
		_artifact,
		_terrain.data,
		_reference_texture,
		render_settings.reference_opacity,
	)
	_reference.transform = Transform3D.IDENTITY
	_grid.mesh = _overlay_builder.grid_mesh(
		_artifact,
		_terrain.data,
		render_settings.grid_width,
		render_settings.grid_opacity,
	)
	_apply_visibility()

func _ensure_layers() -> void:
	_terrain = get_node_or_null("Terrain3D") as Terrain3D
	if _terrain == null:
		_terrain = Terrain3D.new()
		_terrain.name = "Terrain3D"
		add_child(_terrain)
	_terrain.free_editor_textures = false
	if _terrain.material == null:
		_terrain.material = Terrain3DMaterial.new()
	_terrain.material.world_background = Terrain3DMaterial.WorldBackground.NONE
	_reference = _mesh_node("ReferenceTexture")
	_grid = _mesh_node("HexGrid")

func _mesh_node(node_name: StringName) -> MeshInstance3D:
	var node := get_node_or_null(NodePath(node_name)) as MeshInstance3D
	if node == null:
		node = MeshInstance3D.new()
		node.name = node_name
		add_child(node)
	return node

func _apply_visibility() -> void:
	if _reference != null:
		_reference.visible = render_settings.reference_visible
	if _grid != null:
		_grid.visible = render_settings.grid_visible

func _connect_settings() -> void:
	if render_settings == null:
		render_settings = RenderSettings.new()
	if _connected_settings == render_settings:
		return
	_disconnect_settings()
	_connected_settings = render_settings
	if not _connected_settings.changed.is_connected(_on_settings_changed):
		_connected_settings.changed.connect(_on_settings_changed)

func _disconnect_settings() -> void:
	if (
		_connected_settings != null
		and _connected_settings.changed.is_connected(_on_settings_changed)
	):
		_connected_settings.changed.disconnect(_on_settings_changed)
	_connected_settings = null

func _update_setting(change: Callable) -> void:
	_ignore_settings_changed = true
	change.call()
	_ignore_settings_changed = false

func _on_settings_changed() -> void:
	if _ignore_settings_changed:
		return
	_rebuild_overlays()

func _update_opacity(layer: MeshInstance3D, value: float) -> void:
	if layer == null or layer.mesh == null or layer.mesh.get_surface_count() == 0:
		return
	var material := layer.mesh.surface_get_material(0) as StandardMaterial3D
	if material == null:
		return
	var color := material.albedo_color
	color.a = value
	material.albedo_color = color
