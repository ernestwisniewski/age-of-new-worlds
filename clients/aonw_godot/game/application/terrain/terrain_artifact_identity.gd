class_name AonwTerrainArtifactIdentity
extends RefCounted

const COMPATIBLE := "compatible"
const REQUIRES_CONSTRAINT_REFRESH := "requiresConstraintRefresh"
const REQUIRES_MIGRATION := "requiresMigration"
const BELONGS_TO_DIFFERENT_MAP := "belongsToDifferentMap"
const UNSUPPORTED_GENERATOR := "unsupportedGenerator"

var _value: Dictionary

func _init(value: Dictionary) -> void:
	assert(not str(value.get("mapId", "")).is_empty(), "Terrain mapId is required")
	for field in ["mapContentHash", "authoringProfileHash", "generatedBaseHash"]:
		assert(_is_sha256(value.get(field)), "Terrain %s must be a SHA-256" % field)
	assert(not str(value.get("generatorVersion", "")).is_empty(), "Generator version is required")
	assert(int(value.get("rasterWidth", 0)) > 0, "Terrain raster width must be positive")
	assert(int(value.get("rasterHeight", 0)) > 0, "Terrain raster height must be positive")
	assert(
		value.get("sampleSpacingMeters") is float
		and is_finite(value["sampleSpacingMeters"])
		and float(value["sampleSpacingMeters"]) > 0.0,
		"Terrain sample spacing must be finite and positive",
	)
	_value = value.duplicate(true)

func to_dictionary() -> Dictionary:
	return _value.duplicate(true)

func compatibility_with(saved: Dictionary) -> String:
	if (
		str(saved["mapId"]) != str(_value["mapId"])
		or str(saved["mapContentHash"]) != str(_value["mapContentHash"])
	):
		return BELONGS_TO_DIFFERENT_MAP
	if str(saved["generatorVersion"]) != str(_value["generatorVersion"]):
		return UNSUPPORTED_GENERATOR
	if (
		int(saved["rasterWidth"]) != int(_value["rasterWidth"])
		or int(saved["rasterHeight"]) != int(_value["rasterHeight"])
		or not is_equal_approx(
			float(saved["sampleSpacingMeters"]),
			float(_value["sampleSpacingMeters"]),
		)
	):
		return REQUIRES_MIGRATION
	if (
		str(saved["authoringProfileHash"]) != str(_value["authoringProfileHash"])
		or str(saved["generatedBaseHash"]) != str(_value["generatedBaseHash"])
	):
		return REQUIRES_CONSTRAINT_REFRESH
	return COMPATIBLE

static func _is_sha256(value: Variant) -> bool:
	return (
		value is String
		and value.length() == 64
		and value.to_lower() == value
		and value.is_valid_hex_number(false)
	)
