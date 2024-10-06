shader_type canvas_item;

uniform float t;
uniform sampler2D noise;
uniform float flip;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float uv_x = abs(flip - UV.x);
	float noiseval = texture(noise, UV).r;
	float a = mix(mix(0.0, noiseval, t + uv_x), 1.0, t);
	a = round(a);
	COLOR.a = a;
	//float theta = mix(texture(noise, UV).r, 1.0, UV.x);
	//COLOR.a = //mix(0.0, 1.0, theta);
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
