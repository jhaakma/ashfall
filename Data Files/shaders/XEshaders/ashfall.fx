//Temperature between -100 and 100
extern float temperature = 20;

texture lastshader;
sampler2D sLastShader = sampler_state { texture = <lastshader>; addressu = clamp; };

float4 main(float2 uv : TEXCOORD) : SV_Target {
    float4 color = tex2D(sLastShader, uv);

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

technique T0 < string MGEinterface="MGE XE 0"; string category = "final"; int priorityAdjust = 40; >
{
    pass p0 { PixelShader = compile ps_3_0 main(); }
}
