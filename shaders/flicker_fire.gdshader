shader_type canvas_item;
render_mode blend_add;

uniform sampler2D NOISE_PATTERN : repeat_enable;
uniform vec2 low_frequency_scroll = vec2(0.0, 0.01);
uniform vec2 high_frequency_scroll = vec2(0.1, 0.5);
uniform vec2 low_frequency_noise_scale = vec2(1.0, 1.0);
uniform vec2 high_frequency_noise_scale = vec2(1.0, 1.0);
uniform sampler2D TONE_MAPPING;
uniform vec4 color : source_color;
uniform float distortion : hint_range(0.0, 0.5, 0.01) = 0.05;
uniform float base_intensity : hint_range(0.0, 0.5) = 0.1;
uniform float intensity_factor : hint_range(0.0, 5.0) = 1.5; 
uniform float alpha: hint_range(0.0, 1.0);
uniform float blur: hint_range(0, 8) = 3;

void fragment() {
	float shape_texture = textureLod(TEXTURE, UV, blur).a;	
	float pattern_intensity = texture(NOISE_PATTERN, SCREEN_UV * low_frequency_noise_scale  + TIME * low_frequency_scroll).r;
	float pattern_intensity2 = texture(NOISE_PATTERN, SCREEN_UV * high_frequency_noise_scale + TIME * high_frequency_scroll).r;
	float intensity = (shape_texture * pattern_intensity * pattern_intensity2 * intensity_factor)  + base_intensity;
	
	//COLOR = vec4(intensity);
	//COLOR.a = intensity;
	vec4 tone = texture(TONE_MAPPING, vec2(intensity)) * color;
	COLOR = textureLod(TEXTURE, UV + ( (pattern_intensity * pattern_intensity2) * distortion), blur) * tone;
	COLOR.a = COLOR.a * alpha;
	
}
