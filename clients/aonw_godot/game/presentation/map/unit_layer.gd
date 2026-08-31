class_name AonwUnitLayer
extends Node3D

const UNIT_OFFSET := 0.24

var _projection: AonwHexMapProjection
var _units: Dictionary = {}
var _unit_ids_by_coordinate: Dictionary = {}
var _instances: Dictionary = {}
var _movement_tweens: Dictionary = {}
var _marker_mesh: CylinderMesh

func present(
	projection: AonwHexMapProjection,
	units: Array[AonwLocalMatchViewModels.UnitView],
) -> void:
	_projection = projection
	var incoming_ids: Dictionary = {}
	for unit in units:
		incoming_ids[unit.id] = true
	for unit_id in _instances.keys():
		if not incoming_ids.has(unit_id):
			_remove_unit(unit_id)
	for unit in units:
		_upsert_unit(unit)

func unit_at(coordinate: Vector2i) -> String:
	return str(_unit_ids_by_coordinate.get(coordinate, ""))

func apply_transition(transition: AonwLocalMatchViewModels.UnitTransition) -> void:
	for unit_id in transition.removed_unit_ids:
		_remove_unit(unit_id)
	for unit in transition.upserted_units:
		var steps: Array[AonwLocalMatchViewModels.MovementStep] = []
		if unit.id == transition.movement_unit_id:
			steps = transition.movement_steps
		_upsert_unit(unit, steps)

func _upsert_unit(
	unit: AonwLocalMatchViewModels.UnitView,
	movement_steps: Array[AonwLocalMatchViewModels.MovementStep] = [],
) -> void:
	var unit_id := unit.id
	if _units.has(unit_id):
		var previous: AonwLocalMatchViewModels.UnitView = _units[unit_id]
		if _unit_ids_by_coordinate.get(previous.coordinate, "") == unit_id:
			_unit_ids_by_coordinate.erase(previous.coordinate)
	_units[unit_id] = unit
	_unit_ids_by_coordinate[unit.coordinate] = unit_id
	if not _instances.has(unit_id):
		var instance := _create_marker(unit_id)
		_instances[unit_id] = instance
		add_child(instance)
		instance.position = _unit_position(unit)
	elif not movement_steps.is_empty():
		_animate_steps(unit_id, movement_steps)
	else:
		_stop_movement(unit_id)
		(_instances[unit_id] as MeshInstance3D).position = _unit_position(unit)

func _animate_steps(
	unit_id: String,
	steps: Array[AonwLocalMatchViewModels.MovementStep],
) -> void:
	_stop_movement(unit_id)
	var instance: MeshInstance3D = _instances[unit_id]
	if not is_inside_tree():
		instance.position = _unit_position(_units[unit_id])
		return
	var tween := create_tween()
	_movement_tweens[unit_id] = tween
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	for value in steps:
		var coordinate: Vector2i = value.coordinate
		tween.tween_property(instance, "position", _projection.hex_center(
			coordinate,
			UNIT_OFFSET,
		), 0.18)
	tween.finished.connect(func() -> void: _movement_tweens.erase(unit_id))

func _unit_position(unit: AonwLocalMatchViewModels.UnitView) -> Vector3:
	return _projection.hex_center(_coordinate(unit), UNIT_OFFSET)

func _coordinate(value: AonwLocalMatchViewModels.UnitView) -> Vector2i:
	return value.coordinate

func _create_marker(unit_id: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = unit_id.validate_node_name()
	instance.mesh = _marker_mesh_resource()
	return instance

func _marker_mesh_resource() -> CylinderMesh:
	if _marker_mesh != null:
		return _marker_mesh
	_marker_mesh = CylinderMesh.new()
	_marker_mesh.top_radius = 0.2
	_marker_mesh.bottom_radius = 0.24
	_marker_mesh.height = 0.38
	_marker_mesh.radial_segments = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.72, 1.0)
	material.metallic = 0.15
	material.roughness = 0.38
	_marker_mesh.material = material
	return _marker_mesh

func _remove_unit(unit_id: String) -> void:
	_stop_movement(unit_id)
	if _instances.has(unit_id):
		(_instances[unit_id] as Node).queue_free()
		_instances.erase(unit_id)
	if _units.has(unit_id):
		var unit: AonwLocalMatchViewModels.UnitView = _units[unit_id]
		if _unit_ids_by_coordinate.get(unit.coordinate, "") == unit_id:
			_unit_ids_by_coordinate.erase(unit.coordinate)
	_units.erase(unit_id)

func _stop_movement(unit_id: String) -> void:
	if not _movement_tweens.has(unit_id):
		return
	(_movement_tweens[unit_id] as Tween).kill()
	_movement_tweens.erase(unit_id)
