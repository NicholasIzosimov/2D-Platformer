shader_type canvas_item;
render_mode unshaded;

#include "res://Resources/Shaders/Tests/sway.gdshaderinc"

const float MAX_HEIGHT = 255.0;
uniform float ground_y;
uniform float object_id;
varying float world_y;

void vertex() {
	VERTEX = sway_vertex(VERTEX, MODEL_MATRIX, TIME);
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	if (texture(TEXTURE, UV).a < 0.5) {
		discard;
	}
	float height = clamp(ground_y - world_y, 0.0, MAX_HEIGHT);
	COLOR = vec4(height / MAX_HEIGHT, object_id, 0.0, 1.0);
}