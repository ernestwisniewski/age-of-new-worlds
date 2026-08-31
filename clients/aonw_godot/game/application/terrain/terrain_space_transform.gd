class_name AonwTerrainSpaceTransform
extends RefCounted

var _artifact: AonwTerrainCompiledArtifact

func _init(artifact: AonwTerrainCompiledArtifact) -> void:
	assert(artifact != null, "Compiled terrain artifact is required")
	_artifact = artifact

func logical_to_world(logical_position: Vector2, height_meters: float = 0.0) -> Vector3:
	return Vector3(
		logical_position.x + _artifact.world_origin_meters.x,
		height_meters,
		logical_position.y + _artifact.world_origin_meters.z,
	)

func world_to_terrain_local(world_position: Vector3) -> Vector3:
	return Vector3(
		world_position.x - _artifact.world_min_meters.x,
		world_position.y,
		world_position.z - _artifact.world_min_meters.y,
	)

func terrain_local_to_world(local_position: Vector3) -> Vector3:
	return Vector3(
		local_position.x + _artifact.world_min_meters.x,
		local_position.y,
		local_position.z + _artifact.world_min_meters.y,
	)

func logical_to_terrain_local(
	logical_position: Vector2,
	height_meters: float = 0.0,
) -> Vector3:
	return world_to_terrain_local(logical_to_world(logical_position, height_meters))

func terrain_local_to_logical(local_position: Vector3) -> Vector2:
	var world := terrain_local_to_world(local_position)
	return Vector2(
		world.x - _artifact.world_origin_meters.x,
		world.z - _artifact.world_origin_meters.z,
	)

func raster_pixel_to_terrain_local(
	pixel: Vector2i,
	height_meters: float = 0.0,
) -> Vector3:
	return Vector3(
		float(pixel.x) * _artifact.sample_spacing_meters,
		height_meters,
		float(pixel.y) * _artifact.sample_spacing_meters,
	)

func terrain_local_to_raster_pixel(local_position: Vector3) -> Vector2i:
	return Vector2i(
		roundi(local_position.x / _artifact.sample_spacing_meters),
		roundi(local_position.z / _artifact.sample_spacing_meters),
	)

func reference_to_terrain_local(reference_position: Vector3) -> Vector3:
	return _artifact.reference_transform() * reference_position

func terrain_local_to_reference_uv(
	local_position: Vector3,
	logical_bounds: Rect2,
) -> Vector2:
	return (
		(terrain_local_to_logical(local_position) - logical_bounds.position)
		/ logical_bounds.size
	).clamp(Vector2.ZERO, Vector2.ONE)
