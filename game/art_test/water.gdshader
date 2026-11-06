shader_type canvas_item;
// The flooded market's water: a dark mirror of everything drawn above the
// waterline, broken into pixel-sized ripples. The playable layer is sampled
// from the screen (its own viewport, which is see-through where the market
// has gaps) and the background from `back_tex`, so characters, neon and the
// fogged signs behind all reflect without extra work.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D back_tex : filter_nearest;
uniform vec2 view_size = vec2(640.0, 360.0);
uniform float line_y = 300.0;       // waterline, in native screen pixels
uniform vec4 deep : source_color = vec4(0.024, 0.051, 0.086, 1.0);
uniform float strength = 0.55;

void fragment() {
	vec2 px = floor(SCREEN_UV * view_size);
	float d = px.y - line_y;
	float wobble = sin(px.y * 0.9 + TIME * 2.2) * 1.4 + sin(px.y * 0.27 - TIME * 1.1 + px.x * 0.04) * 1.2;
	wobble *= clamp(d / 30.0, 0.25, 1.0);
	vec2 src = vec2(px.x + floor(wobble), line_y - d - 1.0 - floor(d * 0.15));
	vec2 uv = (src + 0.5) / view_size;
	vec4 front = texture(screen_tex, uv);
	vec3 refl = mix(texture(back_tex, uv).rgb, front.rgb, front.a);
	float fade = clamp(1.0 - d / 70.0, 0.0, 1.0);
	// Darker bands between ripples, so the reflection reads as broken water.
	float band = step(0.55, fract(px.y * 0.34 + sin(px.x * 0.06 + TIME * 0.8) * 0.25));
	vec3 col = deep.rgb + refl * strength * fade * (0.55 + 0.45 * band);
	COLOR = vec4(col, 1.0);
}
