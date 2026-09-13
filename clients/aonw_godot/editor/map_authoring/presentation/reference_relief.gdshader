shader_type spatial;
render_mode cull_disabled;

uniform sampler2D reference_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D biome_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 raster_extent = vec2(1.0);
uniform float reference_opacity : hint_range(0.0, 1.0) = 1.0;
uniform bool reference_visible = true;
uniform float relief_lighting : hint_range(0.0, 1.0) = 0.85;
uniform float rock_slope : hint_range(0.1, 0.95) = 0.55;
varying vec2 terrain_uv;
varying vec3 world_position;

void vertex() {
	terrain_uv = VERTEX.xz / max(raster_extent, vec2(0.001));
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 reference = texture(reference_texture, UV);
	vec3 geometric_normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	NORMAL = faceforward(geometric_normal, VERTEX, geometric_normal);
	vec3 world_normal = normalize(cross(dFdx(world_position), dFdy(world_position)));
	float slope = 1.0 - abs(world_normal.y);
	vec3 biome = texture(biome_texture, terrain_uv).rgb;
	vec3 ground = mix(biome, vec3(0.31, 0.29, 0.25), smoothstep(rock_slope, min(1.0, rock_slope + 0.2), slope));
	float blend = reference_visible ? reference_opacity * reference.a : 0.0;
	vec3 albedo = mix(ground, reference.rgb, blend);
	ALBEDO = albedo * relief_lighting;
	EMISSION = albedo * (1.0 - relief_lighting);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	// Opaque blending avoids alpha sorting artifacts over Terrain3D. Zero opacity
	// reveals the semantic material rather than a transparent, depth-writing sheet.
}
