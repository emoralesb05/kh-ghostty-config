// Ghostty custom shader — "Twilight Town"
// The clock tower at endless sunset, rendered as a layered scene with
// atmospheric perspective so the tower feels grounded in the world rather
// than floating as a cutout against the sky.
//
// Layer order (back → front, painted in this order):
//   1. Sepia sky gradient
//   2. Painterly cloud striations (slow horizontal drift)
//   3. Sun + atmospheric warm wash
//   4. Mountain silhouettes — hazy purple, atmospheric perspective
//   5. Distant town silhouette — medium haze
//   6. Tower silhouette — dark warm purple-brown (NOT pure black)
//   7. Clock face glow + rotating hour/minute hands
//   8. Foreground rooftops — nearly black (closest to viewer)
//   9. Subtle horizon atmospheric haze (unifying wash)

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

// Distance from point p to segment a → b
float segDist(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

// Soft horizontal-line mask: 1 below the height curve, 0 above, with a soft
// transition controlled by `softness`. Use this for layer silhouettes.
float horizonBand(float uvY, float height, float softness) {
    return 1.0 - smoothstep(height - softness, height + softness, uvY);
}

// Soft axis-aligned rectangle mask
float rectMask(vec2 uv, float xMin, float xMax, float yMin, float yMax, float soft) {
    float sx = smoothstep(xMin - soft, xMin + soft, uv.x)
             * (1.0 - smoothstep(xMax - soft, xMax + soft, uv.x));
    float sy = smoothstep(yMin - soft, yMin + soft, uv.y)
             * (1.0 - smoothstep(yMax - soft, yMax + soft, uv.y));
    return sx * sy;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    uv.y = 1.0 - uv.y;  // y=0 bottom (consistent with destiny-islands)
    vec2 aspectScale = vec2(iResolution.x / iResolution.y, 1.0);

    // ── Sky gradient ──
    // Bright orange-pink near horizon, deepening through coral/magenta to
    // dark sienna at the top.
    vec3 skyHorizon = vec3(0.180, 0.085, 0.035);
    vec3 skyMid     = vec3(0.130, 0.055, 0.045);
    vec3 skyUpper   = vec3(0.075, 0.030, 0.060);
    vec3 skyTop     = vec3(0.030, 0.015, 0.045);

    vec3 sky = mix(skyHorizon, skyMid,   smoothstep(0.05, 0.40, uv.y));
    sky      = mix(sky,        skyUpper, smoothstep(0.40, 0.70, uv.y));
    sky      = mix(sky,        skyTop,   smoothstep(0.70, 1.00, uv.y));

    // ── Painterly cloud striations ──
    // Two horizontal bands of soft warm cloud drifting at different speeds.
    // Use 2D noise stretched horizontally to feel like wisps rather than dots.
    float cloud1 = noise(vec2(uv.x * 5.0 + iTime * 0.020, uv.y * 35.0));
    float cloud2 = noise(vec2(uv.x * 7.0 - iTime * 0.013, uv.y * 22.0));

    float cloudBand1 = smoothstep(0.55, 0.85, cloud1)
                     * smoothstep(0.40, 0.50, uv.y)
                     * (1.0 - smoothstep(0.50, 0.62, uv.y));
    float cloudBand2 = smoothstep(0.55, 0.85, cloud2)
                     * smoothstep(0.58, 0.68, uv.y)
                     * (1.0 - smoothstep(0.68, 0.82, uv.y));

    sky += vec3(0.085, 0.030, 0.040) * cloudBand1;   // warm pink
    sky += vec3(0.060, 0.025, 0.055) * cloudBand2;   // cooler lavender

    // ── Sun ──
    // Behind and to the right of the tower. Smaller and dimmer than DI's sun.
    vec2  sunPos        = vec2(0.66, 0.30);
    vec2  sunDelta      = (uv - sunPos) * aspectScale;
    float sunDistAspect = length(sunDelta);

    float atmosphere = exp(-pow(sunDistAspect / 0.32, 2.0));
    sky += vec3(0.55, 0.28, 0.06) * atmosphere * 0.35;

    float sunCore  = exp(-pow(sunDistAspect / 0.026, 2.0)) * 0.50;
    float sunOuter = exp(-pow(sunDistAspect / 0.065, 2.0)) * 0.20;
    float sunPulse = 0.85 + 0.15 * sin(iTime * 0.32);
    vec3  sunCol   = vec3(1.00, 0.82, 0.40);
    sky += sunCol * sunPulse * (sunCore + sunOuter);

    vec3 backdrop = sky;

    // ── Mountains (back-most layer) ──
    // Soft layered silhouette spanning the lower-mid portion. Color is hazy
    // purple-brown — atmospheric perspective: the mountains pick up some of
    // the sky color rather than reading as pure black.
    float mountainHeight = 0.21
        + 0.045 * sin(uv.x * 4.2 + 0.3)
        + 0.025 * sin(uv.x * 9.5 + 1.7)
        + 0.015 * sin(uv.x * 18.7 - 2.1);
    float mountainMask = horizonBand(uv.y, mountainHeight, 0.012);
    vec3  mountainCol  = vec3(0.075, 0.040, 0.075);
    backdrop = mix(backdrop, mountainCol, mountainMask);

    // ── Distant town silhouette ──
    // Slightly more defined than mountains, lower haze. Sits between mountains
    // and the tower in depth.
    float distantTown = 0.115
        + 0.030 * sin(uv.x * 18.0 + 0.3)
        + 0.020 * sin(uv.x * 45.0 - 1.7)
        + 0.012 * sin(uv.x * 90.0);
    float distantTownMask = horizonBand(uv.y, distantTown, 0.005);
    vec3  distantTownCol  = vec3(0.045, 0.020, 0.040);
    backdrop = mix(backdrop, distantTownCol, distantTownMask);

    // ── Clock tower silhouette ──
    // Multi-tier: wider station base, narrower body, slightly tapered upper
    // section, peaked roof. Tower color is dark warm purple — picks up a
    // touch of sunset warmth so it doesn't read as a flat cutout.
    const float towerCX     = 0.36;
    const float yBase       = 0.08;     // bottom of station base
    const float yBaseTop    = 0.22;     // top of station base
    const float yBodyTop    = 0.62;     // top of main body
    const float yUpperTop   = 0.70;     // top of upper tier
    const float yPeak       = 0.82;     // top of pyramid roof

    float baseHalfW   = 0.062;
    float bodyHalfW   = 0.038;
    float upperHalfW  = 0.032;

    float baseMask  = rectMask(uv, towerCX - baseHalfW,  towerCX + baseHalfW,
                                   yBase, yBaseTop, 0.0015);
    float bodyMask  = rectMask(uv, towerCX - bodyHalfW,  towerCX + bodyHalfW,
                                   yBaseTop, yBodyTop, 0.0015);
    float upperMask = rectMask(uv, towerCX - upperHalfW, towerCX + upperHalfW,
                                   yBodyTop, yUpperTop, 0.0015);

    // Pyramid roof: at height y, half-width tapers from upperHalfW + 0.005 to 0
    float roofProgress = clamp((uv.y - yUpperTop) / (yPeak - yUpperTop), 0.0, 1.0);
    float roofHalfW    = mix(upperHalfW + 0.006, 0.0, roofProgress);
    float roofMask     = rectMask(uv, towerCX - roofHalfW, towerCX + roofHalfW,
                                      yUpperTop, yPeak, 0.0015);

    float towerMask = max(max(baseMask, bodyMask), max(upperMask, roofMask));
    vec3  towerCol  = vec3(0.022, 0.012, 0.025);    // dark warm purple-brown
    backdrop = mix(backdrop, towerCol, towerMask);

    // ── Clock face on the main body ──
    // Ornate-but-soft clock face. Every element is built from Gaussian
    // falloffs (no hard edges) so the overall look stays painterly/diffuse
    // — but with enough internal structure to read as a real ornate clock:
    // outer rim, inner concentric ring, 12 hour markers, a center hub, and
    // two slowly rotating hands.
    vec2  clockPos = vec2(towerCX, 0.50);
    vec2  cs       = (uv - clockPos) * aspectScale;
    float cd       = length(cs);

    const float clockR      = 0.022;
    const float clockInnerR = 0.013;

    // Soft glow layers
    float core = exp(-pow(cd / 0.014, 2.0));                      // diffuse bright center
    float rim  = exp(-pow((cd - clockR) / 0.0050, 2.0));          // soft outer ring
    float halo = exp(-pow(cd / 0.055, 2.0));                      // wide ambient bleed

    // Inner concentric ring — adds the "two-rim" feel of an astronomical clock
    float innerRing = exp(-pow((cd - clockInnerR) / 0.0018, 2.0));

    // Hour markers — 12 soft dots just inside the outer rim, evenly spaced
    float angle      = atan(cs.y, cs.x);
    float step12     = 6.2832 / 12.0;
    float angMod     = mod(angle + 6.2832, step12);
    float distToMark = min(angMod, step12 - angMod);
    float markAngular = exp(-pow(distToMark / 0.045, 2.0));
    float markRadial  = exp(-pow((cd - (clockR - 0.0035)) / 0.0018, 2.0));
    float markers     = markAngular * markRadial;

    // Center hub where the hands meet
    float hub = exp(-pow(cd / 0.0028, 2.0));

    // Hands: hour (60s/rev), minute (6s/rev). Start at 12 o'clock.
    float hourAng = -1.5708 - iTime * (6.2832 / 60.0);
    float minAng  = -1.5708 - iTime * (6.2832 / 6.0);
    vec2  hourEnd = vec2(cos(hourAng), sin(hourAng)) * 0.012;
    vec2  minEnd  = vec2(cos(minAng),  sin(minAng))  * 0.018;

    float hourD = segDist(cs, vec2(0.0), hourEnd);
    float minD  = segDist(cs, vec2(0.0), minEnd);
    // Gaussian-falloff hands so they read as suggestive lines, not sharp marks.
    float hourMask = exp(-pow(hourD / 0.0020, 2.0));
    float minMask  = exp(-pow(minD  / 0.0015, 2.0));

    // Hands soft-clipped inside the face
    float handsClip = exp(-pow(cd / clockR, 4.0));
    float handsMask = max(hourMask, minMask) * handsClip * 0.65;

    vec3 clockCol = vec3(0.92, 0.72, 0.34);
    backdrop += clockCol * (
          core       * 0.13
        + rim        * 0.30
        + halo       * 0.10
        + innerRing  * 0.28
        + markers    * 0.32
        + hub        * 0.45
    );
    backdrop = mix(backdrop, vec3(0.0), handsMask);

    // ── Foreground rooftops (closest to viewer) ──
    // Nearly black silhouette in front of the tower base. Mix of low rolling
    // rooftops and occasional triangular peaks to feel like brick rooftops.
    float fgRolling = 0.075
        + 0.020 * sin(uv.x * 24.0 + 1.7)
        + 0.012 * sin(uv.x * 67.0);
    // Triangular peaks suggesting individual roof gables
    float fgPeaks = 0.08 + 0.040 * abs(sin(uv.x * 11.0 + 0.4));
    float fgHeight = max(fgRolling, fgPeaks * 0.55 + fgRolling * 0.45);
    float fgMask = horizonBand(uv.y, fgHeight, 0.003);
    vec3  fgCol = vec3(0.005, 0.002, 0.008);
    backdrop = mix(backdrop, fgCol, fgMask);

    // ── Atmospheric horizon haze (unifying wash) ──
    // Very subtle warm wash centered on the horizon-ish band, blending
    // distant elements toward the sky color so the scene feels cohesive.
    float horizonHaze = exp(-pow((uv.y - 0.18) * 6.0, 2.0));
    backdrop += vec3(0.060, 0.025, 0.012) * horizonHaze * 0.18;

    // ── Compositing (matches dive-to-heart) ──
    float lum    = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);
    vec3  bloom  = term.rgb * smoothstep(0.45, 1.0, lum) * 0.35;

    vec3 col = term.rgb + backdrop * bgMask + bloom;
    fragColor = vec4(col, 1.0);
}
