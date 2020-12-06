package;

import states.rooms.RoomState;

class Main extends openfl.display.Sprite
{
	public static var initialRoom(default, null) = 
		#if debug
		RoomName.Bedroom;
		// (RoomName.Hallway:String) + ".0";
		// (RoomName.Entrance:String) + ".0";
		// (RoomName.Outside:String) + ".0";
		#else
		RoomName.Bedroom;
		#end
	public function new()
	{
		super();
		#if SKIP_TO_DIG_GAME
		addChild(new flixel.FlxGame(480, 270, PlayState, 1, 60, 60, true));
		#else
		// addChild(new flixel.FlxGame(240, 135, states.BootState, 1, 60, 60, true));
		addChild(new flixel.FlxGame(480, 270, states.BootState, 1, 60, 60, true));
		// addChild(new flixel.FlxGame(960, 540, states.BootState));
		#end
		
		trace("version:" + openfl.Lib.application.meta.get("version"));
	}
}
