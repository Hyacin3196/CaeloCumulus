shader_type spatial;

uniform vec4 live_color : hint_color;
uniform vec4 dead_color : hint_color;
uniform bool alive = true;

void fragment(){
	if(alive){
		EMISSION = live_color.rgb
	} else {
		EMISSION = dead_color.rgb
	}
}