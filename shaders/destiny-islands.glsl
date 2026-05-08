// Ghostty custom shader — "Destiny Islands"
// Warm sunset gradient with soft horizon glow and palm-frond silhouettes
// drifting across the bottom. Tuned to be subtle behind text.

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

// One palm tree silhouette anchored at base point (cx, 0) on the screen.
// Returns a [0,1] mask: 1 = inside the silhouette, 0 = outside.
//   cx        horizontal center
//   phase     animation offset for the sway
//   scale     overall size (in p-coordinates; smaller = bigger tree)
//   dirSign   +1 fronds lean right, -1 lean left
float palm(vec2 p, float cx, float phase, float scale, float dirSign) {
    // Gentle sway
    float sway = 0.025 * sin(iTime * 0.6 + phase);
    vec2 q = vec2((p.x - cx - sway) * dirSign, p.y) / scale;

    // Trunk: thin vertical strip from q.y=0 up to q.y=0.20
    float trunkX = 1.0 - smoothstep(0.0, 0.020, abs(q.x));
    float trunkY = smoothstep(-0.02, 0.0, q.y) * (1.0 - smoothstep(0.18, 0.22, q.y));
    float trunk = trunkX * trunkY;

    // Fronds: 5 arcs emerging from (0, 0.20), fanning up and outward.
    // For each frond, rotate q so its "along" axis points outward, then
    // draw a thin curved arc.
    vec2 fp = q - vec2(0.0, 0.20);
    float fronds = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        // Angle from straight-up (0) outward; mix of leftward and rightward
        float ang = (fi - 2.0) * 0.55;     // -1.10, -0.55, 0.0, 0.55, 1.10 rad
        float c = cos(ang);
        float s = sin(ang);
        // Rotate so frond's length axis is along r.x
        vec2 r = vec2(s * fp.x + c * fp.y, c * fp.x - s * fp.y);

        // Frond extends from r.x = 0 to r.x = 0.30, with thickness narrowing
        float along = clamp(r.x / 0.30, 0.0, 1.0);
        float thickness = mix(0.022, 0.004, along);
        // Slight curve in r.y so the frond bows down toward its tip
        float curve = -0.05 * along * along;
        float arc = (1.0 - smoothstep(0.0, thickness, abs(r.y - curve)))
                  * smoothstep(-0.01, 0.02, r.x)
                  * (1.0 - smoothstep(0.28, 0.32, r.x));
        fronds = max(fronds, arc);
    }

    return clamp(trunk + fronds, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    vec2 p = uv * vec2(iResolution.x / iResolution.y, 1.0);

    // --- Sunset sky gradient ---
    // Gold near the horizon → coral mid → deep magenta at top.
    vec3 skyTop = vec3(0.060, 0.020, 0.060);
    vec3 skyMid = vec3(0.090, 0.040, 0.050);
    vec3 skyLow = vec3(0.120, 0.060, 0.030);
    vec3 sky = mix(skyLow, skyMid, smoothstep(0.10, 0.55, uv.y));
    sky = mix(sky, skyTop, smoothstep(0.55, 1.00, uv.y));

    // Soft horizon glow — warm band centered around uv.y ≈ 0.22
    float horizon = exp(-pow((uv.y - 0.22) * 14.0, 2.0));
    sky += vec3(0.090, 0.050, 0.020) * horizon;

    // Subtle drifting cloud band, very low contrast
    float cloud = noise(vec2(uv.x * 4.0 + iTime * 0.02, uv.y * 8.0));
    cloud = smoothstep(0.55, 0.95, cloud)
          * smoothstep(0.20, 0.35, uv.y)
          * (1.0 - smoothstep(0.35, 0.55, uv.y));
    sky += vec3(0.040, 0.025, 0.012) * cloud;

    // --- Palm fronds along the bottom ---
    // Tree positions are in p-coordinates (aspect-corrected x).
    float fronds = 0.0;
    fronds = max(fronds, palm(p, 0.18, 0.0,  0.55,  1.0));
    fronds = max(fronds, palm(p, 0.62, 1.7,  0.65, -1.0));
    fronds = max(fronds, palm(p, 1.05, 3.4,  0.50,  1.0));
    // Palms are silhouettes — pull the sky toward near-black where they sit.
    vec3 palmCol = vec3(0.012, 0.005, 0.020);
    sky = mix(sky, palmCol, fronds);

    // --- Compositing (matches dive-to-heart) ---
    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);

    // Warm bloom on bright text — sunset light catching the letters
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * 0.40;

    vec3 col = term.rgb + sky * bgMask + bloom;
    fragColor = vec4(col, 1.0);
}
