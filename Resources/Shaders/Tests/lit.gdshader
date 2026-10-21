shader_type canvas_item;

#include "res://Resources/Shaders/Tests/shadow_light.gdshaderinc"
#include "res://Resources/Shaders/Tests/sway.gdshaderinc"

void vertex() {
	VERTEX = sway_vertex(VERTEX, MODEL_MATRIX, TIME);
	shadow_world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	shadow_scale = length(CANVAS_MATRIX[0].xy);
}

void light() {
	LIGHT = shadow_lit_light(shadow_world, shadow_scale, LIGHT_POSITION, LIGHT_VERTEX, LIGHT_COLOR, LIGHT_ENERGY, COLOR);
}