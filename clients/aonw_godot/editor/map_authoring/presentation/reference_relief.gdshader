shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D reference_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float reference_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float relief_lighting : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec4 reference = texture(reference_texture, UV);
	// The existing reference mesh updates vertices after sculpting. Derivatives
	// follow that geometry without storing stale normals or duplicating the mesh.
	vec3 relief_normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	NORMAL = faceforward(relief_normal, VERTEX, relief_normal);
	ALBEDO = reference.rgb * relief_lighting;
	EMISSION = reference.rgb * (1.0 - relief_lighting);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALPHA = reference.a * reference_opacity;
}
