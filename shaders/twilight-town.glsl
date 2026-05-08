// Ghostty custom shader — "Twilight Town"
// Sepia/orange drift, faint horizontal light streaks evoking the train line,
// and a clock-tower vignette in the upper-right.

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

// A single thin horizontal streak passing left → right across the image.
// `yPos` is the vertical position [0..1], `phase` offsets timing,
// `speed` controls travel time, `thickness` controls vertical width.
float streak(vec2 uv, float yPos, float phase, float speed, float thickness) {
    // Streak head moves from -0.15 → 1.15 over `speed` seconds, then resets.
    float t = fract((iTime + phase) / speed);
    float headX = mix(-0.15, 1.15, t);

    // Vertical falloff — the streak only exists in a thin band near yPos.
    float vy = exp(-pow((uv.y - yPos) / thickness, 2.0));

    // Horizontal trail behind the head.
    float dx = headX - uv.x;
    float trail = smoothstep(0.18, 0.0, dx) * step(0.0, dx);

    // A brighter core right at the head.
    float head = exp(-pow(dx / 0.012, 2.0));

    return vy * (trail * 0.55 + head);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    // --- Sepia drift: warm low-frequency noise ---
    vec2 driftP = vec2(uv.x * 2.0 + iTime * 0.015, uv.y * 1.6 + iTime * 0.008);
    float drift = noise(driftP) * 0.6 + noise(driftP * 2.3) * 0.4;
    drift = drift * 0.5 + 0.25;  // 0.25..0.75

    // Sepia gradient: warm orange at the bottom → dusty rose mid → muted indigo top
    vec3 sepiaLow = vec3(0.085, 0.045, 0.020);
    vec3 sepiaMid = vec3(0.060, 0.035, 0.025);
    vec3 sepiaTop = vec3(0.030, 0.020, 0.035);
    vec3 sky = mix(sepiaLow, sepiaMid, smoothstep(0.0, 0.55, uv.y));
    sky = mix(sky, sepiaTop, smoothstep(0.55, 1.0, uv.y));
    sky *= (0.7 + 0.6 * drift);

    // --- Horizontal light streaks (the train) ---
    // A handful of streaks at slightly different heights/speeds so they don't sync up.
    float s = 0.0;
    s += streak(uv, 0.32, 0.0,  9.0, 0.012);
    s += streak(uv, 0.31, 4.7,  11.0, 0.010);
    s += streak(uv, 0.34, 9.2,  13.5, 0.014);
    s += streak(uv, 0.30, 13.8, 17.0, 0.008);
    vec3 streakCol = vec3(0.95, 0.75, 0.45);  // warm amber
    sky += streakCol * s * 0.55;

    // --- Clock-tower vignette in the upper-right ---
    // A soft warm glow centered around (0.86, 0.78) with a faint inner ring.
    vec2 c = vec2(0.86, 0.78);
    float d = distance(uv, c);
    float glow = exp(-pow(d * 7.0, 2.0)) * 0.55;
    // A subtle ring suggesting the clock face
    float ring = smoothstep(0.060, 0.050, abs(d - 0.055)) * 0.20;
    vec3 towerCol = vec3(1.00, 0.82, 0.55);
    sky += towerCol * (glow + ring);

    // --- Compositing (matches dive-to-heart) ---
    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);

    // Bloom on bright text in a warm tone
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * 0.42;

    vec3 col = term.rgb + sky * bgMask + bloom;
    fragColor = vec4(col, 1.0);
}
