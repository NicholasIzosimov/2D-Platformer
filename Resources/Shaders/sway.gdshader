shader_type canvas_item;

uniform float strength = 0.03;
uniform float speed = 1.2;

void vertex() {
	vec2 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float phase = world_pos.x * 0.05 + world_pos.y * 0.03;
	VERTEX.x -= VERTEX.y * strength * sin(TIME * speed + phase);
}