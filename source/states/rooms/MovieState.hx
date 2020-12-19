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
        addHoverTextTo(screen, "watch", watchMovie);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
    
    function watchMovie()
    {
        openSubState(new VideoSubstate("assets/movies/snackers.mp4"));
    }
    
    inline static var GRID_LEFT = 88;
    inline static var GRID_TOP = 164;
    inline static var GRID_BOTTOM = 320;
    inline static var GRID_COL = 16;
    inline static var GRID_ROW = 32;
    
    override function onAvatarAdd(data:Avatar, key:String)
    {
        super.onAvatarAdd(data, key);
        
        if (ghostsById.exists(key))
        {
            var ghost = ghostsById[key];
            ghost.cancelTargetPos();
            final gridRight = FlxG.worldBounds.right - GRID_LEFT;
            final gridB = FlxG.worldBounds.right - GRID_LEFT;
            ghost.x = GRID_LEFT + GRID_COL * FlxG.random.int(0, Std.int((gridRight - GRID_LEFT) / GRID_COL));
            ghost.y = GRID_TOP + GRID_ROW * FlxG.random.int(0, Std.int((GRID_BOTTOM - GRID_TOP) / GRID_ROW));
        }
        data.onChange = (_)->{};
    }
}