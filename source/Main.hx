package;

import flixel.FlxGame;

class Main extends openfl.display.Sprite
{
	public static var initialState(default, null) = states.CabinState.new;
	
	public function new()
	{
		super();
		// addChild(new FlxGame(240, 135, states.BootState));
		// addChild(new FlxGame(480, 270, states.BootState));
		addChild(new FlxGame(960, 540, states.BootState));
	}
}
