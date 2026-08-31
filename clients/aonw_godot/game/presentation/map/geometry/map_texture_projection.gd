class_name AonwMapTextureProjection
extends RefCounted

var _geometry: AonwHexGridGeometry

func _init(geometry: AonwHexGridGeometry) -> void:
	_geometry = geometry

func normalized_uv(point: Vector2) -> Vector2:
	var map_bounds := _geometry.bounds()
	return (point - map_bounds.position) / map_bounds.size

func target_atlas_size(tile_size: Vector2i) -> Vector2i:
	var map_bounds := _geometry.bounds()
	return Vector2i(
		roundi(map_bounds.size.x * float(tile_size.x) / (2.0 * _geometry.radius)),
		roundi(
			map_bounds.size.y * float(tile_size.y)
			/ (AonwHexGridGeometry.SQRT_3 * _geometry.radius)
		),
	)

func tile_slice_rect(coordinate: Vector2i, atlas_size: Vector2i) -> Rect2i:
	var map_bounds := _geometry.bounds()
	var center := _geometry.tile_center(coordinate) - map_bounds.position
	var scale := Vector2(atlas_size) / map_bounds.size
	var half_height := AonwHexGridGeometry.SQRT_3 * _geometry.radius * 0.5
	var top_left := Vector2(center.x - _geometry.radius, center.y - half_height) * scale
	var bottom_right := Vector2(center.x + _geometry.radius, center.y + half_height) * scale
	var clipped_top_left := top_left.clamp(Vector2.ZERO, Vector2(atlas_size))
	var clipped_bottom_right := bottom_right.clamp(Vector2.ZERO, Vector2(atlas_size))
	return Rect2i(
		Vector2i(roundi(clipped_top_left.x), roundi(clipped_top_left.y)),
		Vector2i(
			roundi(clipped_bottom_right.x - clipped_top_left.x),
			roundi(clipped_bottom_right.y - clipped_top_left.y),
		),
	)
