package vfx;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

class Snow extends FlxTypedGroup<FlxSprite>
{
	public function new(avgSpacing = 45)
	{
		super();
		
		final density = 1 / avgSpacing / avgSpacing;
		final graphic = new openfl.display.BitmapData(1, 1, false);
		final camera = FlxG.camera;
		
		var num = Math.floor(camera.width * camera.height * density);
		// trace(num + " snow flakes");
		while(num-- > 0)
		{
			var flake = new FlxSprite
				( camera.scroll.x + FlxG.random.float(0, camera.width)
				, camera.scroll.y + FlxG.random.float(0, camera.height)
				, graphic
				);
			add(flake);
			flake.velocity.y = getRandomSpeed();
			flake.velocity.x = FlxG.random.float(-30, 30);
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		final camera = FlxG.camera;
		
		for (flake in members)
		{
			while (flake.y < camera.scroll.y)
				flake.y += camera.height;
			
			if (flake.y > camera.scroll.y + camera.height)
			{
				flake.y -= camera.height;
				flake.x = camera.scroll.x + FlxG.random.float(0, camera.width);
				flake.velocity.y = getRandomSpeed();
			}
			
			if (flake.x > camera.scroll.x + camera.width)
				flake.x -= camera.width;
			
			if (flake.x < camera.scroll.x)
				flake.x += camera.width;
		}
	}
	
	inline function getRandomSpeed():Float
		return FlxG.random.float(20, 50);
}