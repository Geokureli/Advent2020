package;

import states.rooms.RoomState;
import flixel.FlxGame;

class Main extends openfl.display.Sprite
{
	public static var initialRoom(default, null) = RoomName.Bedroom;
	
	public function new()
	{
		super();
		addChild(new FlxGame(240, 135, states.BootState));
		// addChild(new FlxGame(480, 270, states.BootState));
		// addChild(new FlxGame(960, 540, states.BootState));
	}
}
