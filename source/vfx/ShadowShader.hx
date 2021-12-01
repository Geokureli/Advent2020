package vfx;

import utils.GameSize;
import flixel.util.FlxColor;

class ShadowShader extends flixel.system.FlxAssets.FlxShader
{
    inline static var NUM_LIGHTS = 1;
    @:glFragmentSource('
        #pragma header
        
        const float innerRadiusRatio = 0.8;
        
        uniform float ambientDither;
        uniform bool inverse;
        uniform vec4 shadow;
        // uniform int indices[16];
        uniform float pixelSize;
        
        // LIGHT 1
        uniform vec2 light1;
        uniform float rad1;
        
        // LIGHT 2
        uniform vec2 light2;
        uniform float rad2;
        
        // LIGHT 3
        uniform vec2 light3;
        uniform float rad3;
        
        // LIGHT 4
        uniform vec2 light4;
        uniform float rad4;
        
        // LIGHT 5
        uniform vec2 light5;
        uniform float rad5;
        
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
            
            float amount = ambientDither;
            amount = min(amount, getLight(topLeft, light1, rad1));
            amount = min(amount, getLight(topLeft, light2, rad2));
            amount = min(amount, getLight(topLeft, light3, rad3));
            amount = min(amount, getLight(topLeft, light4, rad4));
            amount = min(amount, getLight(topLeft, light5, rad5));
            
            gl_FragColor = dither(bigPixelCenterColor(topLeft), amount, topLeft);
        }
    ')
    
    public function new(shadow:FlxColor, pixelSize = -1.0, inverse = true, ambientDither = 1.0)
    {
        super();
        this.ambientDither.value = [ambientDither];
        this.pixelSize.value = [pixelSize <= 0 ? GameSize.pixelSize : pixelSize];
        this.inverse.value = [inverse];
        this.shadow.value = [shadow.redFloat, shadow.greenFloat, shadow.blueFloat, shadow.alphaFloat];
        
        // this.indices.value =
        //     [  0,  8,  2, 10
        //     , 12,  4, 14,  6
        //     ,  3, 11,  1,  9
        //     , 15,  7, 13,  5
        //     ];
        
        for (i in 0...NUM_LIGHTS)
        {
            setLight(i + 1, 0, 0, 0);
        }
    }
    
    public function setAmbientDither(num:Float)
    {
        this.ambientDither.value = [num];
    }
    
    public function setLight(num:Int, x:Float, y:Float, radius:Float)
    {
        switch (num)
        {
            case 1:
                this.light1.value = [x, y];
                this.rad1.value = [radius];
            case 2:
                this.light2.value = [x, y];
                this.rad2.value = [radius];
            case 3:
                this.light3.value = [x, y];
                this.rad3.value = [radius];
            case 4:
                this.light4.value = [x, y];
                this.rad4.value = [radius];
            case 5:
                this.light5.value = [x, y];
                this.rad5.value = [radius];
            case _: throw "invalid light:" + num;
        }
    }
    
    public function setLightPos(num:Int, x:Float, y:Float)
    {
        switch (num)
        {
            case 1: this.light1.value = [x, y];
            case 2: this.light2.value = [x, y];
            case 3: this.light3.value = [x, y];
            case 4: this.light4.value = [x, y];
            case 5: this.light5.value = [x, y];
            case _: throw "invalid light:" + num;
        }
    }
    
    public function setLightX(num:Int, x:Float)
    {
        switch (num)
        {
            case 1: this.light1.value[0] = x;
            case 2: this.light2.value[0] = x;
            case 3: this.light3.value[0] = x;
            case 4: this.light4.value[0] = x;
            case 5: this.light5.value[0] = x;
            case _: throw "invalid light:" + num;
        }
    }
    
    public function getLightX(num:Int)
    {
        return switch (num)
        {
            case 1: this.light1.value[0];
            case 2: this.light2.value[0];
            case 3: this.light3.value[0];
            case 4: this.light4.value[0];
            case 5: this.light5.value[0];
            case _: throw "invalid light:" + num;
        }
    }
    
    public function setLightY(num:Int, y:Float)
    {
        switch (num)
        {
            case 1: this.light1.value[1] = y;
            case 2: this.light2.value[1] = y;
            case 3: this.light3.value[1] = y;
            case 4: this.light4.value[1] = y;
            case 5: this.light5.value[1] = y;
            case _: throw "invalid light:" + num;
        }
    }
    
    public function getLightY(num:Int)
    {
        return return switch (num)
        {
            case 1: this.light1.value[1];
            case 2: this.light2.value[1];
            case 3: this.light3.value[1];
            case 4: this.light4.value[1];
            case 5: this.light5.value[1];
            case _: throw "invalid light:" + num;
        }
    }
    
    public function setLightRadius(num:Int, radius:Float)
    {
        switch (num)
        {
            case 1: this.rad1.value = [radius];
            case 2: this.rad2.value = [radius];
            case 3: this.rad3.value = [radius];
            case 4: this.rad4.value = [radius];
            case 5: this.rad5.value = [radius];
            case _: throw "invalid light:" + num;
        }
    }
    
    public function getLightRadius(num:Int)
    {
        return switch (num)
        {
            case 1: this.rad1.value[0];
            case 2: this.rad2.value[0];
            case 3: this.rad3.value[0];
            case 4: this.rad4.value[0];
            case 5: this.rad5.value[0];
            case _: throw "invalid light:" + num;
        }
    }
}