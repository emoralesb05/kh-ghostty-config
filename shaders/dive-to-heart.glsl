// Ghostty custom shader - "Dive to the Heart"
// Subtle animated light layer for the Dive to the Heart background.
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

float rayBand(vec2 p, float angle, float speed) {
    float beam = sin((p.x * cos(angle) + p.y * sin(angle)) * 24.0 + iTime * speed);
    return smoothstep(0.68, 0.98, 0.5 + 0.5 * beam);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    const float sceneOpacity = 0.32;
    const float textBloom = 0.22;

    float aspectX = iResolution.x / iResolution.y;
    vec2 aspect = vec2(aspectX, 1.0);

    vec3 paleBlue = vec3(0.58, 0.86, 1.00);
    vec3 aqua = vec3(0.10, 0.72, 0.82);
    vec3 glassViolet = vec3(0.50, 0.24, 0.88);
    vec3 indigo = vec3(0.004, 0.014, 0.030);

    vec3 scene = vec3(0.0);

    // Slow underwater veil over the side walls. The center stays mostly clear
    // for the existing light shaft in the image.
    float veilNoise = noise(uv * vec2(3.2, 5.0) + vec2(iTime * 0.010, -iTime * 0.006));
    float veil = smoothstep(0.42, 0.86, veilNoise)
               * (1.0 - smoothstep(0.28, 0.68, abs(uv.x - 0.5)));
    scene += mix(indigo, aqua, uv.y) * veil * 0.048;

    // Animated shaft aligned with the falling light in the KH image.
    float yFromOculus = clamp(uv.y / 0.72, 0.0, 1.0);
    float shaftVertical = (1.0 - smoothstep(0.66, 0.96, yFromOculus));
    float shaftCenter = 0.5 + 0.010 * sin(uv.y * 8.0 + iTime * 0.075);
    float shaftWidth = mix(0.080, 0.230, yFromOculus);
    float shaftX = (uv.x - shaftCenter) * aspectX;
    float shaft = gaussian(shaftX, shaftWidth) * shaftVertical;
    float shaftCore = gaussian(shaftX, shaftWidth * 0.34) * shaftVertical;
    float sacredThread = gaussian(shaftX, shaftWidth * 0.13)
                       * (1.0 - smoothstep(0.20, 0.74, uv.y));
    float pulse = 0.86 + 0.14 * sin(iTime * 0.22);

    // Breathing glow around the top stained-glass oculus.
    vec2 oculusP = (uv - vec2(0.50, 0.010)) * aspect;
    float oculusGlow = gaussian(length(oculusP), 0.115);
    float oculusRing = gaussian(length(oculusP) - 0.082, 0.007);
    float oculusShard = 0.5 + 0.5 * sin(atan(oculusP.y, oculusP.x) * 14.0 - iTime * 0.32);
    float oculusPulse = 0.82 + 0.18 * sin(iTime * 0.28);
    scene += paleBlue * oculusGlow * oculusPulse * 0.055;
    scene += vec3(0.88, 0.98, 1.00)
           * oculusRing
           * smoothstep(0.58, 0.96, oculusShard)
           * oculusPulse
           * 0.042;

    scene += paleBlue * shaft * pulse * 0.115;
    scene += vec3(0.86, 0.97, 1.00) * shaftCore * pulse * 0.090;
    scene += vec3(0.92, 1.00, 1.00) * sacredThread * pulse * 0.060;

    // Long, slow god rays inside the main shaft.
    vec2 rayP = (uv - vec2(0.50, 0.03)) * aspect;
    float rayMask = shaft * (1.0 - smoothstep(0.58, 0.88, uv.y));
    float rays = rayBand(rayP, 1.35, 0.18) + rayBand(rayP, 1.70, -0.14);
    scene += paleBlue * rays * rayMask * 0.038;

    // Sparse rising motes, only inside the light column.
    for (int i = 0; i < 20; i++) {
        float fi = float(i);
        float speed = 0.012 + 0.014 * hash(vec2(fi, 3.7));
        float my = 0.02 + fract(hash(vec2(fi, 2.4)) - iTime * speed) * 0.54;
        float t = clamp(my / 0.60, 0.0, 1.0);
        float beamCenterAtMote = 0.5 + 0.010 * sin(my * 8.0 + iTime * 0.075);
        float depthDrift = sin(my * 12.0 + fi * 2.1 + iTime * 0.09) * mix(0.004, 0.020, t);
        float mx = beamCenterAtMote
                 + depthDrift
                 + (hash(vec2(fi, 5.1)) - 0.5) * mix(0.045, 0.230, t);
        vec2 mp = (uv - vec2(mx, my)) * aspect;

        float m = glassMote(mp, 0.0042 + 0.0045 * hash(vec2(fi, 9.0)));
        float inBeam = gaussian((mx - beamCenterAtMote) * aspectX, mix(0.040, 0.205, t));
        float depth = mix(1.18, 0.78, t);
        scene += paleBlue * m * inBeam * depth * 0.145;
    }

    // Slower, larger motes that feel suspended rather than sparkly.
    for (int i = 0; i < 7; i++) {
        float fi = float(i);
        float speed = 0.004 + 0.006 * hash(vec2(fi, 12.3));
        float my = 0.06 + fract(hash(vec2(fi, 13.7)) - iTime * speed) * 0.48;
        float t = clamp(my / 0.58, 0.0, 1.0);
        float beamCenterAtMote = 0.5 + 0.010 * sin(my * 8.0 + iTime * 0.075);
        float depthDrift = sin(my * 10.0 + fi * 1.8 - iTime * 0.06) * mix(0.003, 0.015, t);
        float mx = beamCenterAtMote
                 + depthDrift
                 + (hash(vec2(fi, 15.1)) - 0.5) * mix(0.032, 0.165, t);
        vec2 mp = (uv - vec2(mx, my)) * aspect;

        float mote = glassMote(mp, 0.010 + 0.006 * hash(vec2(fi, 19.0)));
        float inBeam = gaussian((mx - beamCenterAtMote) * aspectX, mix(0.070, 0.200, t));
        float fade = 0.70 + 0.30 * sin(iTime * (0.16 + speed) + fi * 1.7);
        scene += vec3(0.82, 0.98, 1.00) * mote * inBeam * fade * 0.080;
    }

    // Slow breathing shimmer over the stained glass floor at the bottom.
    float glassRim = gaussian(uv.y - 0.720, 0.045)
                   * (1.0 - smoothstep(0.96, 1.0, uv.y));
    float shimmer = 0.5 + 0.5 * sin(uv.x * 46.0 + iTime * 0.55);
    scene += aqua * glassRim * shimmer * 0.035;

    vec2 glassP = (uv - vec2(0.50, 0.825)) * aspect;
    float glassFloor = smoothstep(0.665, 0.790, uv.y)
                     * (1.0 - smoothstep(0.985, 1.0, uv.y));
    float glassPetals = 0.5 + 0.5 * sin(atan(glassP.y, glassP.x) * 18.0
                                      + length(glassP) * 18.0
                                      - iTime * 0.16);
    float glassBreath = 0.80 + 0.20 * sin(iTime * 0.20);
    scene += mix(aqua, glassViolet, smoothstep(0.30, 0.92, uv.y))
           * glassFloor
           * smoothstep(0.58, 0.96, glassPetals)
           * glassBreath
           * 0.026;

    // Slightly cool the outer edges so the image stays tucked back.
    float sideShade = smoothstep(0.18, 0.56, abs(uv.x - 0.5));
    float lowerDepth = smoothstep(0.72, 0.98, uv.y)
                     * (1.0 - smoothstep(0.24, 0.62, abs(uv.x - 0.5)));
    scene -= indigo * (sideShade * 0.22 + lowerDepth * 0.08);

    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * textBloom;

    vec3 col = term.rgb + scene * bgMask * sceneOpacity + bloom;
    fragColor = vec4(col, 1.0);
}
