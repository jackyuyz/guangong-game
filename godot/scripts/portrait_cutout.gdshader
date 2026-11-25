shader_type canvas_item;
// Crop the existing pixel bust into the jade medallion's inner opening.
uniform vec2 portrait_size = vec2(40.0, 50.0);
uniform float radius = 22.0;
varying vec4 portrait_tint;
varying vec2 portrait_position;
void vertex() {
 portrait_tint = COLOR;
 portrait_position = VERTEX;
}
void fragment() {
 vec2 position = portrait_position - portrait_size * 0.5;
 vec4 pixel = texture(TEXTURE, UV);
 if (dot(position, position) > radius * radius || pixel.a < 0.75) { discard; }
 COLOR = vec4(pixel.rgb, 1.0) * portrait_tint;
}
