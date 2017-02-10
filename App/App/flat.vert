#version 300 es

uniform mat4 projection;
uniform mat4 modelMatrix;

layout (location = 0) in vec2 position;

void main() {
    gl_Position  = projection * (modelMatrix * vec4(position, 0.0, 1.0));
}
