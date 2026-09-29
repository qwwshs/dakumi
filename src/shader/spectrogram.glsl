// 保留数值到最后一步才映射颜色；亮度调整不触发 FFT 或纹理重建。
extern Image palette;
extern number floorDB;
extern number ceilingDB;
extern number gainDB;
extern number opacity;
extern bool packedDB;

vec4 effect(vec4 color, Image spectrum, vec2 uv, vec2 screenPosition) {
    vec4 sampleValue = Texel(spectrum, uv);
    number db;
    if (packedDB) {
        number code = floor(sampleValue.r * 255.0 + 0.5) * 256.0 + floor(sampleValue.g * 255.0 + 0.5);
        db = -256.0 + code * (280.0 / 65535.0);
    } else {
        db = 10.0 * log(max(sampleValue.r, 1.0e-30)) / log(10.0);
    }
    number level = clamp((db + gainDB - floorDB) / (ceilingDB - floorDB), 0.0, 1.0);
    vec3 rgb = Texel(palette, vec2((level * 255.0 + 0.5) / 256.0, 0.5)).rgb;
    // 低于显示下限时透明；较强部分保持稳定不透明度，避免背景图吞掉泛音。
    number alpha = opacity * smoothstep(0.0, 0.06, level);
    return vec4(rgb, alpha) * color;
}
