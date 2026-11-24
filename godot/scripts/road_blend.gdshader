shader_type canvas_item;
// Only soften the back verge; the entire walk band remains opaque.
varying vec4 road_tint;
void vertex() { road_tint = COLOR; }
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	pixel.a *= smoothstep(0.0, 0.11, UV.y);
	COLOR = pixel * road_tint;
}
