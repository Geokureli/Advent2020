package data;

import states.rooms.RoomState;
import states.rooms.*;

import flixel.FlxG;

class Game
{
    static public var room(get, never):RoomState;
    static function get_room() return Std.downcast(FlxG.state, RoomState);
    
    static var roomTypes:Map<RoomName, RoomConstructor>;
    
    @:allow(states.BootState)
    static function init():Void
    {
        roomTypes = [];
        roomTypes[Bedroom] = BedroomState.new;
        roomTypes[Hallway] = HallwayState.new;
        
        trace(flixel.util.FlxColor.fromRGBFloat(0.1, 0.1, 0.1, 1.0).toHexString());
    }
    
    static public function goToRoom(target:String):Void
    {
        var name:RoomName = cast target;
        if (target.indexOf(".") != -1)
        {
            final split = target.split(".");
            split.pop();
            name = cast split.join(".");
        }
        
        final constructor = roomTypes.exists(name) ? roomTypes[name] : RoomState.new;
        FlxG.switchState(constructor(target));
    }
}

