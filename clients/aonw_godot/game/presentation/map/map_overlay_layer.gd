class_name AonwMapOverlayLayer
extends Node3D

const HOVER_OFFSET := 0.055
const SELECTION_OFFSET := 0.05
const REACHABLE_OFFSET := 0.045
const ROUTE_OFFSET := 0.065
const FOCUS_OFFSET := 0.075

var _projection: AonwHexMapProjection
var _hover: MeshInstance3D
var _selection: MeshInstance3D
var _reachable: MeshInstance3D
var _route: MeshInstance3D
var _focus: MeshInstance3D

func _ready() -> void:
	_ensure_layers()

func present(projection: AonwHexMapProjection) -> void:
	_projection = projection
	_ensure_layers()
	clear()

func set_hovered(coordinate: Vector2i) -> void:
	_ensure_layers()
	_set_single_hex(_hover, coordinate, HOVER_OFFSET)

func set_selected(coordinate: Vector2i) -> void:
	_ensure_layers()
	_set_single_hex(_selection, coordinate, SELECTION_OFFSET)

func set_focused(coordinate: Vector2i) -> void:
	_ensure_layers()
	_set_single_hex(_focus, coordinate, FOCUS_OFFSET)

func set_reachable(coordinates: Array) -> void:
	_ensure_layers()
	_update_mesh(_reachable, coordinates, REACHABLE_OFFSET)

func set_route(coordinates: Array) -> void:
	_ensure_layers()
	_update_mesh(_route, coordinates, ROUTE_OFFSET)

func clear() -> void:
	_ensure_layers()
	for layer in [_hover, _selection, _reachable, _route, _focus]:
		_hide(layer)

func _set_single_hex(layer: MeshInstance3D, coordinate: Vector2i, offset: float) -> void:
	if _projection == null or not _projection.contains(coordinate):
		_hide(layer)
		return
	var mesh := layer.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_hex(mesh, coordinate, offset)
	mesh.surface_end()
	layer.visible = true

func _update_mesh(layer: MeshInstance3D, coordinates: Array, offset: float) -> void:
	_ensure_layers()
	if _projection == null or coordinates.is_empty():
		_hide(layer)
		return
	var has_valid_coordinate := false
	for value in coordinates:
		var coordinate: Vector2i = value
		if _projection.contains(coordinate):
			has_valid_coordinate = true
			break
	if not has_valid_coordinate:
		_hide(layer)
		return
	var mesh := layer.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for value in coordinates:
		var coordinate: Vector2i = value
		if not _projection.contains(coordinate):
			continue
		_append_hex(mesh, coordinate, offset)
	mesh.surface_end()
	layer.visible = true

func _append_hex(mesh: ImmediateMesh, coordinate: Vector2i, offset: float) -> void:
	var center := _projection.hex_center(coordinate, offset)
	for corner in 6:
		mesh.surface_add_vertex(center)
		mesh.surface_add_vertex(_projection.hex_corner(coordinate, corner, offset))
		mesh.surface_add_vertex(
			_projection.hex_corner(coordinate, (corner + 1) % 6, offset)
		)

func _hide(layer: MeshInstance3D) -> void:
	if layer != null:
		layer.visible = false

func _ensure_layers() -> void:
	if _focus == null:
		_focus = _layer("Focus", Color(0.95, 0.95, 1.0, 0.82))
	if _route == null:
		_route = _layer("Route", Color(1.0, 0.72, 0.12, 0.5))
	if _reachable == null:
		_reachable = _layer("Reachable", Color(0.12, 0.78, 0.45, 0.28))
	if _selection == null:
		_selection = _layer("Selection", Color(0.12, 0.72, 1.0, 0.5))
	if _hover == null:
		_hover = _layer("Hover", Color(1.0, 0.82, 0.18, 0.38))

func _layer(layer_name: String, color: Color) -> MeshInstance3D:
	var layer := get_node_or_null(layer_name) as MeshInstance3D
	if layer == null:
		layer = MeshInstance3D.new()
		layer.name = layer_name
		add_child(layer)
	if layer.mesh is not ImmediateMesh:
		layer.mesh = ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	material.albedo_color = color
	layer.material_override = material
	layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return layer
