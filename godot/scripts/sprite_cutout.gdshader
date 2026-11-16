shader_type canvas_item;
// Keep generated sheet fringes crisp without altering the source images.
varying vec4 actor_tint;
void vertex() { actor_tint = COLOR; }
void fragment() {
 vec4 pixel = texture(TEXTURE, UV);
 if (pixel.a < 0.75) { discard; }
 COLOR = vec4(pixel.rgb, 1.0) * actor_tint;
}
