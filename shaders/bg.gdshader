shader_type canvas_item;

uniform sampler2D background_texture : repeat_enable, filter_nearest;
uniform vec2 camera_position = vec2(0.0);
uniform float camera_zoom = 1.0;
uniform vec2 viewport_size = vec2(640.0, 360.0);

void fragment() {
    vec2 background_size = vec2(textureSize(background_texture, 0));
    vec2 world_uv = camera_position / background_size;
    world_uv += (UV - 0.5) * viewport_size / background_size / camera_zoom;
    COLOR = texture(background_texture, world_uv);
}
