#version 300 es

uniform mat4  projection;
uniform float pointSize;

layout (location = 0) in vec2 position;
layout (location = 1) in vec2 velocity;
out vec3 outColor;

void main() {
    gl_Position  = projection * vec4(position, 0.0, 1.0);
    gl_PointSize = pointSize;
    float v = clamp(length(velocity) * 5.0, 0.0, 1.0);
    outColor = vec3(v, 0.5 * (1.0 - v), 0.5 * (1.0 - v));
}
