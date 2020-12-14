package vfx;

import flixel.FlxSprite;
import utils.GameSize;
import flixel.util.FlxColor;

class PeekDitherShader extends flixel.system.FlxAssets.FlxShader
{
    inline static var NUM_LIGHTS = 1;
    @:glFragmentSource('
        #pragma header
        
        const float innerRadiusRatio = 0.4;
        
        const bool inverse = false;
        const float radius = 60.0;
        const float pixelSize = 1.0;
        const vec4 shadow = vec4(0.0, 0.0, 0.0, 0.0);
        uniform float amount;
        uniform vec2 light;
        
        vec4 pixelColor(vec2 coord)
        {
            return texture2D(bitmap, coord / openfl_TextureSize);
        }
        
        vec4 bigPixelCenterColor(vec2 coord)
        {
            return pixelColor(coord + vec2(pixelSize / 2.0));
        }
        
        vec2 bigPixelTopLeft(vec2 coord)
        {
            return vec2(coord.x - mod(coord.x, pixelSize), coord.y - mod(coord.y, pixelSize));
        }
        
        float indexValue(vec2 coord)
        {
            int indices[16];
            indices[ 0] =  0; indices[ 1] =  8; indices[ 2] =  2; indices[ 3] = 10;
            indices[ 4] = 12; indices[ 5] =  4; indices[ 6] = 14; indices[ 7] =  6;
            indices[ 8] =  3; indices[ 9] = 11; indices[10] =  1; indices[11] =  9;
            indices[12] = 15; indices[13] =  7; indices[14] = 13; indices[15] =  5;
            
            int x = int(mod(coord.x / pixelSize, 4.0));
            int y = int(mod(coord.y / pixelSize, 4.0));
            float amount = 0.0;
            
            for (int i = 0; i < 16; i++)
            {
                amount = (x + y * 4 == i) ? float(indices[i]) / 16.0 : amount;
            }
            
            return amount;
        }
        
        vec4 dither(vec4 color, float amount, vec2 coord)
        {
            return (amount <= indexValue(coord)) == inverse ? color : shadow;
        }
        
        float getLight(vec2 coord, vec2 light, float radius)
        {
            float smallRadius = innerRadiusRatio * radius;
            vec2 d = coord - (light * pixelSize); 
            float length = sqrt(d.x*d.x + d.y*d.y) / pixelSize;
            float amount = max(0.0, min(length - smallRadius, radius - smallRadius));
            return radius > 0.0 ? amount / (radius - smallRadius) : 1.0;
        }
        
        void main()
        {
            vec2 topLeft = bigPixelTopLeft(openfl_TextureCoordv * openfl_TextureSize);
            
            float pixelAmount = amount;
            pixelAmount = min(pixelAmount, getLight(topLeft, light, radius));
            
            gl_FragColor = dither(bigPixelCenterColor(topLeft), pixelAmount, topLeft);
        }
    ')
    
    public function new()
    {
        super();
        
        // this.indices.value =
        //     [  0,  8,  2, 10
        //     , 12,  4, 14,  6
        //     ,  3, 11,  1,  9
        //     , 15,  7, 13,  5
        //     ];
        this.amount.value = [1.0];
        setPlayerPos(0, 0);
    }
    
    public function setPlayerPosWithSprite(x:Float, y:Float, target:FlxSprite)
    {
        setPlayerPos(x - (target.x - target.offset.x), y - (target.y - target.offset.y));
    }
    
    public function setPlayerPos(x:Float, y:Float)
    {
        this.light.value = [x, y];
    }
    
    public function setAlpha(value:Float)
    {
        this.amount.value = [value];
    }
    
    public function getAlpha()
    {
        return this.amount.value[0];
    }
}