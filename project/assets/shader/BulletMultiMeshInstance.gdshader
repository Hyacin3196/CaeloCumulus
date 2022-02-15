shader_type spatial;

uniform float PI = 3.1415926535897932384626;
uniform vec2 size = vec2(1.0, 0.1);

uniform sampler2D vel_tex;
uniform float max_vel;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void vertex(){
	
//	float c = 0.5;
	float x = VERTEX.x;
	float z = VERTEX.z;
	// array of bullets
	// use a list of indices of active bullets
	// use a getter for inactive bullets by finding the nearest inactive bullet from index 0
	// initial pos + TIME * velocity + rotation
	vec4 vel = texelFetch(vel_tex, ivec2(INSTANCE_ID, 0), 0);
	VERTEX.x = VERTEX.x + vel.x * max_vel * TIME;// + size.x * cos(TIME + (x) * PI * 2.0) - size.y * sin(TIME + (z) * PI * 2.0);
	VERTEX.z = VERTEX.z + vel.y * max_vel * TIME;// + size.y * sin(TIME + (x) * PI * 2.0) + size.y * cos(TIME + (z) * PI * 2.0);
//	VERTEX.z = cos(TIME + (VERTEX.z) * PI * 2.0);// + cos(TIME + (VERTEX.z) * PI * 2.0);
//	VERTEX.x = VERTEX.x + cos(TIME) * VERTEX.x - sin(TIME) * VERTEX.z;
//	VERTEX.z = VERTEX.z + sin(TIME) * VERTEX.x + cos(TIME) * VERTEX.z;
}

void fragment(){
	
}