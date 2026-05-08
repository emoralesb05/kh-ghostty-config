// Ghostty custom shader — "The World That Never Was"
// Pure black background. Occasional vertical neon-pink rain streaks fall from
// the top, fading as they descend. No nebula, no stars. Maximum contrast for
// late-night focus sessions.

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// One column of rain: returns a brightness value [0..1] for this uv if a streak
// is currently passing through this column, else 0. Each column has its own
// random period and length so the rain never feels grid-aligned.
float rainColumn(vec2 uv, float colWidth) {
    float colIdx = floor(uv.x / colWidth);
    float colSeed = hash(vec2(colIdx, 7.13));

    // Per-column timing
    float period = mix(8.0, 22.0, colSeed);            // seconds between drops
    float phase = colSeed * 17.0;                       // initial offset
    float t = mod(iTime + phase, period) / period;     // 0..1 cycle position

    // Only a fraction of cycles produce a visible streak (sparse rain)
    float active = step(0.45, hash(vec2(colIdx, floor((iTime + phase) / period))));
    if (active < 0.5) return 0.0;

    // Streak head moves from above the top edge (y=1.15) down past the bottom (y=-0.15).
    // In Shadertoy/Ghostty UVs y=0 is the bottom, so the head's y *decreases* over time.
    float headY = 1.15 - t * 1.30;

    // The visible trail sits *above* the current head (where the head just was),
    // i.e. at uv.y >= headY. Pixels below the head have already been passed.
    float dy = uv.y - headY;
    if (dy < 0.0) return 0.0;

    // Trail length varies per column
    float length = mix(0.18, 0.45, hash(vec2(colIdx, 3.7)));
    float trail = smoothstep(length, 0.0, dy);

    // Sharp bright head right at dy = 0
    float head = exp(-pow(dy / 0.010, 2.0));

    // Horizontal centering within the column (slightly off-center for variety)
    float colCenter = (colIdx + 0.5 + (colSeed - 0.5) * 0.3) * colWidth;
    float horizFalloff = exp(-pow((uv.x - colCenter) / (colWidth * 0.18), 2.0));

    return horizFalloff * (head + trail * 0.45);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    // Pure black background. No nebula, no ambient light.
    vec3 sky = vec3(0.0);

    // Rain on a few overlapping column scales for depth
    float r = 0.0;
    r += rainColumn(uv, 1.0 / 20.0);
    r += rainColumn(uv + vec2(0.013, 0.0), 1.0 / 32.0) * 0.7;
    r += rainColumn(uv + vec2(0.027, 0.0), 1.0 / 50.0) * 0.5;

    vec3 rainCol = vec3(1.00, 0.18, 0.55);  // neon pink
    sky += rainCol * r;

    // --- Compositing (matches dive-to-heart) ---
    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);

    // Bloom on bright text picks up the pink slightly so text feels lit by the rain
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * 0.35;

    vec3 col = term.rgb + sky * bgMask + bloom;
    fragColor = vec4(col, 1.0);
}
