package states.rooms;

import flixel.FlxG;
import schema.Avatar;

class MovieState extends RoomState
{
    override function create()
    {
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        var screen = background.getByName("screen");
        if (screen == null)
            throw "missing screen";
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        
    }
    
    inline static var GRID_LEFT = 88;
    inline static var GRID_TOP = 168;
    inline static var GRID_BOTTOM = 320;
    inline static var GRID_COL = 16;
    inline static var GRID_ROW = 32;
    
    override function onAvatarAdd(data:Avatar, key:String)
    {
        super.onAvatarAdd(data, key);
        
        if (ghostsById.exists(key))
        {
            var ghost = ghostsById[key];
            ghost.cancelTargetPos()
            final gridRight = FlxG.worldBounds.right - GRID_LEFT;
            final gridB = FlxG.worldBounds.right - GRID_LEFT;
            // ghost.x = GRID_LEFT + GRID_COL * FlxG.random.int(GRID_RIGHT
        }
        data.onChange = null;
    }
}