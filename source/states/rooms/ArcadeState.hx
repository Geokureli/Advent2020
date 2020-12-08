package states.rooms;

import data.Calendar;
import data.Game;
import data.Content;
import props.Cabinet;
import ui.Prompt;

import flixel.FlxG;
import flixel.math.FlxMath;

class ArcadeState extends RoomState
{
    override function create()
    {
        entityTypes["Cabinet"] = cast function(data)
        {
            var cabinet = Cabinet.fromEntity(data);
            if (cabinet.enabled)
                addHoverTextTo(cabinet, cabinet.data.name, playCabinet.bind(cabinet.data));
            
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
    
    function playCabinet(data:ArcadeCreation)
    {
        if (FlxG.onMobile)
            Prompt.showOKInterrupt("This game is not available on mobile\n...yet.");
        else
            Game.goToArcade(cast data.id);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}