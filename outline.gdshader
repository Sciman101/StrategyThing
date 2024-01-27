shader_type canvas_item;

uniform vec4 outline_col : source_color; //Outline color
uniform float outline_thickness = 1;

void fragment() {
    
    vec4 col = texture(TEXTURE,UV);
    
    //Get alpha val of adjacent pixels
    vec2 p = TEXTURE_PIXEL_SIZE * outline_thickness;
    
    float a = texture(TEXTURE,UV+vec2(p.x,0)).a;
    a += texture(TEXTURE,UV+vec2(-p.x,0)).a;
    a += texture(TEXTURE,UV+vec2(0,p.y)).a;
    a += texture(TEXTURE,UV+vec2(0,-p.y)).a;
	a *= outline_col.a;
    
    //Using found alpha value, determine the opacity of the outline
    
    a = step(a,.5);//Clamp the a value
    col.rgb = mix(outline_col.xyz, col.rgb, col.a);
    col.a = step(a, col.a);
    
    //Get palette color
    COLOR = col;
}