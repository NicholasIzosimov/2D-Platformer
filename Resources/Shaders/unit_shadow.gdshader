shader_type canvas_item;
render_mode unshaded;
uniform sampler2D body : filter_nearest;
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 body_center = vec2(0.0, -16.0);
uniform vec2 body_size = vec2(64.0, 64.0);
uniform float flip = 0.0;
uniform vec2 shift = vec2(0.0, 0.25);
uniform float top_height = 48.0;
uniform float near_width = 1.0;
uniform float far_width = 1.0;
uniform float tip_fade = 0.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 ground = floor(local_pos) + 0.5;
	float h = ground.y / shift.y;
	if (h < 0.0 || h > top_height) {
		COLOR = vec4(0.0);
	} else {
		float hn = h / top_height;
		float x = (ground.x - shift.x * h) / mix(near_width, far_width, hn);
		vec2 uv = (vec2(x, -h) - body_center) / body_size + 0.5;
		if (flip > 0.5) {
			uv.x = 1.0 - uv.x;
		}
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0);
		} else {
			float a = texture(body, region.xy + uv * region.zw).a;
			COLOR = vec4(COLOR.rgb, COLOR.a * a * mix(1.0, 1.0 - tip_fade, hn));
		}
	}
}