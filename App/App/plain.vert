#version 300 es

uniform mat4 projection;

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 velocity;
out vec3 outColor;

void main() {
    gl_Position  = projection * vec4(position, 1.0);
    gl_PointSize = 10.0;
    float v = clamp(length(velocity) * 5.0, 0.0, 1.0);
    outColor = vec3(v, 0.5 * (1.0 - v), 0.5 * (1.0 - v));
}
