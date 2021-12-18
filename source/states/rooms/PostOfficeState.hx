package states.rooms;

import states.OgmoState;
import flixel.FlxSprite;

import flixel.text.FlxBitmapText;

import props.Note;

class PostOfficeState extends RoomState
{
    var mail:FlxSprite;
    var mindchamberText = new FlxBitmapText();
    
    var robot:FlxSprite;
    var pbotText = new FlxBitmapText();
    
    var note:Note;
    
    override function create()
    {
        entityTypes["Note"] = cast function(data)
        {
            note = Note.fromEntity(data);
            note.visible = false;
            return note;
        }
        
        super.create();
    }
    
    override function initEntities()
    { 
        super.initEntities();
        
        foreground.remove(note);
        topGround.add(note);
        
        var robot = npcsByName["P-Bot"];
        if (robot == null)
            throw "Missing P-Bot";
        
        //hacky fix, for now
        robot.hitboxOffset.y = 16;
        addHoverTextTo(robot, "LETTER", () -> note.visible = !note.visible);
        note.camera = topWorldCamera;
    }
    
    // override function update(elapsed:Float) { super.update(elapsed); }
}
