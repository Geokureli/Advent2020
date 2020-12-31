package states.rooms;

import ui.DjUi;
import flixel.FlxG;
import schema.GameState;

import io.colyseus.Room;
import io.colyseus.serializer.schema.Schema;

class DanceState extends RoomState
{
    override function create()
    {
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        #if debug
        if (FlxG.keys.justPressed.H)
            ui.add(new DjUi());
        #end
    }
    
    override function onRoomJoin(error:String, room:Room<GameState>)
    {
        super.onRoomJoin(error, room);
        
        if (error != null)
            room.state.onChange = onStateChange;
    }
    
    function onStateChange(changes:Array<DataChange>)
    {
    }
}