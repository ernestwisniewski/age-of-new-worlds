class_name AonwTerrainOverlayMeshBuilder
extends RefCounted

const HexGridGeometry := preload(
	"res://game/presentation/map/geometry/hex_grid_geometry.gd"
)
const TerrainSpaceTransform := preload(
	"res://game/application/terrain/terrain_space_transform.gd"
)
const REFERENCE_OFFSET := 0.012
const GRID_OFFSET := 0.035
const CONSTRAINT_OFFSET := 0.06
const LOGICAL_CURSOR_OFFSET := 0.075
const MINIMUM_GRID_WIDTH_RATIO := 0.035

func reference_mesh(
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	texture: Texture2D,
	opacity: float,
) -> ArrayMesh:
	var space := TerrainSpaceTransform.new(artifact)
	var geometry := HexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	vertices.resize(artifact.width * artifact.height)
	uvs.resize(vertices.size())
	for y in artifact.height:
		for x in artifact.width:
			var pixel := Vector2i(x, y)
			var index := y * artifact.width + x
			var source := space.raster_pixel_to_terrain_local(pixel)
			var transformed := space.reference_to_terrain_local(source)
			var terrain_height := data.get_height(Vector3(transformed.x, 0.0, transformed.z))
			transformed.y += (terrain_height if is_finite(terrain_height) else 0.0)
			transformed.y += REFERENCE_OFFSET
			vertices[index] = transformed
			uvs[index] = space.terrain_local_to_reference_uv(source, geometry.bounds())
	return _raster_mesh(
		artifact,
		vertices,
		uvs,
		Color(1.0, 1.0, 1.0, opacity),
		texture,
	)

func refresh_reference_heights(
	mesh: ArrayMesh,
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	changed_pixels: Rect2i,
) -> int:
	if mesh == null or not changed_pixels.has_area():
		return 0
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var space := TerrainSpaceTransform.new(artifact)
	var samples := 0
	for y in artifact.height:
		for x in artifact.width:
			var pixel := Vector2i(x, y)
			var source := space.raster_pixel_to_terrain_local(pixel)
			var transformed := space.reference_to_terrain_local(source)
			var sampled_pixel := space.terrain_local_to_raster_pixel(transformed)
			if not changed_pixels.has_point(sampled_pixel):
				continue
			var terrain_height := data.get_height(Vector3(transformed.x, 0.0, transformed.z))
			transformed.y += (terrain_height if is_finite(terrain_height) else 0.0)
			transformed.y += REFERENCE_OFFSET
			vertices[y * artifact.width + x] = transformed
			samples += 1
	if samples > 0:
		_replace_vertices(mesh, arrays, vertices)
	return samples

func constraint_mesh(
	artifact: AonwTerrainCompiledArtifact,
	image: Image,
	color: Color,
	vertical_offset: float,
) -> ArrayMesh:
	var heights: Image = image.duplicate()
	for y in heights.get_height():
		for x in heights.get_width():
			var value: float = heights.get_pixel(x, y).r + vertical_offset
			heights.set_pixel(x, y, Color(value, 0.0, 0.0))
	var space := TerrainSpaceTransform.new(artifact)
	var vertices := PackedVector3Array()
	vertices.resize(artifact.width * artifact.height)
	for y in artifact.height:
		for x in artifact.width:
			var pixel := Vector2i(x, y)
			var index := y * artifact.width + x
			vertices[index] = space.raster_pixel_to_terrain_local(
				pixel,
				heights.get_pixelv(pixel).r,
			)
	return _raster_mesh(artifact, vertices, PackedVector2Array(), color, null)

func grid_mesh(
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	width: float,
	opacity: float,
) -> ArrayMesh:
	var space := TerrainSpaceTransform.new(artifact)
	var geometry := HexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var edges := {}
	var visible_width := maxf(width, artifact.hex_radius_meters * MINIMUM_GRID_WIDTH_RATIO)
	for row in artifact.rows:
		for col in artifact.cols:
			var coordinate := Vector2i(col, row)
			for corner in 6:
				var first_key := geometry.corner_key(coordinate, corner)
				var second_key := geometry.corner_key(coordinate, (corner + 1) % 6)
				var edge_key := _edge_key(first_key, second_key)
				if edges.has(edge_key):
					continue
				edges[edge_key] = true
				var first := _terrain_point(
					space,
					data,
					geometry.corner_position(coordinate, corner),
					GRID_OFFSET,
				)
				var second := _terrain_point(
					space,
					data,
					geometry.corner_position(coordinate, (corner + 1) % 6),
					GRID_OFFSET,
				)
				_append_segment(vertices, indices, first, second, visible_width)
	var mesh := _mesh(vertices, PackedVector2Array(), indices)
	mesh.surface_set_material(0, _material(Color(0.0, 0.0, 0.0, opacity)))
	return mesh

func refresh_grid_heights(
	mesh: ArrayMesh,
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	changed_pixels: Rect2i,
) -> int:
	if mesh == null or not changed_pixels.has_area():
		return 0
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var space := TerrainSpaceTransform.new(artifact)
	var affected := changed_pixels.grow(1)
	var samples := 0
	for index in vertices.size():
		var vertex := vertices[index]
		if not affected.has_point(space.terrain_local_to_raster_pixel(vertex)):
			continue
		var height := data.get_height(Vector3(vertex.x, 0.0, vertex.z))
		vertex.y = (height if is_finite(height) else 0.0) + GRID_OFFSET
		vertices[index] = vertex
		samples += 1
	if samples > 0:
		_replace_vertices(mesh, arrays, vertices)
	return samples

func city_marker(
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	coordinate: Vector2i,
) -> Dictionary:
	if artifact.city_core_radius_meters <= 0.0:
		return {"mesh": null, "position": Vector3.ZERO}
	var geometry := HexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	var space := TerrainSpaceTransform.new(artifact)
	var world_center: Vector2 = geometry.tile_center(coordinate)
	var center := _terrain_point(space, data, world_center, 0.08)
	var mesh := CylinderMesh.new()
	mesh.top_radius = artifact.city_core_radius_meters
	mesh.bottom_radius = artifact.city_core_radius_meters
	mesh.height = 0.08
	mesh.radial_segments = 48
	mesh.material = _material(Color(0.95, 0.62, 0.12, 0.45))
	return {"mesh": mesh, "position": center}

func logical_cursor_mesh(
	artifact: AonwTerrainCompiledArtifact,
	data: Terrain3DData,
	coordinate: Vector2i,
) -> ArrayMesh:
	var geometry := HexGridGeometry.new(
		artifact.cols,
		artifact.rows,
		artifact.hex_radius_meters,
	)
	if not geometry.contains(coordinate):
		return null
	var space := TerrainSpaceTransform.new(artifact)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.append(_terrain_point(
		space,
		data,
		geometry.tile_center(coordinate),
		LOGICAL_CURSOR_OFFSET,
	))
	for corner in 6:
		vertices.append(_terrain_point(
			space,
			data,
			geometry.corner_position(coordinate, corner),
			LOGICAL_CURSOR_OFFSET,
		))
	for corner in 6:
		indices.append_array(PackedInt32Array([
			0,
			corner + 1,
			(corner + 1) % 6 + 1,
		]))
	var mesh := _mesh(vertices, PackedVector2Array(), indices)
	mesh.surface_set_material(0, _material(Color(1.0, 0.72, 0.05, 0.42)))
	return mesh

func _raster_mesh(
	artifact: AonwTerrainCompiledArtifact,
	vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	color: Color,
	texture: Texture2D,
) -> ArrayMesh:
	var indices := PackedInt32Array()
	for y in artifact.height - 1:
		for x in artifact.width - 1:
			var top_left := y * artifact.width + x
			var bottom_left := top_left + artifact.width
			indices.append_array(PackedInt32Array([
				top_left,
				bottom_left,
				top_left + 1,
				top_left + 1,
				bottom_left,
				bottom_left + 1,
			]))
	var mesh := _mesh(vertices, uvs, indices)
	var material := _material(color)
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mesh.surface_set_material(0, material)
	return mesh

func _mesh(
	vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _replace_vertices(
	mesh: ArrayMesh,
	arrays: Array,
	vertices: PackedVector3Array,
) -> void:
	var material := mesh.surface_get_material(0)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	return material

func _terrain_point(
	space: AonwTerrainSpaceTransform,
	data: Terrain3DData,
	logical_point: Vector2,
	vertical_offset: float,
) -> Vector3:
	var local := space.logical_to_terrain_local(logical_point)
	var terrain_height := data.get_height(local)
	local.y = (terrain_height if is_finite(terrain_height) else 0.0) + vertical_offset
	return local

func _append_segment(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	first: Vector3,
	second: Vector3,
	width: float,
) -> void:
	var direction := Vector2(second.x - first.x, second.z - first.z)
	if direction.is_zero_approx():
		return
	var perpendicular := direction.normalized().orthogonal() * maxf(width, 0.01) * 0.5
	var offset := Vector3(perpendicular.x, 0.0, perpendicular.y)
	var start := vertices.size()
	vertices.append(first - offset)
	vertices.append(first + offset)
	vertices.append(second + offset)
	vertices.append(second - offset)
	indices.append_array(PackedInt32Array([
		start,
		start + 1,
		start + 2,
		start,
		start + 2,
		start + 3,
	]))

func _edge_key(first: Vector2i, second: Vector2i) -> Vector4i:
	if first.y < second.y or (first.y == second.y and first.x < second.x):
		return Vector4i(first.x, first.y, second.x, second.y)
	return Vector4i(second.x, second.y, first.x, first.y)
