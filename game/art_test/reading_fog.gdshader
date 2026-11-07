shader_type canvas_item;
// A memory reading: white comes in from the edges like fog and eats the
// picture (horror pass, case 1: "the wipe from inside, white spreads like
// fog"). Drawn on the game's pixel grid with an ordered dither, so it stays
// pixel art at any window size.

uniform vec2 native = vec2(640.0, 360.0);
// 0: none. 1: the deepest it goes.
uniform float amount = 0.0;
uniform float time = 0.0;
uniform vec4 white : source_color = vec4(0.83, 0.86, 0.90, 1.0);

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float wave(vec2 p) {
	return sin(p.x * 0.031 + time * 0.7) * 0.5 + sin(p.y * 0.047 - time * 0.5) * 0.35 + sin((p.x + p.y) * 0.019 + time * 0.3) * 0.4;
}

void fragment() {
	vec2 px = floor(UV * native);
	// Distance from the middle, squashed to the screen's shape: 0 centre, 1 edge.
	vec2 d = abs(UV - 0.5) * 2.0;
	float edge = max(d.x, d.y * 0.9);
	float fog = smoothstep(1.05 - amount * 1.1, 1.25 - amount * 0.6, edge + wave(px) * 0.12);
	fog = clamp(fog * (0.55 + amount * 0.5), 0.0, 1.0);
	int i = int(mod(px.y, 4.0)) * 4 + int(mod(px.x, 4.0));
	float on = step(BAYER[i] + 0.5, fog * 16.0);
	// A faint wash under the dither, so the white has body.
	COLOR = vec4(white.rgb, max(on * 0.92, fog * 0.18 * amount));
}
