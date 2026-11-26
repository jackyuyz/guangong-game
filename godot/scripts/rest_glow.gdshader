shader_type canvas_item;
render_mode unshaded;
uniform vec4 frame_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float strength = 0.0;
uniform float outline_width = 5.0;
uniform vec2 atlas_pixel_size = vec2(0.0005637, 0.0011274);
uniform sampler2D source_atlas : source_color, filter_nearest;
varying vec4 glow_tint;
void vertex() {
 glow_tint = COLOR;
 vec2 local_uv = (UV - frame_rect.xy) / frame_rect.zw;
 VERTEX += (local_uv * 2.0 - 1.0) * outline_width;
 UV += (local_uv * 2.0 - 1.0) * outline_width * atlas_pixel_size;
}
float alpha_at(vec2 uv) {
 if (any(lessThan(uv, frame_rect.xy)) || any(greaterThan(uv, frame_rect.xy + frame_rect.zw))) { return 0.0; }
 return step(0.75, texture(source_atlas, uv).a);
}
void fragment() {
 vec2 d = atlas_pixel_size * outline_width;
 float center = alpha_at(UV);
 float edge = max(max(alpha_at(UV + vec2(d.x, 0.0)), alpha_at(UV - vec2(d.x, 0.0))), max(alpha_at(UV + vec2(0.0, d.y)), alpha_at(UV - vec2(0.0, d.y))));
 vec3 jade_gold = mix(vec3(0.42, 0.84, 0.66), vec3(0.93, 0.86, 0.51), clamp(UV.y, 0.0, 1.0));
 COLOR = vec4(jade_gold, max(0.0, edge - center) * strength) * glow_tint;
}
