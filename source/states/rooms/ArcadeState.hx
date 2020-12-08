package states.rooms;

import data.Calendar;
import data.Game;
import data.Content;
import props.Cabinet;

import flixel.math.FlxMath;

class ArcadeState extends RoomState
{
    override function create()
    {
        entityTypes["Cabinet"] = cast function(data)
        {
            var cabinet = Cabinet.fromEntity(data);
            if (cabinet.enabled)
                addHoverTextTo(cabinet, cabinet.data.name, ()->Game.goToArcade(cast cabinet.data.id));
            
            return cabinet;
        }
        
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        for (light in foreground.getAllWithName("light"))
        {
            topGround.add(light);
            foreground.remove(light);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}