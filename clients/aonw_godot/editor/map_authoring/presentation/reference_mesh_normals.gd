@tool
extends RefCounted
## Smooth height-field normals for lighting AND the shadow pass. The legacy
## overlay had no vertex normals, causing severe directional shadow acne.

static func update(mesh: ArrayMesh, width: int, height: int, changed_pixels: Rect2i = Rect2i()) -> int:
	if mesh == null or mesh.get_surface_count() != 1:
		return 0
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.size() != width * height:
		return 0
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var area := Rect2i(0, 0, width, height)
	if normals.size() == vertices.size() and changed_pixels.has_area():
		area = area.intersection(changed_pixels.grow(1))
	normals.resize(vertices.size())
	if not area.has_area():
		return 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var dx := vertices[y * width + mini(x + 1, width - 1)] - vertices[y * width + maxi(x - 1, 0)]
			var dz := vertices[mini(y + 1, height - 1) * width + x] - vertices[maxi(y - 1, 0) * width + x]
			var normal := dz.cross(dx).normalized()
			normals[y * width + x] = normal if normal.is_finite() and not normal.is_zero_approx() else Vector3.UP
	arrays[Mesh.ARRAY_NORMAL] = normals
	var material := mesh.surface_get_material(0)
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return area.get_area()
