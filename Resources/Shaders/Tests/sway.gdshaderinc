uniform float strength = 0.0;
uniform float speed = 1.2;

vec2 sway_vertex(vec2 vertex, mat4 model_matrix, float time) {
	vec2 world_pos = (model_matrix * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	float phase = world_pos.x * 0.05 + world_pos.y * 0.03;
	vertex.x -= vertex.y * strength * sin(time * speed + phase);
	return vertex;
}