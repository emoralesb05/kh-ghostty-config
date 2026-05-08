// Ghostty custom shader - "Twilight Town"
// Subtle animated sunset/clock layer for the Twilight Town background image.
// The bitmap carries the tower; this shader adds atmosphere and clock life.

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

vec2 coverLeftImagePos(vec2 imageUv, float imageAspect, float screenAspect) {
    if (screenAspect > imageAspect) {
        float scaledHeight = screenAspect / imageAspect;
        return vec2(imageUv.x, 0.5 + (imageUv.y - 0.5) * scaledHeight);
    }

    float scaledWidth = imageAspect / screenAspect;
    return vec2(imageUv.x * scaledWidth, imageUv.y);
}

float coverScaleToScreenHeight(float imageAspect, float screenAspect) {
    if (screenAspect > imageAspect) {
        return screenAspect / imageAspect;
    }
    return 1.0;
}

float sparkle(vec2 uv, float density, float threshold, float speed) {
    vec2 grid = floor(uv * density);
    vec2 cell = fract(uv * density) - 0.5;
    float h = hash(grid);

    float d = length(cell);
    float core = 1.0 - smoothstep(0.025, 0.075, d);
    float glow = (1.0 - smoothstep(0.075, 0.240, d)) * 0.22;
    float twinkle = 0.45 + 0.55 * sin(iTime * speed + h * 6.2831853);
    return (core + glow) * twinkle * step(threshold, h);
}

float softMote(vec2 p, float size) {
    float d = length(p);
    float core = 1.0 - smoothstep(size * 0.20, size * 0.72, d);
    float glow = (1.0 - smoothstep(size * 0.72, size * 2.8, d)) * 0.25;
    return core + glow;
}

float segDist(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    const float sceneOpacity = 0.36;
    const float textBloom = 0.21;

    float screenAspect = iResolution.x / iResolution.y;
    vec2 aspect = vec2(screenAspect, 1.0);
    vec3 amber = vec3(1.00, 0.55, 0.16);
    vec3 gold = vec3(1.00, 0.76, 0.28);
    vec3 rose = vec3(0.76, 0.22, 0.30);
    vec3 violet = vec3(0.12, 0.05, 0.16);

    vec3 scene = vec3(0.0);

    // Slow painterly cloud movement across the sunset sky.
    float cloudA = noise(vec2(uv.x * 3.6 + iTime * 0.012, uv.y * 12.0));
    float cloudB = noise(vec2(uv.x * 5.2 - iTime * 0.008, uv.y * 18.0));
    float skyMask = 1.0 - smoothstep(0.54, 0.76, uv.y);
    float cloudBand = smoothstep(0.50, 0.86, cloudA * 0.65 + cloudB * 0.35)
                    * skyMask;
    scene += mix(rose, amber, smoothstep(0.20, 0.82, uv.x)) * cloudBand * 0.100;

    // Warm horizon breathing, strongest toward the open sunset on the right.
    float horizon = gaussian(uv.y - 0.56, 0.105)
                  * smoothstep(0.34, 0.95, uv.x);
    float sunsetPulse = 0.86 + 0.14 * sin(iTime * 0.18);
    scene += amber * horizon * sunsetPulse * 0.150;

    // Broad golden rays through the open sky, moving slowly enough to feel
    // atmospheric rather than like a visible scanline effect.
    vec2 sunPos = vec2(0.47, 0.49);
    vec2 rayP = (uv - sunPos) * aspect;
    float rayAngle = atan(rayP.y, rayP.x);
    float rayDist = length(rayP);
    float rays = 0.5 + 0.5 * sin(rayAngle * 10.0 + iTime * 0.22 + rayDist * 3.0);
    rays = smoothstep(0.62, 0.95, rays);
    float rayMask = smoothstep(0.22, 0.86, uv.x)
                  * (1.0 - smoothstep(0.62, 0.94, uv.y))
                  * smoothstep(0.08, 0.34, rayDist);
    scene += mix(gold, amber, 0.45) * rays * rayMask * 0.090;

    // Warm dust drifting through the sunset, mostly above the town and tower.
    for (int i = 0; i < 14; i++) {
        float fi = float(i);
        float speed = 0.003 + 0.006 * hash(vec2(fi, 4.7));
        float my = 0.16 + fract(hash(vec2(fi, 9.2)) - iTime * speed) * 0.46;
        float mx = 0.08 + hash(vec2(fi, 11.1)) * 0.64
                 + 0.015 * sin(iTime * 0.10 + fi * 1.6);
        vec2 mp = (uv - vec2(mx, my)) * aspect;
        float mote = softMote(mp, 0.0045 + 0.0060 * hash(vec2(fi, 14.3)));
        float dustMask = smoothstep(0.04, 0.26, uv.x)
                       * (1.0 - smoothstep(0.62, 0.82, uv.y));
        float dustFade = 0.70 + 0.30 * sin(iTime * 0.24 + fi * 2.3);
        scene += mix(gold, amber, 0.42) * mote * dustMask * dustFade * 0.070;
    }

    // Heat-haze bands over the tram/town horizon. The effect is color-only;
    // Ghostty exposes the composed terminal texture, so we avoid warping text.
    float hazeBand = gaussian(uv.y - 0.615, 0.050)
                   * smoothstep(0.18, 0.88, uv.x);
    float haze = sin(uv.x * 58.0 + iTime * 0.70)
               + 0.55 * sin(uv.x * 113.0 - iTime * 0.46);
    scene += mix(rose, gold, 0.38) * hazeBand * haze * 0.040;

    float tramLine = gaussian(uv.y - 0.682, 0.030)
                   * smoothstep(0.28, 0.92, uv.x);
    float railGlint = 0.5 + 0.5 * sin(uv.x * 122.0 + uv.y * 16.0 - iTime * 0.62);
    scene += gold * tramLine * smoothstep(0.72, 0.98, railGlint) * 0.040;

    // Clock coordinates are in the source image, then remapped to match
    // Ghostty's background-image-fit=cover, position=center-left placement.
    const float imageAspect = 1586.0 / 992.0;
    vec2 clockPos = coverLeftImagePos(vec2(0.206, 0.470), imageAspect, screenAspect);
    float clockScale = coverScaleToScreenHeight(imageAspect, screenAspect);
    vec2 clockP = (uv - clockPos) * aspect;
    float clockTilt = -0.050;
    vec2 cs = vec2(
        clockP.x * cos(clockTilt) - clockP.y * sin(clockTilt),
        clockP.x * sin(clockTilt) + clockP.y * cos(clockTilt)
    );
    cs.y *= 1.08;
    float cd = length(cs);
    float clockPulse = 0.88 + 0.12 * sin(iTime * 0.32);
    float clockFace = gaussian(cd, 0.050 * clockScale);
    float clockRim = gaussian(cd - 0.044 * clockScale, 0.0030 * clockScale);
    float clockAngle = atan(cs.y, cs.x);
    float clockTicks = smoothstep(0.82, 0.99, 0.5 + 0.5 * cos(clockAngle * 12.0));
    scene += gold * clockFace * clockPulse * 0.105;
    scene += vec3(1.00, 0.86, 0.42) * clockRim * clockTicks * clockPulse * 0.055;

    float sweepAng = -1.5708 + iTime * 0.42;
    vec2 sweepTip = vec2(cos(sweepAng), sin(sweepAng)) * 0.036 * clockScale;
    float rimSweep = gaussian(length(cs - sweepTip), 0.0050 * clockScale);
    scene += vec3(1.00, 0.90, 0.48) * rimSweep * clockRim * 0.090;

    float hourAng = -1.5708 - iTime * (6.2831853 / 90.0);
    float minAng = -1.5708 - iTime * (6.2831853 / 18.0);
    vec2 hourEnd = vec2(cos(hourAng), sin(hourAng)) * 0.028 * clockScale;
    vec2 minEnd = vec2(cos(minAng), sin(minAng)) * 0.039 * clockScale;
    float hourHand = gaussian(segDist(cs, vec2(0.0), hourEnd), 0.0023 * clockScale);
    float minHand = gaussian(segDist(cs, vec2(0.0), minEnd), 0.0019 * clockScale);
    float handsClip = gaussian(cd, 0.048 * clockScale);
    scene += vec3(0.18, 0.08, 0.02) * max(hourHand, minHand) * handsClip * 0.085;

    float handTip = gaussian(length(cs - minEnd), 0.0044 * clockScale)
                  + gaussian(length(cs - hourEnd), 0.0038 * clockScale);
    float handGlint = 0.72 + 0.28 * sin(iTime * 1.10);
    scene += vec3(1.00, 0.84, 0.34) * handTip * handsClip * handGlint * 0.075;

    // Sparse town-window twinkles in the lower city. Kept tiny and infrequent
    // so they read as life in the town, not a particle field.
    float townMask = smoothstep(0.62, 0.86, uv.y)
                   * (1.0 - smoothstep(0.96, 1.0, uv.y))
                   * smoothstep(0.18, 0.95, uv.x);
    float windows = sparkle(uv * vec2(1.8, 1.0) + vec2(0.0, iTime * 0.002),
                            68.0, 0.978, 1.15);
    scene += gold * windows * townMask * 0.180;

    float nearWindows = sparkle(uv * vec2(1.5, 1.0) + vec2(iTime * 0.001, 0.0),
                                44.0, 0.986, 0.62);
    scene += mix(gold, amber, 0.30) * nearWindows * townMask * 0.120;

    // Keep edges tucked back for terminal contrast.
    float edgeShade = smoothstep(0.18, 0.58, abs(uv.x - 0.5));
    scene -= violet * edgeShade * 0.12;

    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * textBloom;

    vec3 col = term.rgb + scene * bgMask * sceneOpacity + bloom;
    fragColor = vec4(col, 1.0);
}
