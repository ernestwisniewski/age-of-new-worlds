@tool
extends RefCounted
## One-time, non-destructive upgrade of saved default appearance values.
const PREVIOUS := {"tree_density": 0.8, "city_hex_diameter": 160.0,
	"city_tree_height": 12.0, "city_tree_spacing": 10.0}
const CURRENT := {"tree_density": 0.95, "city_hex_diameter": 240.0,
	"city_tree_height": 8.0, "city_tree_spacing": 6.0}

static func migrate(values: Dictionary) -> Dictionary:
	var result := values.duplicate(true)
	for key in PREVIOUS:
		if result.has(key) and is_equal_approx(float(result[key]), float(PREVIOUS[key])):
			result[key] = CURRENT[key]
	return result
