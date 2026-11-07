shader_type canvas_item;
// The thermal optic over the scene: everything cold goes to a few dark blues
// by brightness, so only what's warm (drawn on top, heat.gdshader) stands out.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 c0 : source_color = vec4(0.02, 0.03, 0.06, 1.0);
uniform vec4 c1 : source_color = vec4(0.04, 0.07, 0.13, 1.0);
uniform vec4 c2 : source_color = vec4(0.07, 0.11, 0.19, 1.0);
uniform vec4 c3 : source_color = vec4(0.11, 0.17, 0.27, 1.0);

void fragment() {
	vec3 s = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(s, vec3(0.3, 0.5, 0.2));
	vec3 c = l < 0.06 ? c0.rgb : (l < 0.14 ? c1.rgb : (l < 0.28 ? c2.rgb : c3.rgb));
	COLOR = vec4(c, 1.0);
}
