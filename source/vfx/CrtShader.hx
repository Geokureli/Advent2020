package vfx;

class CrtShader extends flixel.system.FlxAssets.FlxShader
{
    inline static var NUM_LIGHTS = 1;
    @:glFragmentSource('
        #pragma header
        
        const float vignetteStrength = 0.1;
        
        vec2 curve(vec2 uv)
        {
            uv = (uv - 0.5) * 2.0;
            uv *= 1.1;	
            uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
            uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
            uv  = (uv / 2.0) + 0.5;
            uv =  uv *0.92 + 0.04;
            return uv;
        }
        
        void main()
        {
            vec2 fragCoord = openfl_TextureCoordv * openfl_TextureSize;
            vec2 uv = curve(openfl_TextureCoordv);
            vec3 col = texture2D(bitmap, uv).rgb;
            vec2 p = vec2(2.0, 2.0) / openfl_TextureSize;
        
            col.r = texture2D(bitmap, vec2(uv.x-p.x,uv.y    )).r;
            col.g = texture2D(bitmap, vec2(uv.x+p.x,uv.y    )).g;
            col.b = texture2D(bitmap, vec2(uv.x    ,uv.y-p.y)).b;
            
            // darken edges, vignette
            float vig = (16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
            col *= vec3(pow(vig, vignetteStrength));
            
            //cull past corners
            if (uv.x < 0.0 || uv.x > 1.0)
                col *= 0.0;
            if (uv.y < 0.0 || uv.y > 1.0)
                col *= 0.0;
            
            col*=1.0-0.65*vec3(clamp((mod(fragCoord.x, 2.0)-1.0)*2.0,0.0,1.0));
            col *= 1.5;
            
            gl_FragColor = vec4(col, 1.0);
        }
    ')
    
    public function new()
    {
        super();
    }
}