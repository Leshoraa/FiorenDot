#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float rand(in vec2 uv) {
    return fract(sin(uv.x * uv.y) * 423870.0);
}

void main() {
    vec2 uv = v_texcoord;
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);

    // add barrel effect
    uv += (center - uv) * 0.05 * (1.0-smoothstep(0.28, 0.78, dist));

    //vignette smooth
    vec2 bl = smoothstep(0., 0.05, uv);
    vec2 tr = smoothstep(0., 0.05, 1.-uv);
    float box = 1.-(bl.x * bl.y * tr.x * tr.y);

    vec4 color = texture(tex, uv);

    //add yellow filter
    color *= vec4(vec3(0.95, 0.95, 0.59) * (1.0-dist), 1.0);

    //noise black/white 
    //color += vec4(vec3(0.33 * (rand(uv) * rand(uv + 0.1) * rand(uv + 1.0))), 1.0) * 0.5;
    //color noise 
    color += vec4(mix(0.05, rand(uv), color.r), mix(0.05, rand(uv+0.12), color.g), mix(0., rand(uv+1.), color.b), 1.) * 0.75;
    //adding vignette
    color -= vec4(vec3(box), 1.0);

    fragColor = color;
}
