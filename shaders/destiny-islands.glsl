// Ghostty custom shader — "Destiny Islands"
// Inspired by the iconic KH3 ending shot: the bent paopu palm trunk
// crossing the frame at sunset, with the sun a bright disc at the horizon
// and palm fronds drooping in from the top-left corner.
//
// Composition (in y=0-bottom coordinates after the flip below):
//   • Sky gradient — warm at horizon, magenta toward the top
//   • Atmospheric glow — sky brightens radially around the sun
//   • Sun disc — Gaussian-soft bright spot just above the horizon
//   • Sea — dim warm-purple gradient
//   • Sun reflection — vertical bright band on water below the sun
//   • Trunk — thick bent quadratic bezier crossing from upper-right to
//     lower-left, the dominant structural silhouette
//   • Frond drape — 4 thin curved fronds drooping from the top-left
//     corner, framing the upper edge

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Distance from point p to segment a → b
float segDist(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

// Distance from p to a quadratic bezier (a → c → b), polyline-approximated.
float bezierDist(vec2 p, vec2 a, vec2 c, vec2 b) {
    float minD = 1e9;
    vec2 prev = a;
    for (int i = 1; i <= 24; i++) {
        float t = float(i) / 24.0;
        float u = 1.0 - t;
        vec2 curr = u * u * a + 2.0 * u * t * c + t * t * b;
        minD = min(minD, segDist(p, prev, curr));
        prev = curr;
    }
    return minD;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    // Ghostty's UV origin is top-left. Flip y so the rest of this shader can
    // use uv.y = 0 at the bottom (sky high, sea low — the natural mental model).
    uv.y = 1.0 - uv.y;

    const float horizonY = 0.34;
    vec2  sunPos = vec2(0.50, horizonY + 0.045);  // just above horizon

    // Aspect-corrected distance from the sun, so the disc reads as round.
    vec2  sunDelta       = (uv - sunPos) * vec2(iResolution.x / iResolution.y, 1.0);
    float sunDistAspect  = length(sunDelta);

    // ── Sky base gradient ──
    // Warm at the horizon, magenta toward the top. Kept dim so the sun and
    // its glow read as the bright elements.
    vec3 skyHorizon = vec3(0.110, 0.045, 0.025);
    vec3 skyMid     = vec3(0.075, 0.025, 0.030);
    vec3 skyTop     = vec3(0.030, 0.010, 0.045);

    float skyT = clamp((uv.y - horizonY) / (1.0 - horizonY), 0.0, 1.0);
    vec3 sky = mix(skyHorizon, skyMid, smoothstep(0.0, 0.40, skyT));
    sky      = mix(sky,        skyTop, smoothstep(0.40, 1.00, skyT));

    // ── Atmospheric glow around the sun ──
    // The sky brightens radially toward the sun. Larger falloff than the disc
    // so it bleeds into a soft warm halo across most of the upper sky.
    float atmosphere = exp(-pow(sunDistAspect / 0.32, 2.0));
    vec3  atmCol     = vec3(0.55, 0.30, 0.10);   // warm orange wash
    sky += atmCol * atmosphere * 0.55;

    // ── Sea base gradient ──
    vec3 seaTop  = vec3(0.060, 0.020, 0.030);    // just below horizon
    vec3 seaDeep = vec3(0.012, 0.005, 0.018);    // far below, near-black
    float seaT = clamp((horizonY - uv.y) / horizonY, 0.0, 1.0);
    vec3 sea = mix(seaTop, seaDeep, smoothstep(0.0, 0.85, seaT));

    // ── Sun reflection on the water ──
    // Vertical bright band centered horizontally on the sun, brightest at the
    // horizon, fading toward the bottom of the screen, with subtle shimmer.
    float dx               = abs(uv.x - sunPos.x);
    float reflectionWidth  = exp(-pow(dx / 0.080, 2.0));
    float reflectionVert   = smoothstep(0.04, horizonY - 0.005, uv.y);
    float shimmer = 0.78
                  + 0.16 * sin(uv.y * 55.0 + iTime * 0.40)
                  + 0.10 * sin(uv.y * 22.0 - iTime * 0.65);
    float reflection = reflectionWidth * reflectionVert * shimmer;
    sea += vec3(0.95, 0.62, 0.18) * reflection * 0.65;

    // Soft horizon blend (sky ↔ sea) — replaces a hard step() so the boundary
    // doesn't read as a single sharp line.
    float horizonBlend = 1.0 - smoothstep(horizonY - 0.014, horizonY + 0.014, uv.y);
    vec3  backdrop = mix(sky, sea, horizonBlend);

    // Atmospheric haze right at the horizon — a thin warm band that sits in
    // both sky and sea, simulating the way distant atmosphere fogs out the
    // sea/sky boundary in real sunset photographs.
    float horizonHaze = exp(-pow((uv.y - horizonY) * 55.0, 2.0));
    backdrop += vec3(0.18, 0.10, 0.04) * horizonHaze * 0.40;

    // ── Sun disc ──
    // Gaussian core + soft halo. Gentle pulse so it feels alive.
    // Brightness toned down ~30% from v5 — the disc is still clearly the
    // brightest element but no longer dominates against text.
    float sunCore  = exp(-pow(sunDistAspect / 0.038, 2.0)) * 0.68;
    float sunOuter = exp(-pow(sunDistAspect / 0.090, 2.0)) * 0.32;
    float sunPulse = 0.85 + 0.15 * sin(iTime * 0.40);
    vec3  sunCol   = vec3(1.00, 0.90, 0.55);
    backdrop += sunCol * sunPulse * (sunCore + sunOuter);

    // ── Bent paopu trunk (the hero element) ──
    // Thick quadratic bezier from off-screen upper-right curving down through
    // the middle of the frame and exiting off-screen lower-left. This is the
    // dominant silhouette — it claims the lower-mid portion of the frame.
    vec2 trunkA = vec2(1.10, 0.58);    // off-screen upper-right entry
    vec2 trunkC = vec2(0.55, 0.36);    // control: bows down/left
    vec2 trunkB = vec2(-0.05, 0.30);   // off-screen lower-left exit

    float trunkD = bezierDist(uv, trunkA, trunkC, trunkB);
    // Thick — visible behind the sun. Soft edge so it doesn't alias.
    float trunkMask = smoothstep(0.055, 0.040, trunkD);

    // Pure-black silhouette
    backdrop = mix(backdrop, vec3(0.0), trunkMask);

    // ── Top-left frond drape ──
    // 5 leaf-shaped fronds drooping from the upper-left corner. Each is an
    // elongated silhouette (wider in the middle, tapering at both ends) with
    // subtle internal banding to hint at leaflet ridges — so they read as
    // *leaves*, not as twigs.
    float frondMask = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);

        // Anchor near the top-left, with slight horizontal scatter.
        vec2 base = vec2(-0.04 + fi * 0.022, 1.04);

        // Each frond drapes downward at an angle from "almost straight down"
        // to "down-and-right" — mimicking the way a palm crown hangs from
        // off-screen above. Subtle sway via sin(iTime + fi).
        float angle    = -1.50 + fi * 0.30 + 0.05 * sin(iTime * 0.32 + fi);
        float frondLen = 0.22  + 0.05 * hash(vec2(fi, 7.7));
        vec2  tip      = base + vec2(cos(angle), sin(angle)) * frondLen;

        float halfWidth = 0.022 + 0.006 * hash(vec2(fi, 11.3));

        // Local frame along the frond
        vec2 dir   = tip - base;
        vec2 dirN  = dir / frondLen;
        vec2 perpN = vec2(-dirN.y, dirN.x);

        vec2  d     = uv - base;
        float along = dot(d, dirN);
        float perpD = abs(dot(d, perpN));

        float t            = clamp(along / frondLen, 0.0, 1.0);
        float withinLength = step(0.0, along) * step(along, frondLen);

        // Width at this position: pow(sin) keeps the leaf "fat" through the
        // middle and tapered to nothing at both ends.
        float widthCurve        = pow(sin(t * 3.14159), 0.45);
        float currentHalfWidth  = halfWidth * widthCurve;

        // Faint leaflet ridges — small modulation along the leaf so it's not
        // a featureless oval. (10–15% amplitude only.)
        float ridges = 0.88 + 0.12 * sin(along * 110.0 + fi * 2.0);

        float singleFrond = smoothstep(currentHalfWidth, currentHalfWidth - 0.003, perpD)
                          * withinLength
                          * ridges;
        frondMask = max(frondMask, singleFrond);
    }
    backdrop = mix(backdrop, vec3(0.0), frondMask);

    // ── Compositing (matches dive-to-heart) ──
    float lum    = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);
    vec3  bloom  = term.rgb * smoothstep(0.45, 1.0, lum) * 0.35;

    vec3 col = term.rgb + backdrop * bgMask + bloom;
    fragColor = vec4(col, 1.0);
}
