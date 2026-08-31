class_name AonwTerrainCompiledArtifact
extends RefCounted

const ArtifactIdentity := preload(
	"res://game/application/terrain/terrain_artifact_identity.gd"
)

var directory: String
var map_id: String
var map_content_hash: String
var authoring_profile_hash: String
var generated_base_hash: String
var generator_version: String
var width: int
var height: int
var sample_spacing_meters: float
var world_min_meters: Vector2
var world_origin_meters: Vector3
var cols: int
var rows: int
var hex_radius_meters: float
var max_terrain_height_meters: float
var reference_translation_meters: Vector3
var reference_rotation_degrees: Vector3
var reference_scale: Vector3
var city_core_radius_meters: float
# Reserved authoring metadata. It is not a publish constraint until city placement
# has a canonical location whose slope can be measured.
var max_city_slope: Variant = null
var base_image: Image
var minimum_image: Image
var maximum_image: Image

func raster_rect() -> Rect2i:
	return Rect2i(Vector2i.ZERO, Vector2i(width, height))

func contains_pixel(pixel: Vector2i) -> bool:
	return raster_rect().has_point(pixel)

func minimum_at(pixel: Vector2i) -> float:
	return minimum_image.get_pixelv(pixel).r

func maximum_at(pixel: Vector2i) -> float:
	return maximum_image.get_pixelv(pixel).r

func clamp_height(pixel: Vector2i, requested_height: float) -> float:
	return clampf(requested_height, minimum_at(pixel), maximum_at(pixel))

func metadata(terrain_revision: int) -> Dictionary:
	var result := identity().to_dictionary()
	result["terrainRevision"] = terrain_revision
	return result

func identity() -> AonwTerrainArtifactIdentity:
	return ArtifactIdentity.new({
		"mapId": map_id,
		"mapContentHash": map_content_hash,
		"authoringProfileHash": authoring_profile_hash,
		"generatedBaseHash": generated_base_hash,
		"generatorVersion": generator_version,
		"rasterWidth": width,
		"rasterHeight": height,
		"sampleSpacingMeters": sample_spacing_meters,
	})

func reference_transform() -> Transform3D:
	var basis := Basis.from_euler(reference_rotation_degrees * PI / 180.0)
	basis = basis.scaled(reference_scale)
	return Transform3D(basis, reference_translation_meters)
