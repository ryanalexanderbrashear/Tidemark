shader_type canvas_item;
// The background as it reaches the screen. With `volumetric` off it is the
// native-resolution pixel art, scaled up with nearest filtering. With it on,
// the background is softened and lit by fog drawn at the window's own
// resolution: smooth drifting fog, glows around the signs and light shafts
// under the arcology. The playable layer (market, people, water) is drawn over
// this from its own viewport and stays crisp pixel art, so the comparison is
// a realistic-feeling back against a pixel front.

uniform sampler2D back_soft : filter_linear;
uniform bool volumetric = false;
// The part of the back viewport on screen (its UV), the viewport's size, and
// where the base frame (where lights and water_y are measured) sits in it,
// as in present.gdshader.
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 tex_size = vec2(960.0, 540.0);
uniform vec2 margin = vec2(160.0, 120.0);
uniform float scale = 3.0;
uniform float water_y = 300.0;
uniform vec4 fog_color : source_color = vec4(0.2, 0.263, 0.353, 1.0);
uniform float fog_amount = 0.65;
uniform float soften = 1.0;      // blur radius, in native pixels
uniform int light_count = 0;
// Each light: xy in native screen pixels, z its reach, w its strength.
uniform vec4 light_pos[24];
// rgb its color; a is 1 for a glow, 2 for a shaft falling from it.
uniform vec4 light_col[24];

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

vec2 sharp_uv(vec2 uv) {
	vec2 t = uv * tex_size;
	vec2 cell = floor(t);
	vec2 f = clamp((fract(t) - 0.5) * scale + 0.5, 0.0, 1.0);
	return (cell + f) / tex_size;
}

void fragment() {
	vec2 uv = region.xy + UV * region.zw;
	if (!volumetric) {
		COLOR = texture(TEXTURE, sharp_uv(uv));
	} else {
		vec2 px = uv * tex_size - margin;
		vec2 texel = soften / tex_size;
		vec3 base = texture(back_soft, uv).rgb * 0.25;
		base += texture(back_soft, uv + vec2(texel.x, 0.0)).rgb * 0.125;
		base += texture(back_soft, uv - vec2(texel.x, 0.0)).rgb * 0.125;
		base += texture(back_soft, uv + vec2(0.0, texel.y)).rgb * 0.125;
		base += texture(back_soft, uv - vec2(0.0, texel.y)).rgb * 0.125;
		base += texture(back_soft, uv + texel).rgb * 0.0625;
		base += texture(back_soft, uv - texel).rgb * 0.0625;
		base += texture(back_soft, uv + vec2(texel.x, -texel.y)).rgb * 0.0625;
		base += texture(back_soft, uv + vec2(-texel.x, texel.y)).rgb * 0.0625;

		// Fog thickens toward the water and drifts.
		float h = clamp((px.y - 50.0) / (water_y - 50.0), 0.0, 1.0);
		float drift = fbm(vec2(px.x * 0.011 + TIME * 0.035, px.y * 0.028 - TIME * 0.012));
		float dens = (0.2 + 0.8 * h * h) * (0.55 + 0.9 * drift);
		vec3 col = mix(base, fog_color.rgb, clamp(dens * fog_amount, 0.0, 0.75));

		vec3 light = vec3(0.0);
		for (int i = 0; i < 24; i++) {
			if (i >= light_count) {
				break;
			}
			vec4 lp = light_pos[i];
			vec4 lc = light_col[i];
			if (lc.a < 1.5) {
				float d = length((px - lp.xy) * vec2(1.0, 1.2)) / lp.z;
				light += lc.rgb * lp.w * exp(-d * d * 2.2) * (0.45 + dens);
			} else {
				float dy = px.y - lp.y;
				if (dy > 0.0) {
					float half_w = 4.0 + dy * 0.32;
					float dx = abs(px.x - lp.x) / half_w;
					float beam = smoothstep(1.0, 0.15, dx) * exp(-dy / lp.z);
					float motes = 0.6 + 0.7 * fbm(vec2(px.x * 0.06, dy * 0.015 - TIME * 0.06));
					light += lc.rgb * lp.w * beam * motes * (0.3 + dens);
				}
			}
		}
		COLOR = vec4(col + light, 1.0);
	}
}
