shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap_anisotropic;
uniform vec4 background_color : source_color = vec4(1.0);
uniform vec4 border_color : source_color = vec4(vec3(0.5), 1.0);
uniform vec4 shadow_color : source_color = vec4(vec3(0.0), 0.5);
uniform float blur : hint_range(0, 4);

// RED = Background, GREEN = Shadow, BLUE = Border

void fragment() {
    vec3 blur_texture = textureLod(screen_texture, SCREEN_UV, blur).rgb;
	vec4 raw_color = mix(background_color * COLOR.r, border_color, COLOR.b);
	float blur_mask = clamp(COLOR.r + COLOR.b, 0.0, 1.0);
	vec3 blended_color = mix(blur_texture, raw_color.rgb, raw_color.a);
	COLOR.rgb = mix(shadow_color.rgb, blended_color, blur_mask);
	COLOR.a = mix(shadow_color.a * COLOR.a, COLOR.a, blur_mask);
}