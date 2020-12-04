package vfx;

class GhostShader extends flixel.system.FlxAssets.FlxShader
{
	@:glFragmentSource('
		#pragma header
		
		const float pixelSize = 0.5;
		uniform bool invert;
		
		float checker(vec2 coord)
		{
			return mod((invert ? 1.0 : 0.0) + floor(coord.x / pixelSize) + floor(coord.y / pixelSize), 2.0);
		}
		
		vec4 pixelColor(vec2 coord)
		{
			return texture2D(bitmap, coord / openfl_TextureSize);
		}
		
		float pixelAlpha(vec2 coord)
		{
			return pixelColor(coord).w;
		}
		
		vec4 bigPixelCenterColor(vec2 coord)
		{
			return pixelColor(coord + vec2(pixelSize / 2.0, pixelSize / 2.0));
		}
		
		float bigPixelBlendAlpha(vec2 coord)
		{
			return floor
				(   ( pixelAlpha(coord)
					+ pixelAlpha(coord + vec2(pixelSize, 0        ))
					+ pixelAlpha(coord + vec2(0        , pixelSize))
					+ pixelAlpha(coord + vec2(pixelSize, pixelSize))
					) / 4.0 + 0.5
				);
		}
		
		vec2 bigPixelTopLeft(vec2 coord)
		{
			return vec2(coord.x - mod(coord.x, pixelSize), coord.y - mod(coord.y, pixelSize));
		}
		
		float neighboringBigPixelsCenterAlpha(vec2 coord)
		{
			return floor
				(	( bigPixelCenterColor(coord + vec2(0,  pixelSize)).w
					+ bigPixelCenterColor(coord + vec2(0, -pixelSize)).w
					+ bigPixelCenterColor(coord + vec2( pixelSize, 0)).w
					+ bigPixelCenterColor(coord + vec2(-pixelSize, 0)).w
					) / 4.0
				);
		}
		
		void main()
		{
			vec2 topLeft = bigPixelTopLeft(openfl_TextureCoordv * openfl_TextureSize);
			gl_FragColor = bigPixelCenterColor(topLeft) * vec4(0.45, 0.8, 1.2, 1.0);
			if (gl_FragColor.a > 0.0)
				gl_FragColor += vec4(0.0, 0.1, 0.2, 0.0);
			gl_FragColor = mix(vec4(0,0,0,0), gl_FragColor, checker(topLeft));
		}
	')
	public function new()
	{
		super();
		
		this.invert.value = [true];
	}
	
	public function updatePos(x:Int, y:Int)
	{
		this.invert.value[0] = ((x + y) % 2 == 1);
	}
	
	inline public function updatePosRound(x:Float, y:Float)
	{
		updatePos(Math.round(x), Math.round(y));
	}
}