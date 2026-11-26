shader_type canvas_item;

uniform vec2 mouse_pos = vec2(0.0);
uniform vec2 rect_size = vec2(1920.0, 1080.0);
uniform float radius : hint_range(0.0, 800.0) = 220.0;
uniform float softness : hint_range(1.0, 400.0) = 140.0;
uniform float darkness : hint_range(0.0, 1.0) = 1.0;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 pixel = UV * rect_size;
	float d = distance(pixel, mouse_pos);
	float light = 1.0 - smoothstep(radius - softness, radius, d);
	light *= intensity;
	COLOR = vec4(0.0, 0.0, 0.0, darkness * (1.0 - light));
}