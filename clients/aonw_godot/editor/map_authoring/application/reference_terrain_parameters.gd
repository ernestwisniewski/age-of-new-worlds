@tool
extends RefCounted
## One versioned schema for UI controls, validation, presets and recipe identity.
## Geometry is staged until Apply. Appearance and camera never rebuild heightmaps.

const VERSION := 2
# key, label, min, max, step, default, stage, help
const FIELDS := [
	["level_height", "Height of JSON level 5 (m)", 0.5, 1000.0, 0.5, 18.5, "terrain", "Metric elevation envelope; never writes the gameplay JSON."],
	["mountain_scale", "Mountain relief", 0.5, 3.0, 0.05, 1.65, "terrain", "Amplitude inside mountain ranges located by heights and terrain tags."],
	["lowland_scale", "Lowland elevation", 0.15, 1.2, 0.05, 0.4, "terrain", "Keeps plains and river valleys below mountain ranges while respecting JSON elevations."],
	["hill_scale", "Rolling hills", 0.0, 2.0, 0.05, 0.65, "terrain", "Broad relief on hills; does not add random mountains on plains."],
	["reference_strength", "Reference ridge influence", 0.0, 1.0, 0.05, 0.9, "terrain", "Follow image features or an explicit ridge guide, rather than noise."],
	["reference_peak_strength", "Reference rocky crests", 0.0, 1.0, 0.05, 0.85, "terrain", "Locate crests from bright low-chroma rock inside JSON mountain ranges, not dark forest shadows."],
	["ridge_sharpness", "Ridge sharpness", 0.6, 3.0, 0.05, 1.65, "terrain", "Sharper crests and narrower summits, without hexagonal plateaus."],
	["smoothing", "Range continuity (hex radii)", 0.2, 1.5, 0.05, 0.65, "terrain", "Cross-hex smoothing of elevation and biome masks."],
	["detail_strength", "Small-scale roughness", 0.0, 0.12, 0.005, 0.018, "terrain", "Small land-only surface detail, relative to the metric envelope."],
	["detail_scale", "Detail wavelength (hex radii)", 0.2, 2.0, 0.05, 0.9, "terrain", "World-space noise wavelength; independent of raster resolution."],
	["bank_width", "Bank width (hex radii)", 0.05, 1.0, 0.05, 0.8, "terrain", "Smooth transition into the zero-height water footprint."],
	["erosion_passes", "Talus relaxation passes", 0.0, 8.0, 1.0, 3.0, "terrain", "Conservative land-only slope relaxation, not a hydraulic simulation."],
	["seed", "Detail seed", 0.0, 2147483647.0, 1.0, 73129.0, "terrain", "Changes secondary detail, not semantic water or reference placement."],
	["relief_lighting", "Relief lighting", 0.0, 1.0, 0.01, 0.85, "appearance", "Unlit reference at zero; fully lit terrain at one."],
	["rock_slope", "Rock slope threshold", 0.1, 0.95, 0.01, 0.55, "appearance", "Procedural rock on steep slopes in reference-free material mode."],
	["ground_scale", "Ground texture repeat (m)", 0.5, 32.0, 0.5, 4.0, "appearance", "World-space PBR texture scale; triplanar projection prevents cliff stretching."],
	["ground_normal_strength", "Ground normal detail", 0.0, 1.5, 0.05, 0.7, "appearance", "Strength of the scanned surface normals; does not modify terrain geometry."],
	["ground_reference_tint", "Reference ground colour", 0.0, 1.0, 0.01, 0.78, "appearance", "Match the low-frequency reference colour and brightness while retaining scanned PBR detail."],
	["surface_reference_strength", "Reference biome boundaries", 0.0, 1.0, 0.05, 0.85, "appearance", "Refine smoothly blended JSON biomes using the reference palette and canopy evidence."],
	["forest_distribution", "Forest layout: reference / natural", 0.0, 1.0, 1.0, 1.0, "appearance", "Natural clusters use biome context and seeded noise, not painted forest colours. An explicit forest guide still overrides placement."],
	["forest_patch_size", "Forest patch size (hex radii)", 0.4, 5.0, 0.1, 2.6, "appearance", "Size of connected woodland and clearings, in map space, independent of tree scale."],
	["forest_patch_coverage", "Woodland patch coverage", 0.1, 1.0, 0.05, 0.45, "appearance", "Area occupied by dense groves within suitable biomes; not a tree count."],
	["forest_edge_softness", "Woodland edge softness", 0.02, 0.4, 0.02, 0.12, "appearance", "Gradual thinning at grove boundaries without a regular hex pattern."],
	["forest_tree_budget", "Maximum generated trees", 1000.0, 80000.0, 1000.0, 40000.0, "appearance", "Bounded global budget. Active woodland gets the candidate budget instead of ocean and empty ground."],
	["tree_density", "Density inside forest patches", 0.0, 1.0, 0.05, 0.95, "appearance", "Thins deterministic candidates within forest regions. Zero disables generated trees."],
	["tree_spacing", "Tree spacing (m)", 1.0, 40.0, 0.25, 2.75, "appearance", "World-space jittered distribution, not a fixed count per hex. Work is capped."],
	["tree_height", "Tree height (m)", 1.0, 35.0, 0.25, 5.0, "appearance", "Target height before variation; roots follow the edited Terrain3D surface."],
	["tree_max_slope", "Maximum tree slope (degrees)", 5.0, 60.0, 1.0, 38.0, "appearance", "Measured on the current terrain; trees are excluded from steeper cliffs."],
	["tree_reference_strength", "Reference forest influence", 0.0, 1.0, 0.05, 0.85, "appearance", "Refines JSON forests using the reference image. An optional forest guide resolves ambiguity."],
	["tree_canopy_threshold", "Forest darkness threshold", 0.1, 0.6, 0.01, 0.3, "appearance", "Higher values admit brighter canopy; inspect the exported canopy mask for ambiguous regions."],
	["tree_conifer_share", "Temperate conifer share", 0.0, 1.0, 0.05, 0.75, "appearance", "Mixture of narrow and broad Tree3D forms; explicit jungle and taiga tags take precedence."],
	["tree_draw_distance", "Forest draw distance (m)", 100.0, 8000.0, 50.0, 3000.0, "appearance", "Chunk visibility distance. Shared Tree3D prototypes avoid per-tree native generation."],
	["water_bed_slope", "Water-bed grade", 0.1, 1.5, 0.05, 0.45, "appearance", "Metric shore-distance bathymetry: narrow channels remain shallow and wider basins deepen smoothly."],
	["water_bank_grade", "Lowland river-bank grade", 0.1, 0.8, 0.05, 0.25, "terrain", "Maximum lowland shore grade. Changes go into a new recipe; existing sculpts stay in their old workspace."],
	["water_sampling", "Shoreline samples per axis", 1.0, 3.0, 1.0, 3.0, "terrain", "Supersample narrow blue/turquoise channels near semantic water; one sample keeps the old footprint sampling."],
	["water_depth", "Maximum visual water depth (m)", 0.5, 30.0, 0.5, 8.0, "appearance", "Carves the rendered bed below the zero-height water contract. Narrow rivers stay shallow."],
	["water_shore_width", "Shallow-water colour reach (m)", 1.0, 30.0, 0.5, 10.0, "appearance", "Metric shallow/deep scattering transition measured from the reconstructed shoreline."],
	["water_waves", "Water ripple strength", 0.0, 1.0, 0.05, 0.35, "appearance", "Animated normal ripples taper at shorelines; no displaced waves breaking narrow rivers."],
	["water_reference_colour", "Reference water colour", 0.0, 1.0, 0.05, 0.7, "appearance", "Retain the reference's blue/turquoise water palette without baking its foam into geometry."],
	["sun_elevation", "Sun elevation (degrees)", 10.0, 85.0, 1.0, 48.0, "appearance", "Live light angle; has no effect on the heightmap."],
	["sun_heading", "Sun heading (degrees)", 0.0, 360.0, 1.0, 328.0, "appearance", "Live direction of terrain shadows."],
	["sun_energy", "Sun intensity", 0.1, 2.0, 0.05, 1.0, "appearance", "Direct illumination of the reconstruction."],
	["ambient_energy", "Ambient light", 0.05, 1.0, 0.05, 0.45, "appearance", "Fill light for valleys; lower values reveal landform shadows."],
	["city_scale_enabled", "Vegetation scale: legacy / city hex", 0.0, 1.0, 1.0, 1.0, "city", "City hex scales trees and spacing to the selected map radius. Legacy keeps the original metre controls."],
	["city_hex_diameter", "Represented hex diameter (model m)", 80.0, 600.0, 10.0, 240.0, "city", "Corner-to-corner city and immediate surroundings. A presentation convention, not a change to map geometry."],
	["city_tree_height", "Tree height (model m)", 3.0, 30.0, 0.5, 8.0, "city", "Real-model height before variation. Uses the same model-to-map scale as the future city."],
	["city_tree_spacing", "Tree spacing (model m)", 3.0, 30.0, 0.5, 6.0, "city", "Desired model-space spacing; existing candidate/tree budgets still apply on large maps."],
	["city_reserve_enabled", "Reserve marked city hex", 0.0, 1.0, 1.0, 0.0, "city", "Only the chosen city-marker coordinate is reserved. Off restores its original forest. No terrain is flattened."],
	["city_core_ratio", "Building core (hex radius fraction)", 0.2, 0.6, 0.01, 0.42, "city", "Clear whole tree crowns from this core. Water and steep cores are rejected without changing the map."],
	["city_outskirts_ratio", "Outskirts (hex radius fraction)", 0.65, 0.84, 0.01, 0.76, "city", "Gradually restore natural vegetation outside the core. The outer band fits entirely inside the hex."],
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
		if key in ["seed", "erosion_passes", "city_scale_enabled", "city_reserve_enabled", "forest_distribution", "forest_tree_budget", "water_sampling"] and float(value) != floorf(float(value)):
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
			values = {"reference_strength": 1.0, "mountain_scale": 1.25, "hill_scale": 0.45, "detail_strength": 0.01, "erosion_passes": 2.0, "reference_peak_strength": 1.0, "surface_reference_strength": 1.0, "ground_reference_tint": 0.9, "tree_reference_strength": 1.0}
		"Strategic natural":
			values = {"reference_strength": 0.9, "mountain_scale": 1.65, "hill_scale": 0.65, "detail_strength": 0.018, "erosion_passes": 3.0, "reference_peak_strength": 0.85, "surface_reference_strength": 0.85, "ground_reference_tint": 0.78}
		"Rugged":
			values = {"reference_strength": 0.85, "mountain_scale": 2.1, "hill_scale": 1.0, "detail_strength": 0.035, "erosion_passes": 2.0}
	for key in values:
		result[key] = values[key]
	return result
