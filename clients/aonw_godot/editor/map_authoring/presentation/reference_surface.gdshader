shader_type spatial;
render_mode cull_disabled;

// Diffuse RGB + roughness A; OpenGL normal RGB. Installed scans, not flat biome colors.
uniform sampler2DArray ground_ar : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray ground_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_weights : filter_linear, repeat_disable;
uniform sampler2D detail_weights : filter_linear, repeat_disable;
uniform sampler2D coverage : filter_linear, repeat_disable;
uniform sampler2D shore_distance : filter_linear, repeat_disable;
uniform vec4 layer_means[6];
uniform float water_depth = 8.0;
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
varying vec3 surface_normal;

void vertex() {
	local_position = VERTEX;
	vec2 raster_uv = VERTEX.xz / max(raster_extent, vec2(0.001));
	float wet = texture(water_mask, raster_uv).r;
	float bank = texture(shore_distance, raster_uv).r;
	float reference_mix = reference_visible && has_reference ? reference_opacity : 0.0;
	VERTEX.y -= smoothstep(0.45, 0.95, wet) * min(water_depth, max(0.0, bank - 0.5) * 0.65 + 0.15) * (1.0 - reference_mix);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	surface_normal = MODEL_NORMAL_MATRIX * NORMAL;
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
	if (texture(coverage, terrain_uv).r < 0.5) { discard; }
	vec3 n = normalize(surface_normal);
	if (length(surface_normal) < 0.5) {
		n = normalize(cross(dFdx(world_position), dFdy(world_position)));
		if (n.y < 0.0) { n = -n; }
	}
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
	vec3 macro = texture(reference_macro, terrain_uv).rgb;
	vec3 mean_color = mix(layer_means[first].rgb, layer_means[second].rgb, blend);
	// Compatibility shades in sRGB; Forward+ shades in linear space.
	if (OUTPUT_IS_SRGB) {
		mean_color = mix(12.92 * mean_color, 1.055 * pow(max(mean_color, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), mean_color));
	}
	vec3 surface_detail = clamp(ar.rgb / max(mean_color, vec3(0.01)), vec3(0.65), vec3(1.4));
	// Match low-frequency colour/value, retaining genuine scan detail and PBR normals.
	vec3 target = clamp(macro, vec3(0.018), vec3(0.88)) * surface_detail;
	// Blue water must not colour the neighbouring rock face cyan.
	float water_chroma = smoothstep(0.02, 0.10, macro.b - macro.r);
	vec3 ground = mix(ar.rgb, target, has_reference ? ground_reference_tint * (1.0 - water_chroma) : 0.0);
	vec4 reference = texture(reference_texture, UV);
	float reference_blend = reference_visible && has_reference ? reference_opacity * reference.a : 0.0;
	vec3 albedo = mix(ground, reference.rgb, reference_blend);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(mix(detail_normal, n, reference_blend)), 0.0)).xyz);
	ALBEDO = albedo * relief_lighting;
	EMISSION = albedo * (1.0 - relief_lighting);
	ROUGHNESS = mix(clamp(ar.a, 0.35, 1.0), 1.0, reference_blend);
	SPECULAR = 0.25;
}
