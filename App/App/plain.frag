#version 300 es

precision mediump float;
out vec4 color;
in  vec3 outColor;

void main() {
    vec2 p  = 2.0 * gl_PointCoord - vec2(1.0);
    float r2 = dot(p, p);
    if (r2 > 1.0) {
        discard;
    }
    color = vec4(outColor, clamp(2.0 * (1.0 - r2) ,0.0, 1.0));
}
