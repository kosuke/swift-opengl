#version 300 es

precision mediump float;
uniform sampler2D tex;
uniform bool blur;

in  vec2 coords;
out vec4 outColor;

void main() {
    if (blur) {
        vec2 pixel  = 1.0 / vec2(textureSize(tex, 0));
        vec4 result = vec4(0.0, 0.0, 0.0, 1.0);
        float c     = 1.0 / 9.0;
        for (int j = -1; j <= 1; ++j) {
            for (int i = -1; i <= 1; ++i) {
                result += c * texture(tex, coords + vec2(pixel.x * float(i), pixel.y * float(j)));
            }
        }
        outColor = result;
    } else {
        outColor = texture(tex, coords);
    }
}
