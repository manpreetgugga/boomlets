// Frosted-glass panels for the interface. Anything drawn in the key colour
// (pure magenta, any alpha) becomes glass: the screen behind is blurred and
// washed with a light tint. Every other colour (text, icons) draws as is, so
// one material serves a whole control.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.42);
uniform float blur : hint_range(0.0, 6.0) = 3.5;

void fragment() {
	vec4 c = COLOR;
	// Edge pixels blend the key with the white rim, so glassiness follows
	// how far green has dropped on the white-to-magenta line.
	if (c.r > 0.97 && c.b > 0.97 && c.g < 0.97) {
		vec2 px = SCREEN_PIXEL_SIZE * exp2(blur);
		vec3 behind = vec3(0.0);
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				behind += textureLod(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px, blur).rgb;
			}
		}
		behind /= 9.0;
		vec3 glass = mix(behind, tint.rgb, tint.a);
		COLOR = vec4(mix(vec3(1.0), glass, 1.0 - c.g), c.a);
	}
}
