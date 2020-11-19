package vfx;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class Inline extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        uniform vec2 size;
        uniform vec4 color;

        void main()
        {
            vec4 sample = flixel_texture2D(bitmap, openfl_TextureCoordv);
            if (sample.a != 0.0) {
                float w = size.x / openfl_TextureSize.x;
                float h = size.y / openfl_TextureSize.y;
                
                if (flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x + w, openfl_TextureCoordv.y    )).a == 0.0
                 || flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x - w, openfl_TextureCoordv.y    )).a == 0.0
                 || flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x    , openfl_TextureCoordv.y + h)).a == 0.0
                 || flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x    , openfl_TextureCoordv.y - h)).a == 0.0)
                    sample = color;
            }
            gl_FragColor = sample;
        }')

	public function new(color:FlxColor = 0xFFFFFFFF, width:Float = 1, height:Float = 1)
	{
		super();
		this.color.value = [color.red, color.blue, color.green, color.alpha];
		this.size.value = [width, height];
	}
}