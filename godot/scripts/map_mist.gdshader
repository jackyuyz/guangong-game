shader_type canvas_item;
// Reuse the existing ink-wash alpha as a soft, static parchment-colored veil.
uniform vec4 mist_color : source_color = vec4(0.94, 0.87, 0.7, 0.5);
uniform float alpha_power = 1.0;
varying vec4 veil_tint;
void vertex() { veil_tint = COLOR; }
void fragment() {
 float opacity = texture(TEXTURE, UV).a;
 COLOR = vec4(mist_color.rgb, pow(opacity, alpha_power) * mist_color.a) * veil_tint;
}
