//Temperature between -100 and 100
extern float temperature = 20;

texture lastshader;
sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };

/**
    A collection of common functions and variables used by shaders in Joy of Painting.
**/

#define PI acos(-1)
#define sky 1e6

matrix mview;
matrix mproj;
float time;
float2 rcpres;
float3 sunvec;
float sunvis;
float3 eyepos;
float3 eyevec;
float fov;
float waterlevel;
float fogstart;
float fogrange;
float fognearrange;
float fognearstart;
float3 fognearcol;

static const float Time = time;

// The inverse projection matrix
static const float2 invproj = 2.0 * tan(0.5 * radians(fov)) * float2(1, rcpres.x / rcpres.y);
static const float xylength = sqrt(1 - eyevec.z * eyevec.z);
/**
    Samples a texture at the given texture coordinates, with mip level 0.
    @param s The texture sampler.
    @param uv The texture coordinates.
    @return The color of the pixel.
*/
float4 sample0(sampler2D s, float2 tex)
{
    return tex2Dlod(s, float4(tex, 0, 0));
}

/**
    Distorts the texture based on the provided distortion texture
    @param Tex The texture coordinates of the pixel.
    @param Time The current Time.
    @param speed The speed of the distortion.
    @param distance How far the distortion moves.
    @param scale The scale applied to the distortion texture.
    @param distortionStrength The strength of the distortion.
    @param sDistortionTex The distortion texture.
    @param offset The offset of the distortion. Default is 0.
*/
float2 distort(float2 Tex, float distortionStrength, sampler2D sDistortionTex, float offset = 0) {

    float thisTime = Time + offset;
    float distortionScale = 0.5;
    // Move around over Time
    float scale = 0.2;
    float2 uvR = float2(Tex.x + sin(thisTime * 0.5) * 0.1, Tex.y + cos(thisTime * 0.5) * 0.1) * scale;
    float2 uvG = float2(Tex.x + cos(thisTime * 0.5) * 0.1, Tex.y + sin(thisTime * 0.5) * 0.1) * scale * 1.1;
    float2 uvB = float2(Tex.x - sin(thisTime * 0.5) * 0.1, Tex.y - cos(thisTime * 0.5) * 0.1) * scale * 1.3;

    float4 normalMapR = tex2D(sDistortionTex, uvR);
    float4 normalMapG = tex2D(sDistortionTex, uvG);
    float4 normalMapB = tex2D(sDistortionTex, uvB);

    // Convert the normal map from tangent space to [-1, 1]
    float2 distortionR = (normalMapR.rg * 2.0 - 1.0);
    float2 distortionG = (normalMapG.rg * 2.0 - 1.0);
    float2 distortionB = (normalMapB.rg * 2.0 - 1.0);

    // Combine the distortions from each channel
    float2 combinedDistortion = (distortionR + distortionG + distortionB) / 3.0;

    // Apply the combined distortion to the texture coordinates
    float2 distort = Tex + combinedDistortion * distortionStrength * distortionScale;

    return distort;
}


/**
    Reads the depth of the pixel at the given texture coordinates.
    The returned depth is
    @param tex The texture coordinates of the pixel.
    @param sDepthFrame The depth frame sampler.
    @param power The power to raise the depth to. Default is 1.
    @return The depth of the pixel.
*/
float readDepth(float2 tex, sampler2D sDepthFrame, int power = 1)
{
	float depth = pow(sample0(sDepthFrame, tex).r, power);
	return depth;
}

/**
    Convert RGB to HSL
    @param color The color to convert.
    @return The HSL color.
*/
float3 RGBToHSL(float3 color)
{
    float3 hsl; // init to 0 to avoid warnings ? (and reverse if + remove first part)
    float fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    float delta = fmax - fmin;             //Delta RGB value
    hsl.z = (fmax + fmin) / 2.0; // Luminance

    if (delta == 0.0)       //This is a gray, no chroma...
    {
        hsl.x = 0.0;    // Hue
        hsl.y = 0.0;    // Saturation
    }
    else                                    //Chromatic data...
    {
        if (hsl.z < 0.5)
            hsl.y = delta / (fmax + fmin); // Saturation
        else
            hsl.y = delta / (2.0 - fmax - fmin); // Saturation

        float deltaR = (((fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
        float deltaG = (((fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
        float deltaB = (((fmax - color.b) / 6.0) + (delta / 2.0)) / delta;

        if (color.r == fmax )
            hsl.x = deltaB - deltaG; // Hue
        else if (color.g == fmax)
            hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
        else if (color.b == fmax)
            hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue

        if (hsl.x < 0.0)
            hsl.x += 1.0; // Hue
        else if (hsl.x > 1.0)
            hsl.x -= 1.0; // Hue
    }

    return hsl;
}

// Helper function for HSLToRGB
float HueToRGB(float f1, float f2, float hue)
{
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

// Converts HSL to RGB
float3 HSLToRGB(float3 hsl)
{
    float3 rgb;

    if (hsl.y == 0.0)
        rgb = float3(hsl.z, hsl.z, hsl.z); // Luminance
    else
    {
        float f2;

        if (hsl.z < 0.5)
            f2 = hsl.z * (1.0 + hsl.y);
        else
            f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);

        float f1 = 2.0 * hsl.z - f2;

        rgb.r = HueToRGB(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = HueToRGB(f1, f2, hsl.x);
        rgb.b= HueToRGB(f1, f2, hsl.x - (1.0/3.0));
    }

    return rgb;
}

/**
    Converts the texture coordinates to world coordinates.
    @param tex The texture coordinates of the pixel.
    @return The world coordinates of the pixel.
*/
float3 toWorld(float2 tex)
{
	float3 v = float3(mview[0][2], mview[1][2], mview[2][2]);
	v += (1/mproj[0][0] * (2*tex.x-1)).xxx * float3(mview[0][0], mview[1][0], mview[2][0]);
	v += (-1/mproj[1][1] * (2*tex.y-1)).xxx * float3(mview[0][1], mview[1][1], mview[2][1]);
	return v;
}

/**
    Converts the texture coordinates to view coordinates.
    @param tex The texture coordinates of the pixel.
    @param sDepthFrame The depth frame sampler.
    @return The view coordinates of the pixel.
*/
float3 toView(float2 tex, sampler2D sDepthFrame)
{
    float depth = readDepth(tex, sDepthFrame);
    float2 xy = depth * (tex - 0.5) * invproj;
    return float3(xy, depth);
}

/**
    Gets the position of the pixel at the given texture coordinates.
    @param tex The texture coordinates of the pixel.
    @param depth The depth of the pixel.
    @param eyepos The position of the camera.
    @return The position of the pixel.
*/
float3 getPosition(float2 tex, float depth)
{
	return (eyepos + toWorld(tex) * depth);
}

/**
    Gets the world-space normal of the pixel at the given texture coordinates.
    @param uv The texture coordinates of the pixel.
    @param sDepthFrame The depth frame sampler.
    @return The world-space normal of the pixel.
*/
float3 _getWorldSpaceNormal(float2 uv, sampler2D sDepthFrame)
{
    // Neighboring UV coordinates
    float2 posCenter = uv;
    float2 posNorth  = posCenter + float2(0, -rcpres.y); // Move up
    float2 posEast   = posCenter + float2(rcpres.x, 0);  // Move right

    // Get view rays for the current pixel and neighbors
    float3 viewRayCenter = toWorld(posCenter); // This is a view ray, not world space position
    float3 viewRayNorth  = toWorld(posNorth);
    float3 viewRayEast   = toWorld(posEast);

    // Reconstruct world-space positions using eyePos
    float3 worldPosCenter = eyepos + normalize(viewRayCenter) * length(toView(posCenter, sDepthFrame));
    float3 worldPosNorth  = eyepos + normalize(viewRayNorth)  * length(toView(posNorth, sDepthFrame));
    float3 worldPosEast   = eyepos + normalize(viewRayEast)   * length(toView(posEast, sDepthFrame));

    // Compute the world-space normal using the cross product
    float3 edge1 = worldPosNorth - worldPosCenter;
    float3 edge2 = worldPosEast - worldPosCenter;

    // Correct for Z-up coordinate system
    float3 normal = normalize(cross(edge2, edge1)); // Switch cross order to respect Z-up
    return normal;
}


float3 toWorldWithDepth(float2 uv, float depth)
{
    // This version modifies your toWorld() to incorporate depth.
    // (Adjust signs, near/far plane logic, or matrix usage as needed.)
    // Some engines use [0..1] for depth; others might use different ranges.
    // Move uv from [0..1] into clip space [-1..1]
    float2 clip = float2(2.0 * uv.x - 1.0, 1.0 - 2.0 * uv.y);
    // Start with the camera's forward basis from your mview, etc.
    // We'll just show a pseudo-code version:
    float3 wpos = float3(mview[0][2], mview[1][2], mview[2][2]);
    // Scale factors from the projection
    float invProjX = 1.0 / mproj[0][0];  // typically FOV scale
    float invProjY = 1.0 / mproj[1][1];
    // "clip.x" is the [-1..1] x coordinate
    wpos += (clip.x * invProjX) * float3(mview[0][0], mview[1][0], mview[2][0]);
    wpos += (clip.y * -invProjY) * float3(mview[0][1], mview[1][1], mview[2][1]);
    // Adjust by 'depth' in a way consistent with your engine's depth range
    // Exactly how you factor in 'depth' depends on how your pipeline is set up.
    // E.g., you might do something like:
    wpos *= depth;  // or apply near/far plane logic as appropriate
    return wpos;
}

float3 getWorldSpaceNormal(float2 uv, sampler2D sDepthFrame)
{
    // Sample depth from the depth buffer
    float depthC = sample0(sDepthFrame, uv).r;
    // Get the world‐space position at the center
    float3 center = toWorldWithDepth(uv, depthC);
    float3 pos = toView(uv, sDepthFrame);
    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;
    if(pos.z <= 0 || pos.z > sky || (water - waterlevel) < 0)
        return float3(0, 0, 1);
    // Offset in X
    float2 uvR = uv + float2(rcpres.x, 0);
    float2 uvL = uv - float2(rcpres.x, 0);
    float3 posR = toWorldWithDepth(uvR, sample0(sDepthFrame, uvR).r);
    float3 posL = toWorldWithDepth(uvL, sample0(sDepthFrame, uvL).r);
    // Offset in Y
    float2 uvD = uv + float2(0, rcpres.y);
    float2 uvU = uv - float2(0, rcpres.y);
    float3 posD = toWorldWithDepth(uvD, sample0(sDepthFrame, uvD).r);
    float3 posU = toWorldWithDepth(uvU, sample0(sDepthFrame, uvU).r);
    // Compute partial derivatives: one across X, one across Y
    float3 dX = posR - posL;
    float3 dY = posD - posU;
    // World‐space normal via cross product
    float3 N = normalize(cross(dX, dY));
    return N;
}


float3 temperatureEffect(float2 uv, float3 color,  float temperature)
{
    float3 coldColor = float3(0.0, 0.50, 1.0);
    float3 hotColor = float3(1.0, 0.5, 0.0);

    float3 colorTemperature = lerp(coldColor, hotColor, temperature > 0);

    float luminosity = dot(color.rgb, float3(0.299, 0.587, 0.114));

    float distanceFromCenter = distance(uv, float2(0.5, 0.5));
    float absTemp = abs(temperature);
    float distanceEffect = saturate(distanceFromCenter * ( absTemp / 100) - 0.5);

    //Limit the color values to cold/hot depending on temperature
    float fadeAmount = saturate(abs(temperature) / 100) * luminosity * 2;
    color.rgb = lerp(color.rgb, colorTemperature, fadeAmount * distanceEffect);

    return color;
}




float4 main(float2 uv : TEXCOORD) : SV_Target {
    float4 color = tex2D(sLastShader, uv);

    color.rgb = temperatureEffect(uv, color.rgb, temperature);


    return color;
}

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 40; >
{
    pass p0 { PixelShader = compile ps_3_0 main(); }
}
