shader_type canvas_item;
// The examine view's 3D render, made to read as pixel art: every pixel is
// snapped to the art palette (with 4x4 ordered dithering between shades) and
// the item gets a one-pixel ink outline, like the sprites in the market.

uniform bool snap = true;
uniform vec3 palette[32];
uniform int palette_size = 0;
// How far the dither pushes a colour before it's snapped.
uniform float spread = 0.03;
uniform vec3 outline_color : source_color = vec3(0.02, 0.03, 0.06);

const int BAYER[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5) {
		// Outline: an empty pixel next to the item.
		vec2 px = TEXTURE_PIXEL_SIZE;
		float near = max(max(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a),
				max(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a));
		COLOR = near >= 0.5 ? vec4(outline_color, 1.0) : vec4(0.0);
	} else if (!snap || palette_size == 0) {
		COLOR = vec4(c.rgb, 1.0);
	} else {
		ivec2 p = ivec2(floor(UV / TEXTURE_PIXEL_SIZE));
		float b = (float(BAYER[(p.y & 3) * 4 + (p.x & 3)]) + 0.5) / 16.0 - 0.5;
		vec3 want = c.rgb + vec3(b * spread);
		vec3 best = palette[0];
		float best_d = 1e9;
		for (int i = 0; i < palette_size; i++) {
			vec3 d = want - palette[i];
			float dist = dot(d, d);
			if (dist < best_d) {
				best_d = dist;
				best = palette[i];
			}
		}
		COLOR = vec4(best, 1.0);
	}
}
