shader_type spatial;
render_mode cull_disabled;

uniform sampler2D water_mask : filter_linear, repeat_disable;
uniform sampler2D shore_distance : filter_linear, repeat_disable;
uniform sampler2D coverage : filter_linear, repeat_disable;
uniform sampler2D palette : source_color, filter_linear, repeat_disable;
uniform float water_depth = 8.0;
uniform float water_shore_width = 10.0;
uniform float water_waves = 0.35;
uniform float water_reference_colour = 0.7;
uniform bool has_reference = true;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float wet = texture(water_mask, UV).r;
	if (wet < 0.5 || texture(coverage, UV).r < 0.5) { discard; }
	float distance_to_land = max(0.0, texture(shore_distance, UV).r - 0.5);
	float depth = min(water_depth, distance_to_land * 0.65 + 0.15);
	float shallow = exp(-depth / max(water_shore_width * 0.18, 0.1));
	vec3 deep_color = vec3(0.014, 0.065, 0.115);
	vec3 shallow_color = vec3(0.06, 0.29, 0.27);
	vec3 water = mix(deep_color, shallow_color, shallow);
	vec3 reference = texture(palette, UV).rgb;
	// Reference tint is bounded: painted white foam does not turn the lake white.
	vec3 reference_water = clamp(reference, vec3(0.008, 0.028, 0.05), vec3(0.1, 0.32, 0.48));
	water = mix(water, reference_water, has_reference ? water_reference_colour : 0.0);
	vec2 p = world_position.xz;
	float amplitude = water_waves * smoothstep(0.0, 2.0, distance_to_land);
	vec3 n = normalize(vec3(
		sin(p.x * 0.8 + p.y * 0.42 + TIME * 0.85) * 0.1 * amplitude,
		1.0,
		cos(p.y * 1.1 - p.x * 0.31 + TIME * 0.72) * 0.075 * amplitude));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float shoreline = (1.0 - smoothstep(0.3, 1.15, distance_to_land));
	float ripple = 0.5 + 0.5 * sin(distance_to_land * 6.0 - TIME * 1.4 + sin(p.x * 0.6));
	ALBEDO = mix(water, vec3(0.5, 0.57, 0.52), shoreline * ripple * 0.13 * water_waves);
	ROUGHNESS = mix(0.16, 0.29, shallow);
	SPECULAR = 0.5;
	// Opaque shallow/deep scattering is deterministic and works in both renderers.
	// No screen-space refraction artefacts, sorting seams or fake wave displacement on rivers.
}
