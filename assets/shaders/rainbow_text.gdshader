shader_type canvas_item;

uniform sampler2D rainbowTexture : repeat_enable;
uniform float stretch = 1.0;
uniform float angle : hint_range(0.0, 360.0);
uniform float speed = 1.0;

const float DEG2RAD = PI / 180.0;
const float TIME_SCALE = -0.1;

void fragment() {
    float cosa = cos(angle * DEG2RAD);
    float sina = sin(angle * DEG2RAD);
	vec2 uv = SCREEN_UV - vec2(0.5);
    uv = vec2(
        stretch * (cosa * uv.x - sina * uv.y) + TIME * TIME_SCALE * speed * stretch,
        cosa * uv.y + sina * uv.x 
    ) + vec2(0.5);
	COLOR.rgb *= texture(rainbowTexture, uv).rgb;
}
