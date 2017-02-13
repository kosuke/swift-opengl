#version 300 es

layout (location = 0) in vec2 position;
layout (location = 1) in vec2 texCoords;

out vec2 coords;

void main() {
    gl_Position = vec4(position.x, position.y, 0.0, 1.0);
    coords = texCoords;
}

