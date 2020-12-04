package vfx;

class DitherShader extends flixel.system.FlxAssets.FlxShader
{
    @:glFragmentSource('
        #pragma header
        
        uniform float pixelSize;
        uniform float amount;
        
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
            return amount <= indexValue(coord) ? color : vec4(0.0, 0.0, 0.0, 0.0);
        }
        
        void main()
        {
            // vec2 topLeft = bigPixelTopLeft(openfl_TextureCoordv * openfl_TextureSize);
            // gl_FragColor = dither(bigPixelCenterColor(topLeft), amount, topLeft);
            // gl_FragColor = bigPixelCenterColor(topLeft);
            // gl_FragColor.a = 0;
            gl_FragColor = vec4(1.0,1.0,1.0,1.0);
        }
    ')
    public function new(pixelSize = 1.0)
    {
        super();
        this.pixelSize.value = [pixelSize];
        this.amount.value = [1.0];
    }
    
    inline public function getAlpha() return this.amount.value[0];
    inline public function setAlpha(value:Float) this.amount.value[0] = value;
}