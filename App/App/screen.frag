#version 300 es

precision mediump float;
uniform sampler2D tex;

in  vec2 coords;
out vec4 outColor;

void main() {
    outColor = texture(tex, coords);
}
