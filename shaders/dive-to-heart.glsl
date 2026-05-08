// Ghostty custom shader — "Dive to the Heart"
// Drifting starfield + heart-of-light bloom. Tuned to be visible
// even with high background-opacity.

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float starLayer(vec2 uv, float density, float speed, float threshold) {
    vec2 grid = floor(uv * density);
    vec2 cell = fract(uv * density) - 0.5;
    float h = hash(grid);
    if (h < threshold) return 0.0;
    float t = iTime * speed + h * 6.2831;
    float twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(t));
    float d = length(cell);
    float core = smoothstep(0.08, 0.0, d);
    float halo = smoothstep(0.30, 0.0, d) * 0.25;
    return (core + halo) * twinkle;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 term = texture(iChannel0, uv);

    vec2 p = uv * vec2(iResolution.x / iResolution.y, 1.0);

    // Three layers of stars at different scales/speeds
    float s1 = starLayer(p + vec2(iTime * 0.010, 0.0),  60.0, 1.4, 0.990);
    float s2 = starLayer(p * 1.7 + vec2(0.0, iTime * 0.006), 110.0, 2.0, 0.993);
    float s3 = starLayer(p * 2.6 + vec2(iTime * 0.004, iTime * 0.002), 180.0, 2.6, 0.996);

    vec3 warm = vec3(1.0, 0.85, 0.55);   // gold
    vec3 cool = vec3(0.55, 0.75, 1.0);   // sky-blue
    vec3 starCol = mix(cool, warm, hash(floor(p * 50.0)));

    // Subtle nebula gradient (deeper blue at top → indigo at bottom)
    vec3 nebula = mix(vec3(0.005, 0.010, 0.030),
                      vec3(0.020, 0.012, 0.045), uv.y);

    vec3 sky = nebula + starCol * (s1 + s2 + s3) * 1.6;

    // Detect "background" pixels (low luminance) so stars only show in dark areas
    float lum = dot(term.rgb, vec3(0.299, 0.587, 0.114));
    float bgMask = 1.0 - smoothstep(0.05, 0.25, lum);

    // Heart-of-light bloom on bright text
    vec3 bloom = term.rgb * smoothstep(0.45, 1.0, lum) * 0.45;

    // Compose: overlay stars onto background, keep text crisp + bloomed
    vec3 col = term.rgb + sky * bgMask + bloom;

    fragColor = vec4(col, 1.0);
}
