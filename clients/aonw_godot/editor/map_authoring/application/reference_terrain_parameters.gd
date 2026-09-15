@tool
extends RefCounted
## One versioned schema for UI controls, validation, presets and recipe identity.
## Geometry is staged until Apply. Appearance and camera never rebuild heightmaps.

const VERSION := 2
# key, label, min, max, step, default, stage, help
const FIELDS := [
	["level_height", "Height of JSON level 5 (m)", 0.5, 1000.0, 0.5, 18.5, "terrain", "Metric elevation envelope; never writes the gameplay JSON."],
	["mountain_scale", "Mountain relief", 0.5, 3.0, 0.05, 1.65, "terrain", "Amplitude inside mountain ranges located by heights and terrain tags."],
	["hill_scale", "Rolling hills", 0.0, 2.0, 0.05, 0.65, "terrain", "Broad relief on hills; does not add random mountains on plains."],
	["reference_strength", "Reference ridge influence", 0.0, 1.0, 0.05, 0.9, "terrain", "Follow image features or an explicit ridge guide, rather than noise."],
	["ridge_sharpness", "Ridge sharpness", 0.6, 3.0, 0.05, 1.65, "terrain", "Sharper crests and narrower summits, without hexagonal plateaus."],
	["smoothing", "Range continuity (hex radii)", 0.2, 1.5, 0.05, 0.65, "terrain", "Cross-hex smoothing of elevation and biome masks."],
	["detail_strength", "Small-scale roughness", 0.0, 0.12, 0.005, 0.018, "terrain", "Small land-only surface detail, relative to the metric envelope."],
	["detail_scale", "Detail wavelength (hex radii)", 0.2, 2.0, 0.05, 0.9, "terrain", "World-space noise wavelength; independent of raster resolution."],
	["bank_width", "Bank width (hex radii)", 0.05, 1.0, 0.05, 0.35, "terrain", "Smooth transition into the zero-height water footprint."],
	["erosion_passes", "Talus relaxation passes", 0.0, 8.0, 1.0, 3.0, "terrain", "Conservative land-only slope relaxation, not a hydraulic simulation."],
	["seed", "Detail seed", 0.0, 2147483647.0, 1.0, 73129.0, "terrain", "Changes secondary detail, not semantic water or reference placement."],
	["relief_lighting", "Relief lighting", 0.0, 1.0, 0.01, 0.85, "appearance", "Unlit reference at zero; fully lit terrain at one."],
	["rock_slope", "Rock slope threshold", 0.1, 0.95, 0.01, 0.55, "appearance", "Procedural rock on steep slopes in reference-free material mode."],
	["ground_scale", "Ground texture repeat (m)", 0.5, 32.0, 0.5, 4.0, "appearance", "World-space PBR texture scale; triplanar projection prevents cliff stretching."],
	["ground_normal_strength", "Ground normal detail", 0.0, 1.5, 0.05, 0.7, "appearance", "Strength of the scanned surface normals; does not modify terrain geometry."],
	["ground_reference_tint", "Reference ground palette", 0.0, 0.5, 0.01, 0.12, "appearance", "Broad reference hue only, not painted tree shadows or lighting."],
	["tree_density", "Forest coverage", 0.0, 1.0, 0.05, 0.8, "appearance", "Thins deterministic candidates within forest regions. Zero disables generated trees."],
	["tree_spacing", "Tree spacing (m)", 2.0, 40.0, 0.5, 7.0, "appearance", "World-space jittered distribution, not a fixed count per hex. Work is capped."],
	["tree_height", "Tree height (m)", 1.0, 35.0, 0.5, 9.0, "appearance", "Target height before variation; roots follow the edited Terrain3D surface."],
	["tree_max_slope", "Maximum tree slope (degrees)", 5.0, 60.0, 1.0, 38.0, "appearance", "Measured on the current terrain; trees are excluded from steeper cliffs."],
	["tree_reference_strength", "Reference forest influence", 0.0, 1.0, 0.05, 0.85, "appearance", "Refines JSON forests using the reference image. An optional forest guide resolves ambiguity."],
	["tree_draw_distance", "Forest draw distance (m)", 100.0, 8000.0, 50.0, 3000.0, "appearance", "Chunk visibility distance. Shared Tree3D prototypes avoid per-tree native generation."],
	["sun_elevation", "Sun elevation (degrees)", 10.0, 85.0, 1.0, 48.0, "appearance", "Live light angle; has no effect on the heightmap."],
	["sun_heading", "Sun heading (degrees)", 0.0, 360.0, 1.0, 328.0, "appearance", "Live direction of terrain shadows."],
	["sun_energy", "Sun intensity", 0.1, 2.0, 0.05, 1.0, "appearance", "Direct illumination of the reconstruction."],
	["ambient_energy", "Ambient light", 0.05, 1.0, 0.05, 0.45, "appearance", "Fill light for valleys; lower values reveal landform shadows."],
	["camera_pitch", "Strategic camera pitch", 25.0, 80.0, 1.0, 52.0, "camera", "Perspective strategic view; inspect its live preview below."],
	["camera_yaw", "Strategic camera heading", -180.0, 180.0, 1.0, 0.0, "camera", "Rotate around the map."],
	["camera_zoom", "Strategic camera zoom", 0.5, 8.0, 0.05, 1.0, "camera", "Perspective dolly, not orthographic-size-only zoom."],
	["camera_fov", "Strategic field of view", 20.0, 65.0, 1.0, 38.0, "camera", "A moderate FOV avoids an exaggerated wide-angle landscape."],
]

static func defaults(level_height: float = 18.5) -> Dictionary:
	var result := {}
	for field in FIELDS:
		result[field[0]] = float(field[5])
	result["level_height"] = clampf(level_height, 0.5, 1000.0)
	return result

static func descriptor(key: String) -> Array:
	for field in FIELDS:
		if field[0] == key:
			return field
	return []

static func validate(values: Dictionary) -> String:
	for key in values:
		if key is not String:
			return "Terrain parameter keys must be strings"
		var field := descriptor(key)
		if field.is_empty():
			return "Unknown terrain parameter: " + key
		var value: Variant = values[key]
		if not (value is float or value is int) or not is_finite(float(value)):
			return "Non-finite or non-numeric terrain parameter: " + key
		if float(value) < field[2] or float(value) > field[3]:
			return "Terrain parameter is outside its supported range: " + key
		if key in ["seed", "erosion_passes"] and float(value) != floorf(float(value)):
			return "Terrain parameter must be an integer: " + key
	return ""

static func normalized(values: Dictionary, level_height: float = 18.5) -> Dictionary:
	var result := defaults(level_height)
	for key in values:
		result[key] = float(values[key])
	return result

static func geometry(values: Dictionary) -> Dictionary:
	var result := {}
	for field in FIELDS:
		if field[6] == "terrain":
			result[field[0]] = values[field[0]]
	return result

static func preset(name: String, current: Dictionary) -> Dictionary:
	var result := current.duplicate(true)
	var values := {}
	match name:
		"Reference faithful":
			values = {"reference_strength": 1.0, "mountain_scale": 1.25, "hill_scale": 0.45, "detail_strength": 0.01, "erosion_passes": 2.0}
		"Strategic natural":
			values = {"reference_strength": 0.9, "mountain_scale": 1.65, "hill_scale": 0.65, "detail_strength": 0.018, "erosion_passes": 3.0}
		"Rugged":
			values = {"reference_strength": 0.85, "mountain_scale": 2.1, "hill_scale": 1.0, "detail_strength": 0.035, "erosion_passes": 2.0}
	for key in values:
		result[key] = values[key]
	return result
