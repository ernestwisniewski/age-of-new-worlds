@tool
extends RefCounted
## Smooth height-field normals for lighting AND the shadow pass. The legacy
## overlay had no vertex normals, causing severe directional shadow acne.

static func update(mesh: ArrayMesh, width: int, height: int) -> void:
	if mesh == null or mesh.get_surface_count() != 1:
		return
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.size() != width * height:
		return
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for y in height:
		for x in width:
			var dx := vertices[y * width + mini(x + 1, width - 1)] - vertices[y * width + maxi(x - 1, 0)]
			var dz := vertices[mini(y + 1, height - 1) * width + x] - vertices[maxi(y - 1, 0) * width + x]
			var normal := dz.cross(dx).normalized()
			normals[y * width + x] = normal if normal.is_finite() and not normal.is_zero_approx() else Vector3.UP
	arrays[Mesh.ARRAY_NORMAL] = normals
	var material := mesh.surface_get_material(0)
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
