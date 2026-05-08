// Ghostty custom shader - "Dive to the Heart"
// Subtle animated light layer for the generated stained-glass background.
// The bitmap carries the art; this shader only adds motion and text bloom.

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float gaussian(float x, float width) {
    float d = x / width;
    return exp(-(d * d));
}

float glassMote(vec2 p, float size) {
    vec2 d = abs(p);
    float diamond = 1.0 - smoothstep(size * 0.45, size, d.x + d.y);
    float glow = exp(-dot(p, p) / (size * size * 7.0)) * 0.24;
    return min(diamond + glow, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    const float sceneOpacity = 0.22;
    const float textBloom = 0.24;

    float aspectX = iResolution.x / iResolution.y;
    vec2 aspect = vec2(aspectX, 1.0);

    vec3 paleBlue = vec3(0.58, 0.86, 1.00);
    vec3 aqua = vec3(0.10, 0.72, 0.82);
    vec3 indigo = vec3(0.004, 0.014, 0.030);

    vec3 scene = vec3(0.0);

    // Slow underwater veil. Kept very low so it does not fight the bitmap.
    float veilNoise = noise(uv * vec2(3.2, 5.0) + vec2(iTime * 0.010, -iTime * 0.006));
    float veil = smoothstep(0.42, 0.86, veilNoise)
               * (1.0 - smoothstep(0.28, 0.68, abs(uv.x - 0.5)));
    scene += mix(indigo, aqua, uv.y) * veil * 0.030;

    // A gentle animated shaft aligned with the generated oculus/background.
    vec2 oculusPos = vec2(0.50, 0.145);
    float yFromOculus = clamp((uv.y - oculusPos.y) / 0.78, 0.0, 1.0);
    float shaftVertical = smoothstep(0.02, 0.18, yFromOculus)
                        * (1.0 - smoothstep(0.86, 1.0, yFromOculus));
    float shaftCenter = 0.5 + 0.010 * sin(uv.y * 8.0 + iTime * 0.075);
    float shaftWidth = mix(0.035, 0.210, yFromOculus);
    float shaftX = (uv.x - shaftCenter) * aspectX;
    float shaft = gaussian(shaftX, shaftWidth) * shaftVertical;
    float shaftCore = gaussian(shaftX, shaftWidth * 0.30) * shaftVertical;
    float pulse = 0.86 + 0.14 * sin(iTime * 0.22);

    scene += paleBlue * shaft * pulse * 0.100;
    scene += vec3(0.86, 0.97, 1.00) * shaftCore * pulse * 0.075;

    // Sparse rising motes, only inside the light column.
    for (int i = 0; i < 14; i++) {
        float fi = float(i);
        float speed = 0.010 + 0.010 * hash(vec2(fi, 3.7));
        float my = 0.17 + fract(hash(vec2(fi, 2.4)) - iTime * speed) * 0.62;
        float t = clamp((my - oculusPos.y) / 0.78, 0.0, 1.0);
        float mx = 0.5 + (hash(vec2(fi, 5.1)) - 0.5) * mix(0.040, 0.250, t);
        vec2 mp = (uv - vec2(mx, my)) * aspect;

        float m = glassMote(mp, 0.0038 + 0.0035 * hash(vec2(fi, 9.0)));
        float inBeam = gaussian((mx - shaftCenter) * aspectX, mix(0.040, 0.205, t));
        scene += paleBlue * m * inBeam * 0.105;
    }

    // Slightly cool the outer edges so the generated art stays tucked back.
    float sideShade = smoothstep(0.18, 0.56, abs(uv.x - 0.5));
    scene -= indigo * sideShade * 0.18;

    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * textBloom;

    vec3 col = term.rgb + scene * bgMask * sceneOpacity + bloom;
    fragColor = vec4(col, 1.0);
}
