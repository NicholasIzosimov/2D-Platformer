shader_type canvas_item;

#include "res://Resources/Shaders/Tests/shadow_light.gdshaderinc"

uniform float strength = 0.03;
uniform float speed = 1.2;

void vertex() {
	vec2 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float phase = world_pos.x * 0.05 + world_pos.y * 0.03;
	VERTEX.x -= VERTEX.y * strength * sin(TIME * speed + phase);
	shadow_world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	shadow_scale = length(CANVAS_MATRIX[0].xy);
}

void light() {
	LIGHT = shadow_lit_light(shadow_world, shadow_scale, LIGHT_POSITION, LIGHT_VERTEX, LIGHT_COLOR, LIGHT_ENERGY, COLOR);
}