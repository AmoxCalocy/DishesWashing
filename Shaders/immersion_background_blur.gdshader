shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float focus_amount : hint_range(0.0, 1.0) = 0.0;
uniform float blur_lod : hint_range(0.0, 5.0) = 3.2;

void fragment() {
	vec3 sharp = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 blurred = textureLod(screen_texture, SCREEN_UV, blur_lod).rgb;
	COLOR = vec4(mix(sharp, blurred, focus_amount), 1.0);
}
