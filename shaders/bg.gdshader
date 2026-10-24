shader_type canvas_item;

uniform sampler2D background_texture : repeat_enable, filter_nearest;
uniform vec2 camera_position = vec2(0.0);
uniform float camera_zoom = 1.0;

void fragment() {
    vec2 world_uv = (UV - 0.5) * camera_zoom + (camera_position * 0.001); 
    COLOR = texture(background_texture, world_uv);
}
