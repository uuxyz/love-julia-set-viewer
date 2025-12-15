
extern vec2 lightPos;
extern float lightRadius;
extern vec2 resolution;
extern float lightHue;
extern vec3 ambientColor;

// New uniforms for split-screen fractal views
extern float mandelbrot_zoom;
extern vec2 mandelbrot_offset;
extern float julia_zoom;
extern vec2 julia_offset;

// Function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Unified wall function for both Mandelbrot and Julia sets.
// Returns 0.0 if inside the set (a wall), > 0.0 otherwise.
float is_wall(vec2 coord) {
    int max_iter = 100;
    int i = 0;

    if (coord.x < resolution.x / 2.0) {
        // Left side: Mandelbrot Set
        vec2 c = (coord - vec2(resolution.x * 0.25, resolution.y * 0.5)) / (resolution.y * mandelbrot_zoom) + mandelbrot_offset;
        vec2 z = vec2(0.0, 0.0);
        for (i = 0; i < max_iter; i++) {
            z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
            if (length(z) > 2.0) break;
        }
    } else {
        // Right side: Julia Set
        vec2 z = (coord - vec2(resolution.x * 0.75, resolution.y * 0.5)) / (resolution.y * julia_zoom) + julia_offset;
        vec2 c = mandelbrot_offset; // Linked to Mandelbrot's center
        for (i = 0; i < max_iter; i++) {
            z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
            if (length(z) > 2.0) break;
        }
    }
    
    if (i == max_iter) return 0.0; // Inside the set
    return float(i) / float(max_iter); // Outside the set
}


vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 fragPos = screen_coords;
    float wall_check = is_wall(fragPos);

    vec3 finalColor;
    if (wall_check > 0.0) {
        finalColor = vec3(0.05, 0.05, 0.1); // Background color
        finalColor = mix(finalColor, vec3(0.9, 0.9, 1.0), 1.0 - wall_check);
    } else {
        // Wall color
        if (fragPos.x < resolution.x / 2.0) {
            finalColor = hsv2rgb(vec3(0.6, 0.8, 0.5)); // Mandelbrot wall color
        } else {
            finalColor = hsv2rgb(vec3(0.9, 0.8, 0.5)); // Julia wall color
        }
    }

    // Light direction and distance
    vec2 lightDir = lightPos - fragPos;
    float distToLight = length(lightDir);

    // Light falloff
    float lightIntensity = 1.0 - (distToLight / lightRadius);
    lightIntensity = max(0.0, lightIntensity);

    // Soft shadows
    float inShadow = 0.0;
    int samples = 4;
    float sample_radius = 10.0;
    if (distToLight > 1.0) {
        for (int i = 0; i < samples; i++) {
            float angle = float(i) / float(samples) * 2.0 * 3.14159;
            vec2 offset_shadow = vec2(cos(angle), sin(angle)) * sample_radius;
            vec2 samplePos = fragPos + offset_shadow;
            
            vec2 rayDir = lightPos - samplePos;
            float dist = length(rayDir);
            rayDir /= dist;

            int numSteps = int(dist / 5.0);
            for (int j = 0; j < numSteps; j++) {
                vec2 rayPos = samplePos + rayDir * float(j) * 5.0;
                if (is_wall(rayPos) == 0.0) { // Check if inside either set
                    inShadow += 1.0;
                    break;
                }
            }
        }
    }
    inShadow /= float(samples);

    // Final color calculation
    vec3 lightColor = hsv2rgb(vec3(lightHue, 0.8, 1.0));
    float finalLight = lightIntensity * (1.0 - inShadow);

    finalColor = mix(finalColor, lightColor, finalLight);
    finalColor += ambientColor;
    
    return vec4(finalColor, 1.0);
}
