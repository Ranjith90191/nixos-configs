// Combined shader: Infinite Geometric Snow (Using original stable logic)
// + fire-colored cursor trail (orange/red/yellow, no rainbow)

// ============================================================
// --- GLOBAL UTILS ---
// ============================================================

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 2D Rotation matrix for the tumbling shapes
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// ============================================================
// --- GEOMETRIC SNOW ---
// ============================================================

const int   PARTICLE_LAYERS   = 4;
const float PARTICLE_DENSITY  = 16.0;
const float FALL_SPEED        = 0.03; // Matches your original RISE_SPEED
const float DRIFT_AMOUNT      = 0.20;
const float TWINKLE_SPEED     = 1.5;
const float FLAKE_SIZE        = 0.025;
const float FLAKE_BRIGHTNESS  = 0.6;

// SDF for a 4-pointed star
float sdStar(vec2 p, float r) {
    p = abs(p);
    return (p.x + p.y) * 0.7071 - r; 
}

// SDF for a sharp square
float sdSquare(vec2 p, float r) {
    p = abs(p);
    return max(p.x, p.y) - r;
}

// Random washed out (pastel) colors
vec3 flakeColor(vec2 cell, float layer) {
    float seed = hash(cell + layer * 91.7);
    
    // Completely random hue per particle
    float hue = fract(seed * 133.33 + iTime * 0.03); 
    
    // Low saturation (0.35 - 0.5) and high value (0.7 - 0.9) to make them washed out/pastel
    float saturation = 0.35 + 0.15 * fract(seed * 41.2);
    float value      = 0.70 + 0.20 * fract(seed * 73.1);
    
    return hsv2rgb(vec3(hue, saturation, value));
}

float drawFlake(vec2 uv, float layer, out vec3 color) {
    float density = PARTICLE_DENSITY + layer * 6.0;
    vec2 grid = uv * density;

    float speed = FALL_SPEED * (1.0 + layer * 0.6);
    // Minus makes it fall down like snow instead of rising
    grid.y -= iTime * speed * density; 

    vec2 cell = floor(grid);
    vec2 local = fract(grid) - 0.5;

    float seed = hash(cell + layer * 91.7);
    color = vec3(0.0);
    if (seed > 0.12) return 0.0;

    // YOUR ORIGINAL SWAY LOGIC: Perfectly bounded, will never die out
    float sway = sin(iTime * 0.8 + seed * 30.0) * DRIFT_AMOUNT;
    local.x += sway;

    // Rotate the shape as it falls
    local *= rot(iTime * (2.0 + seed * 4.0));

    // Pick a random geometric shape
    float shapeType = fract(seed * 777.77);
    float dist;
    float size = FLAKE_SIZE * (0.6 + 0.4 * seed); // Slight size variance

    if (shapeType < 0.33) {
        dist = sdStar(local, size);
    } else if (shapeType < 0.66) {
        dist = sdSquare(local, size * 0.8);
    } else {
        dist = abs(sdSquare(local, size)) - 0.005; // Hollow square
    }

    float twinkle = 0.5 + 0.5 * sin(iTime * TWINKLE_SPEED + seed * 20.0);
    
    // Sharp anti-aliased edge instead of blurry glow
    float shapeAlpha = 1.0 - smoothstep(0.0, 0.015, dist);

    color = flakeColor(cell, layer);
    return shapeAlpha * twinkle * FLAKE_BRIGHTNESS;
}


// ============================================================
// --- CURSOR TRAIL ---
// ============================================================

float ease(float x) { return pow(1.0 - x, 10.0); }

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b) {
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);
    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);
    return s * sqrt(d);
}

vec2 normalizeCoord(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float blend(float t) {
    float sqr = t * t;
    return sqr / (2.0 * (sqr - t) + 1.0);
}

float antialising(float distance) {
    return 1. - smoothstep(0., normalizeCoord(vec2(2., 2.), 0.).x, distance);
}

float determineStartVertexFactor(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y);
    float condition2 = step(a.x, b.x) * step(b.y, a.y);
    return 1.0 - max(condition1, condition2);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}

const float RAINBOW_SPEED      = 0.35;
const float RAINBOW_HUE_MIN    = 0.0;
const float RAINBOW_HUE_MAX    = 0.75;
const float RAINBOW_SATURATION = 0.75;
const float RAINBOW_VALUE      = 0.55;

vec4 fireColor(float offset) {
    float hue = mix(RAINBOW_HUE_MIN, RAINBOW_HUE_MAX, fract(iTime * RAINBOW_SPEED + offset));
    return vec4(hsv2rgb(vec3(hue, RAINBOW_SATURATION, RAINBOW_VALUE)), 1.0);
}

const float DURATION = .5;
const float DRAW_THRESHOLD = 1.5;
const bool HIDE_TRAILS_ON_THE_SAME_LINE = false;

// ============================================================
// --- MAIN ---
// ============================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    // --- Snow pass (drawn first, underneath the cursor trail) ---
    vec2 flakeUv = fragCoord.xy / iResolution.xy;
    vec3 finalSnow = vec3(0.0);
    
    for (int i = 0; i < PARTICLE_LAYERS; i++) {
        vec3 pColor;
        float g = drawFlake(flakeUv, float(i), pColor);
        finalSnow += pColor * g;
    }
    fragColor.rgb += finalSnow;

    // Calculate how much snow was added so the snow itself doesn't become fully transparent
    float snowAlpha = max(max(finalSnow.r, finalSnow.g), finalSnow.b);

    // --- Cursor trail pass ---
    vec2 vu = normalizeCoord(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(normalizeCoord(iCurrentCursor.xy, 1.), normalizeCoord(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalizeCoord(iPreviousCursor.xy, 1.), normalizeCoord(iPreviousCursor.zw, 0.));

    float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    float invertedVertexFactor = 1.0 - vertexFactor;

    vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
    vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

    vec4 newColor = vec4(fragColor);

    float progress = blend(clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1));
    float easedProgress = ease(progress);

    vec4 trailColor = fireColor(0.0);
    vec4 trailColorAccent = fireColor(0.18);

    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);
    float cursorSize = max(currentCursor.z, currentCursor.w);
    float trailThreshold = DRAW_THRESHOLD * cursorSize;
    float lineLength = distance(centerCC, centerCP);

    bool isFarEnough = lineLength > trailThreshold;
    bool isOnSeparateLine = HIDE_TRAILS_ON_THE_SAME_LINE ? currentCursor.y != previousCursor.y : true;
    if (isFarEnough && isOnSeparateLine) {
        float distanceToEnd = distance(vu.xy, centerCC);
        float alphaModifier = distanceToEnd / (lineLength * (easedProgress));

        if (alphaModifier > 1.0) {
            alphaModifier = 1.0;
        }

        float sdfCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
        float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

        newColor = mix(newColor, trailColorAccent, 1.0 - smoothstep(sdfTrail, -0.01, 0.001));
        newColor = mix(newColor, trailColor, antialising(sdfTrail));
        newColor = mix(fragColor, newColor, 1.0 - alphaModifier);
        fragColor = mix(newColor, fragColor, step(sdfCursor, 0));
    }

    // Preserve terminal transparency, but ensure the snow and cursor are solid enough to see
    fragColor.a = max(fragColor.a, snowAlpha);
}
