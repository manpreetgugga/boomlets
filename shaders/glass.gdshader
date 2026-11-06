// Tinted glass: the scene behind shows through, filtered by the colour and
// bent a little by the surface, with bright rims where the surface turns
// away from the camera, a lit top and a diagonal glint across each face.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_always, shadows_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// How much flat colour covers what is behind (0 = clear coloured glass).
uniform float tint : hint_range(0.0, 1.0) = 0.3;
uniform float frost : hint_range(0.0, 6.0) = 1.2;
uniform float glow : hint_range(0.0, 2.0) = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

varying vec3 world_normal;
varying vec3 local_pos;

void vertex() {
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	local_pos = VERTEX;
}

void fragment() {
	vec3 wn = normalize(world_normal);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - facing, 3.0);
	vec2 bend = NORMAL.xy * 0.05;
	vec3 behind = textureLod(screen_tex, SCREEN_UV + bend, frost).rgb;
	float top = clamp(wn.y, 0.0, 1.0);
	// Coloured glass filters the light coming through it. Mostly the
	// brightness behind comes through, in the glass's own hue, so the colour
	// stays clean over any floor.
	float lum = dot(behind, vec3(0.299, 0.587, 0.114));
	vec3 filtered = mix(vec3(lum), behind, 0.3) * albedo.rgb * 1.45;
	vec3 body = mix(filtered, albedo.rgb, tint) * (0.8 + 0.3 * top);
	// A thin diagonal glint band.
	float s = fract((local_pos.x + local_pos.y * 0.8 + local_pos.z) * 1.1 + 0.35);
	float glint = smoothstep(0.0, 0.04, s) * smoothstep(0.16, 0.11, s);
	ALBEDO = body + vec3(rim * 0.85 + glint * 0.22) + albedo.rgb * glow;
}
