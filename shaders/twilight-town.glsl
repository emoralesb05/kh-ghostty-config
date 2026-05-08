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

float segDist(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    const float sceneOpacity = 0.32;
    const float textBloom = 0.20;

    vec2 aspect = vec2(iResolution.x / iResolution.y, 1.0);
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
    scene += mix(rose, amber, smoothstep(0.20, 0.82, uv.x)) * cloudBand * 0.080;

    // Warm horizon breathing, strongest toward the open sunset on the right.
    float horizon = gaussian(uv.y - 0.56, 0.105)
                  * smoothstep(0.34, 0.95, uv.x);
    float sunsetPulse = 0.86 + 0.14 * sin(iTime * 0.18);
    scene += amber * horizon * sunsetPulse * 0.120;

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
    scene += mix(gold, amber, 0.45) * rays * rayMask * 0.070;

    // Heat-haze bands over the tram/town horizon. The effect is color-only;
    // Ghostty exposes the composed terminal texture, so we avoid warping text.
    float hazeBand = gaussian(uv.y - 0.615, 0.050)
                   * smoothstep(0.18, 0.88, uv.x);
    float haze = sin(uv.x * 58.0 + iTime * 0.70)
               + 0.55 * sin(uv.x * 113.0 - iTime * 0.46);
    scene += mix(rose, gold, 0.38) * hazeBand * haze * 0.030;

    // The clock face in the generated image sits left of center. Add only a
    // faint pulse and hands so the asset remains the visual source of truth.
    vec2 clockPos = vec2(0.182, 0.438);
    vec2 cs = (uv - clockPos) * aspect;
    float cd = length(cs);
    float clockPulse = 0.88 + 0.12 * sin(iTime * 0.32);
    float clockHalo = gaussian(cd, 0.055);
    float clockRim = gaussian(cd - 0.043, 0.0045);
    scene += gold * (clockHalo * 0.190 + clockRim * 0.280) * clockPulse;

    float hourAng = -1.5708 - iTime * (6.2831853 / 90.0);
    float minAng = -1.5708 - iTime * (6.2831853 / 18.0);
    vec2 hourEnd = vec2(cos(hourAng), sin(hourAng)) * 0.025;
    vec2 minEnd = vec2(cos(minAng), sin(minAng)) * 0.036;
    float hourHand = gaussian(segDist(cs, vec2(0.0), hourEnd), 0.0028);
    float minHand = gaussian(segDist(cs, vec2(0.0), minEnd), 0.0022);
    float handsClip = gaussian(cd, 0.044);
    scene += vec3(0.18, 0.08, 0.02) * max(hourHand, minHand) * handsClip * 0.150;

    // Sparse town-window twinkles in the lower city. Kept tiny and infrequent
    // so they read as life in the town, not a particle field.
    float townMask = smoothstep(0.62, 0.86, uv.y)
                   * (1.0 - smoothstep(0.96, 1.0, uv.y))
                   * smoothstep(0.18, 0.95, uv.x);
    float windows = sparkle(uv * vec2(1.8, 1.0) + vec2(0.0, iTime * 0.002),
                            68.0, 0.978, 1.15);
    scene += gold * windows * townMask * 0.140;

    // Keep edges tucked back for terminal contrast.
    float edgeShade = smoothstep(0.18, 0.58, abs(uv.x - 0.5));
    scene -= violet * edgeShade * 0.12;

    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * textBloom;

    vec3 col = term.rgb + scene * bgMask * sceneOpacity + bloom;
    fragColor = vec4(col, 1.0);
}
