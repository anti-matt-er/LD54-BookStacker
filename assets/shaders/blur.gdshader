shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap_anisotropic;
uniform float blur : hint_range(0, 4);

void fragment() {
    COLOR = textureLod(screen_texture, SCREEN_UV, blur);
	COLOR.a = 1.0;
}