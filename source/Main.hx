package;

import states.rooms.RoomState;

class Main extends openfl.display.Sprite
{
	public function new()
	{
		super();
		// addChild(new flixel.FlxGame(240, 135, states.BootState, 1, 60, 60, true));
		addChild(new flixel.FlxGame(480, 270, states.BootState, 1, 60, 60, true));
		// addChild(new flixel.FlxGame(960, 540, states.BootState));
	}
}
