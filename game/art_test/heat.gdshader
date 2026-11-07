shader_type canvas_item;
// The thermal optic's view of something warm: its own shape, coloured by how
// much heat is left in it. Bare skin and bright parts run hottest, the top
// runs a little warmer than the feet, and clothes and kit stay cooler.
// Pixel art in, pixel art out: no blur, just a stepped ramp.

uniform vec4 cool : source_color = vec4(0.48, 0.11, 0.29, 1.0);
uniform vec4 warm : source_color = vec4(1.0, 0.70, 0.28, 1.0);
uniform vec4 hot : source_color = vec4(0.83, 0.86, 0.90, 1.0);
// 1: a living person. Lower for what's cooling.
uniform float heat = 1.0;

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float lum = dot(t.rgb, vec3(0.3, 0.5, 0.2));
	float h = clamp(((1.0 - UV.y) * 0.45 + lum * 1.5 + 0.15) * heat, 0.0, 1.0);
	// Three steps, so it stays flat like the rest of the art.
	h = floor(h * 3.0 + 0.5) / 3.0;
	vec3 c = h < 0.5 ? mix(cool.rgb, warm.rgb, h * 2.0) : mix(warm.rgb, hot.rgb, (h - 0.5) * 2.0);
	COLOR = vec4(c, t.a * step(0.01, t.a) * clamp(heat * 1.5, 0.0, 1.0));
}
