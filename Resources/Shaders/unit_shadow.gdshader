shader_type canvas_item;

uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform float feet_v = 0.75;
uniform float near_width = 0.4;
uniform float far_width = 1.8;

void fragment() {
	vec2 local = (UV - region.xy) / region.zw;
	float d = clamp((feet_v - local.y) / max(feet_v, 0.001), 0.0, 1.0);
	float w = mix(near_width, far_width, d);
	float x = 0.5 + (local.x - 0.5) / w;
	if (x < 0.0 || x > 1.0) {
		COLOR = vec4(0.0);
	} else {
		vec4 tex = texture(TEXTURE, region.xy + vec2(x, local.y) * region.zw);
		COLOR = vec4(COLOR.rgb, COLOR.a * tex.a);
	}
}