package vfx;

import flixel.util.FlxColor;

class CrtShader extends flixel.system.FlxAssets.FlxShader
{
    inline static var NUM_LIGHTS = 1;
    @:glFragmentSource('
        #pragma header
        
        const float vignetteStrength = 0.1;
        const float colorOfsset = 1.0;
        
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
            vec2 p = vec2(1.0, 1.0) * colorOfsset / openfl_TextureSize;
        
            col.r = texture2D(bitmap, vec2(uv.x-p.x,uv.y    )).r;
            col.g = texture2D(bitmap, vec2(uv.x+p.x,uv.y    )).g;
            col.b = texture2D(bitmap, vec2(uv.x    ,uv.y-p.y)).b;
            
            // darken edges, vignette
            float vig = (16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y));
            col *= vec3(pow(vig, vignetteStrength));
            
            vec3 mosiacColor = col;
            // mosiacColor*=1.0-0.80*vec3(clamp((mod(fragCoord.x, 2.0)-1.0)*2.0,0.0,1.0));
            // mosiacColor *= 1.25;
            
            gl_FragColor = vec4(mosiacColor, 1.0);
            
            //cull past corners
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
                gl_FragColor *= 0.0;
            
        }
    ')
    
    public function new()
    {
        super();
    }
}