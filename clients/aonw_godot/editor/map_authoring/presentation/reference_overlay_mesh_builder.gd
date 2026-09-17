@tool
extends "res://game/presentation/map/terrain_overlay_mesh_builder.gd"
## Native reference drafts are identity-aligned. Keep the generic transformed
## overlay path intact, but do not scan the whole raster for each brush stroke.

func refresh_reference_heights(mesh: ArrayMesh, artifact: AonwTerrainCompiledArtifact,
		data: Terrain3DData, changed_pixels: Rect2i) -> int:
	if not artifact.reference_transform().is_equal_approx(Transform3D.IDENTITY):
		return super.refresh_reference_heights(mesh, artifact, data, changed_pixels)
	if mesh == null or not changed_pixels.has_area():
		return 0
	var area := changed_pixels.intersection(Rect2i(0, 0, artifact.width, artifact.height))
	if not area.has_area():
		return 0
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var space := TerrainSpaceTransform.new(artifact)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var point := space.raster_pixel_to_terrain_local(Vector2i(x, y))
			var height := data.get_height(point)
			point.y = (height if is_finite(height) else 0.0) + REFERENCE_OFFSET
			vertices[y * artifact.width + x] = point
	_replace_vertices(mesh, arrays, vertices)
	return area.get_area()
