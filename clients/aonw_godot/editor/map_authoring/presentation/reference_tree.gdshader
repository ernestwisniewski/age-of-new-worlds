shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool foliage = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float wind_strength = 0.05;
varying vec4 instance_tint;
void vertex() {
	instance_tint = INSTANCE_CUSTOM;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float weight = foliage ? clamp(VERTEX.y / 3.0, 0.0, 1.0) : 0.0;
	VERTEX.x += sin(TIME * 1.2 + origin.x * 0.035 + origin.z * 0.05) * wind_strength * weight;
}
void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb * tint.rgb * instance_tint.rgb;
	ROUGHNESS = foliage ? 0.9 : 0.95;
	SPECULAR = 0.2;
	ALPHA = foliage ? tex.a : 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	if (foliage) {
		BACKLIGHT = ALBEDO * 0.25;
	} else {
		NORMAL_MAP = texture(normal_texture, UV).rgb;
		NORMAL_MAP_DEPTH = 0.65;
	}
}
