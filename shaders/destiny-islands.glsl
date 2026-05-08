// Ghostty custom shader - "Destiny Islands"
// Subtle animated sunset/ocean layer for the Destiny Islands background.
// The bitmap carries the island; this shader only adds motion and text bloom.

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

float sparkle(vec2 uv, float density, float threshold, float speed) {
    vec2 grid = floor(uv * density);
    vec2 cell = fract(uv * density) - 0.5;
    float h = hash(grid);

    float d = length(cell);
    float core = 1.0 - smoothstep(0.020, 0.065, d);
    float glow = (1.0 - smoothstep(0.065, 0.220, d)) * 0.20;
    float twinkle = 0.45 + 0.55 * sin(iTime * speed + h * 6.2831853);
    return (core + glow) * twinkle * step(threshold, h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    const float sceneOpacity = 0.46;
    const float textBloom = 0.22;

    float aspectX = iResolution.x / iResolution.y;
    vec2 aspect = vec2(aspectX, 1.0);

    vec3 gold = vec3(1.00, 0.82, 0.36);
    vec3 amber = vec3(1.00, 0.50, 0.16);
    vec3 coral = vec3(0.92, 0.28, 0.24);
    vec3 rose = vec3(0.58, 0.16, 0.25);
    vec3 leaf = vec3(0.36, 0.62, 0.18);
    vec3 deep = vec3(0.040, 0.014, 0.018);

    vec3 scene = vec3(0.0);

    // The source image's sun sits low on the right. Keep the pulse broad so it
    // still lines up when Ghostty crops the image to different window ratios.
    vec2 sunPos = vec2(0.905, 0.565);
    vec2 sunP = (uv - sunPos) * aspect;
    float sunDist = length(sunP);
    float sunPulse = 0.86 + 0.14 * sin(iTime * 0.18);
    float sunHalo = gaussian(sunDist, 0.235);
    float sunCore = gaussian(sunDist, 0.075);
    scene += mix(amber, gold, 0.56) * sunHalo * sunPulse * 0.235;
    scene += vec3(1.00, 0.92, 0.62) * sunCore * sunPulse * 0.130;

    // Slow sunset rays through the open sky.
    float rayAngle = atan(sunP.y, sunP.x);
    float rays = 0.5 + 0.5 * sin(rayAngle * 9.0 + iTime * 0.20 + sunDist * 3.5);
    rays = smoothstep(0.64, 0.96, rays);
    float skyMask = (1.0 - smoothstep(0.64, 0.92, uv.y))
                  * smoothstep(0.28, 0.96, uv.x)
                  * smoothstep(0.08, 0.32, sunDist);
    scene += mix(gold, coral, 0.35) * rays * sunHalo * skyMask * 0.125;

    // Painterly cloud warmth that drifts almost imperceptibly.
    float cloudA = noise(vec2(uv.x * 3.1 + iTime * 0.010, uv.y * 10.0));
    float cloudB = noise(vec2(uv.x * 5.4 - iTime * 0.007, uv.y * 15.0));
    float cloudBand = smoothstep(0.48, 0.84, cloudA * 0.70 + cloudB * 0.30)
                    * (1.0 - smoothstep(0.58, 0.80, uv.y));
    scene += mix(rose, amber, smoothstep(0.20, 0.95, uv.x)) * cloudBand * 0.095;

    // Golden reflection and water bands on the lower-right ocean.
    float waterMask = smoothstep(0.58, 0.76, uv.y);
    float reflection = gaussian((uv.x - 0.875) * aspectX, 0.230)
                     * waterMask
                     * (1.0 - smoothstep(0.98, 1.0, uv.y));
    float shimmer = 0.50
                  + 0.30 * sin(uv.y * 96.0 + iTime * 0.72 + sin(uv.x * 18.0) * 0.8)
                  + 0.20 * sin(uv.y * 37.0 - iTime * 0.46);
    shimmer = clamp(shimmer, 0.0, 1.0);
    scene += mix(gold, amber, 0.35) * reflection * (0.120 + 0.150 * shimmer);

    float seaLine = gaussian(uv.y - 0.820, 0.085)
                  * smoothstep(0.12, 0.95, uv.x);
    float seaWave = 0.5 + 0.5 * sin(uv.x * 52.0 + uv.y * 18.0 + iTime * 0.44);
    scene += mix(amber, coral, 0.40) * seaLine * seaWave * 0.058;

    // Small glints on the reflection path. Sparse enough to avoid a particle
    // field, but visible when the terminal is idle.
    float glints = sparkle(uv * vec2(1.7, 1.0) + vec2(iTime * 0.002, 0.0),
                           78.0, 0.987, 1.05);
    scene += vec3(1.00, 0.92, 0.58) * glints * reflection * 0.280;

    // A faint green-gold leaf shimmer near the paopu palm canopy on the right.
    float leafMask = smoothstep(0.55, 0.86, uv.x)
                   * (1.0 - smoothstep(0.98, 1.0, uv.x))
                   * smoothstep(0.30, 0.46, uv.y)
                   * (1.0 - smoothstep(0.62, 0.78, uv.y));
    float leafNoise = noise(vec2(uv.x * 18.0 + iTime * 0.030, uv.y * 28.0));
    float leafBreath = 0.78 + 0.22 * sin(iTime * 0.24);
    scene += leaf * smoothstep(0.52, 0.90, leafNoise) * leafMask * leafBreath * 0.090;

    // Keep the left treehouse mass and corners tucked back for terminal text.
    float leftShade = (1.0 - smoothstep(0.22, 0.56, uv.x))
                    * smoothstep(0.34, 0.96, uv.y);
    float edgeShade = smoothstep(0.16, 0.58, abs(uv.x - 0.5));
    scene -= deep * (leftShade * 0.24 + edgeShade * 0.10);

    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.08, 0.52, lum);
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * textBloom;

    vec3 col = term.rgb + scene * bgMask * sceneOpacity + bloom;
    fragColor = vec4(col, 1.0);
}
