global uniform sampler2D shadow_buffer;
global uniform vec4 shadow_buffer_rect;
global uniform vec4 shadow_params;
global uniform vec4 shadow_soft;

const float SHADOW_MAX_HEIGHT = 255.0;
const int SHADOW_MAX_STEPS = 256;

varying vec2 shadow_world;
varying float shadow_scale;

vec4 shadow_read(vec2 world) {
	vec2 local = world - shadow_buffer_rect.xy;
	if (local.x < 0.0 || local.y < 0.0 || local.x >= shadow_buffer_rect.z || local.y >= shadow_buffer_rect.w) {
		return vec4(0.0);
	}
	return texelFetch(shadow_buffer, ivec2(local), 0);
}

float shadow_facing(vec2 ground, vec2 light_ground) {
	vec2 to_light = light_ground - ground;
	float len = length(to_light);
	if (len < 0.001) {
		return 1.0;
	}
	return smoothstep(-shadow_params.y, shadow_params.y, to_light.y / len);
}

bool shadow_blocked(vec3 from, vec3 to, float start_id) {
	int steps = min(int(ceil(distance(from, to) / shadow_params.w)), SHADOW_MAX_STEPS);
	for (int i = 1; i < steps; i++) {
		vec3 ray = mix(from, to, float(i) / float(steps));
		vec4 hit = shadow_read(vec2(ray.x, ray.y - ray.z));
		if (hit.a > 0.5 && abs(hit.g - start_id) > 0.001 && abs(hit.r * SHADOW_MAX_HEIGHT - ray.z) < shadow_params.x) {
			return true;
		}
	}
	return false;
}

float shadow_sample_lit(vec3 from, vec2 light_ground, float height, vec2 side, int s, int samples, float start_id) {
	float angle = (float(s) + 0.5) / float(samples) * TAU;
	vec2 offset = vec2(cos(angle), sin(angle)) * shadow_soft.y * 0.5;
	vec3 to = vec3(light_ground + side * offset.x, max(height + offset.y, 0.0));
	return shadow_blocked(from, to, start_id) ? 0.0 : 1.0;
}

float shadow_visibility(vec3 from, vec2 light_ground, float height, float start_id) {
	int samples = int(shadow_soft.x);
	if (samples <= 0) {
		return 1.0;
	}
	if (samples == 1) {
		return shadow_blocked(from, vec3(light_ground, height), start_id) ? 0.0 : 1.0;
	}
	vec2 to_light = light_ground - from.xy;
	float len = length(to_light);
	vec2 side = len > 0.001 ? vec2(-to_light.y, to_light.x) / len : vec2(1.0, 0.0);
	int opposite_index = samples / 2;
	float first = shadow_sample_lit(from, light_ground, height, side, 0, samples, start_id);
	float opposite = shadow_sample_lit(from, light_ground, height, side, opposite_index, samples, start_id);
	if (first == opposite) {
		return first;
	}
	float visible = first + opposite;
	for (int s = 1; s < samples; s++) {
		if (s != opposite_index) {
			visible += shadow_sample_lit(from, light_ground, height, side, s, samples, start_id);
		}
	}
	return visible / float(samples);
}

float shadow_light(vec2 world, float scale, vec3 light_position, vec3 light_vertex) {
	vec2 lamp = world + (light_position.xy - light_vertex.xy) / scale;
	float height = light_position.z / scale;
	vec2 light_ground = lamp + vec2(0.0, height);
	vec2 pixel = shadow_buffer_rect.xy + floor(world - shadow_buffer_rect.xy) + 0.5;
	vec4 start = shadow_read(pixel);
	bool covered = start.a > 0.5;
	float start_height = covered ? start.r * SHADOW_MAX_HEIGHT : 0.0;
	float start_id = covered ? start.g : -1.0;
	vec3 from = vec3(pixel.x, pixel.y + start_height, start_height);
	float lit = 1.0;
	if (covered) {
		lit = 1.0 - (1.0 - shadow_facing(from.xy, light_ground)) * shadow_params.z;
	}
	if (lit > 0.0) {
		lit *= shadow_visibility(from, light_ground, height, start_id);
	}
	return lit;
}

vec4 shadow_lit_light(vec2 world, float scale, vec3 light_position, vec3 light_vertex, vec4 light_color, float energy, vec4 color) {
	vec3 light_rgb = light_color.rgb * energy;
	if (max(light_rgb.r, max(light_rgb.g, light_rgb.b)) < 0.004) {
		return vec4(0.0, 0.0, 0.0, light_color.a);
	}
	float lit = shadow_light(world, scale, light_position, light_vertex);
	return vec4(light_rgb * color.rgb * lit, light_color.a);
}