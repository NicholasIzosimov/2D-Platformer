shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 merged = textureLod(screen_texture, SCREEN_UV, 0.0);
	COLOR = vec4(shadow_color.rgb, merged.r * shadow_color.a);
}