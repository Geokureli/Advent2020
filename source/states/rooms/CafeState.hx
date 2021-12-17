package states.rooms;

import props.SpeechBubble;

class CafeState extends RoomState
{
    override function create()
    {
        super.create();
        
        #if LOAD_DISK_CAROUSEL
        var juke = foreground.assertByName("cafe-juke");
        addHoverTextTo(juke, "Music", ()->openSubState(new MusicSelectionSubstate()));
        #end
    }
    
    // override function initEntities() { super.initEntities(); }

    // override function update(elapsed:Float) { super.update(elapsed); }
}
