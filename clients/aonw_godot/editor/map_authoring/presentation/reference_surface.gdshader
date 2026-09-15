shader_type spatial;
render_mode cull_disabled;

// Diffuse RGB + roughness A; OpenGL normal RGB. Installed scans, not flat biome colors.
uniform sampler2DArray ground_ar : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray ground_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_weights : filter_linear, repeat_disable;
uniform sampler2D detail_weights : filter_linear, repeat_disable;
uniform sampler2D water_mask : filter_linear, repeat_disable;
uniform sampler2D reference_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D reference_macro : source_color, filter_linear, repeat_disable;
uniform vec2 raster_extent = vec2(1.0);
uniform float ground_scale = 4.0;
uniform float ground_normal_strength = 0.7;
uniform float ground_reference_tint = 0.12;
uniform bool has_reference = false;
uniform bool reference_visible = false;
uniform float reference_opacity = 1.0;
uniform float relief_lighting = 1.0;
uniform float rock_slope = 0.55;
varying vec3 local_position;
varying vec3 world_position;

void vertex() {
	local_position = VERTEX;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Metric triplanar projection avoids stretched cliff textures and hex-shaped UV seams.
void sample_layer(int layer, vec3 p, vec3 n, out vec4 ar, out vec3 normal_delta) {
	vec3 side = step(vec3(0.0), n) * 2.0 - 1.0;
	vec3 w = pow(abs(n), vec3(4.0));
	w /= max(dot(w, vec3(1.0)), 0.0001);
	vec2 ux = vec2(-p.z * side.x, p.y);
	vec2 uy = vec2(p.x, -p.z * side.y);
	vec2 uz = vec2(p.x * side.z, p.y);
	ar = texture(ground_ar, vec3(ux, float(layer))) * w.x
		+ texture(ground_ar, vec3(uy, float(layer))) * w.y
		+ texture(ground_ar, vec3(uz, float(layer))) * w.z;
	vec3 a = texture(ground_normal, vec3(ux, float(layer))).rgb * 2.0 - 1.0;
	vec3 b = texture(ground_normal, vec3(uy, float(layer))).rgb * 2.0 - 1.0;
	vec3 c = texture(ground_normal, vec3(uz, float(layer))).rgb * 2.0 - 1.0;
	vec3 projected = vec3(side.x * a.z, a.y, -side.x * a.x) * w.x
		+ vec3(b.x, side.y * b.z, -side.y * b.y) * w.y
		+ vec3(side.z * c.x, c.y, side.z * c.z) * w.z;
	normal_delta = projected - side * w;
}

void fragment() {
	vec2 terrain_uv = local_position.xz / max(raster_extent, vec2(0.001));
	vec3 n = normalize(cross(dFdx(world_position), dFdy(world_position)));
	if (n.y < 0.0) { n = -n; }
	vec4 g = texture(ground_weights, terrain_uv);
	vec2 d = texture(detail_weights, terrain_uv).rg;
	float rock = smoothstep(rock_slope, min(0.999, rock_slope + 0.18), 1.0 - abs(n.y));
	float weights[6];
	weights[0] = g.r * (1.0 - rock);
	weights[1] = g.g * (1.0 - rock);
	weights[2] = g.b * (1.0 - rock);
	weights[3] = g.a * (1.0 - rock);
	weights[4] = mix(d.r, 1.0, rock);
	weights[5] = d.g * (1.0 - rock);
	// Only the two dominant layers are sampled: at most twelve PBR texture reads.
	int first = 0;
	int second = 1;
	for (int i = 1; i < 6; i++) {
		if (weights[i] > weights[first]) { first = i; }
	}
	second = first == 0 ? 1 : 0;
	for (int i = 0; i < 6; i++) {
		if (i != first && weights[i] > weights[second]) { second = i; }
	}
	float blend = weights[second] / max(weights[first] + weights[second], 0.0001);
	vec4 ar1; vec4 ar2; vec3 nd1; vec3 nd2;
	sample_layer(first, world_position / ground_scale, n, ar1, nd1);
	sample_layer(second, world_position / ground_scale, n, ar2, nd2);
	vec4 ar = mix(ar1, ar2, blend);
	vec3 detail_normal = normalize(n + mix(nd1, nd2, blend) * ground_normal_strength);
	vec3 macro = texture(reference_macro, UV).rgb;
	// Keep the broad reference palette without re-baking tree silhouettes/shadows.
	float luma = max(dot(macro, vec3(0.2126, 0.7152, 0.0722)), 0.04);
	vec3 tint = clamp(macro / luma, vec3(0.65), vec3(1.4));
	vec3 ground = ar.rgb * mix(vec3(1.0), tint, has_reference ? ground_reference_tint : 0.0);
	float water = smoothstep(0.45, 0.55, texture(water_mask, terrain_uv).r);
	vec3 water_color = mix(vec3(0.025, 0.13, 0.19), vec3(0.06, 0.24, 0.27), 0.5 + 0.5 * sin(world_position.x * 0.014 + world_position.z * 0.011));
	vec3 wave_normal = normalize(n + vec3(sin(world_position.z * 0.8 + TIME * 0.7) * 0.055, 0.0, cos(world_position.x * 0.55 + TIME * 0.5) * 0.035));
	ground = mix(ground, water_color, water);
	detail_normal = normalize(mix(detail_normal, wave_normal, water));
	vec4 reference = texture(reference_texture, UV);
	float reference_blend = reference_visible && has_reference ? reference_opacity * reference.a : 0.0;
	vec3 albedo = mix(ground, reference.rgb, reference_blend);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(mix(detail_normal, n, reference_blend)), 0.0)).xyz);
	ALBEDO = albedo * relief_lighting;
	EMISSION = albedo * (1.0 - relief_lighting);
	ROUGHNESS = mix(mix(clamp(ar.a, 0.35, 1.0), 0.22, water), 1.0, reference_blend);
	SPECULAR = mix(0.25, 0.55, water * (1.0 - reference_blend));
}
