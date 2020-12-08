package states.rooms;

import flixel.math.FlxMath;

class ArcadeState extends RoomState
{
    override function create()
    {
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