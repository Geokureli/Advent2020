package states.rooms;

import schema.DanceGameState;
import ui.DjUi;
import flixel.FlxG;
import schema.GameState;

import io.colyseus.Room;
import io.colyseus.serializer.schema.Schema;

class DanceState extends RoomState
{
    var state:DanceGameState = null;
    
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
            throw "join error" + error;
        else
        {
            state = cast (room.state, DanceGameState);
            state.onChange = onStateChange;
        }
    }
    
    function onStateChange(changes:Array<DataChange>)
    {
        trace("gamestate changed:");
        for (change in changes)
            trace('\t${change.field}:${change.previousValue}->${change.value}');
    }
}