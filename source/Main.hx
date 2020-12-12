package;

import states.rooms.RoomState;

class Main extends openfl.display.Sprite
{
	public static var initialRoom(default, null) = 
		#if debug
		// RoomName.Bedroom;
		// RoomName.Hallway + "." + RoomName.Bedroom;
		// RoomName.Entrance + "." + RoomName.Hallway;
		// RoomName.Outside + "." + RoomName.Entrance;
		// RoomName.Arcade + "." + RoomName.Entrance;
		RoomName.Studio + "." + RoomName.Entrance;
		#else
		RoomName.Bedroom;
		#end
	public function new()
	{
		super();
		// addChild(new flixel.FlxGame(240, 135, states.BootState, 1, 60, 60, true));
		addChild(new flixel.FlxGame(480, 270, states.BootState, 1, 60, 60, true));
		// addChild(new flixel.FlxGame(960, 540, states.BootState));
		
		trace("version:" + openfl.Lib.application.meta.get("version"));
	}
}
