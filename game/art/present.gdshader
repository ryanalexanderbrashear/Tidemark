shader_type canvas_item;
// A world viewport onto the screen: shows `region` of it (in its UV) across
// the picture. At a whole-number `scale` (window pixels per world pixel) this
// is plain nearest-pixel scaling; in between (a fight zooming out) it's
// "sharp bilinear": every world pixel stays a solid block and only the
// window pixel on its edge blends with the next, so pixels don't come out
// unevenly sized or shimmer as the zoom moves.

uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 tex_size = vec2(960.0, 540.0);
uniform float scale = 3.0;

vec2 sharp_uv(vec2 uv) {
	vec2 t = (region.xy + uv * region.zw) * tex_size;
	vec2 cell = floor(t);
	vec2 f = clamp((fract(t) - 0.5) * scale + 0.5, 0.0, 1.0);
	return (cell + f) / tex_size;
}

void fragment() {
	COLOR = texture(TEXTURE, sharp_uv(UV));
}
