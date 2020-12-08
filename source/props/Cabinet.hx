package props;

import data.Calendar;
import data.Content;
import data.Save;
import states.OgmoState;

import flixel.FlxSprite;

typedef CabinetValues = { id:String }

class Cabinet extends flixel.FlxSprite
{
    public final enabled = false;
    public final data:ArcadeCreation;
    
    public function new (id:String, x = 0.0, y = 0.0)
    {
        super(x, y);
        
        if (Content.arcades.exists(id))
        {
            data = Content.arcades[id];
            enabled = data.day <= Calendar.day;
        }
        
        if (enabled)
        {
            loadGraphic('assets/images/props/cabinets/${id}.png', true, 40, 60);
            animation.add("anim", [0, 1], 4);
            animation.play("anim");
        }
        else
            loadGraphic('assets/images/props/arcade/cabinet_broken.png');
        
        (this:OgmoDecal).setBottomHeight(this.frameHeight >> 1);
        immovable = true;
    }
    
    static public function fromEntity(data:OgmoEntityData<CabinetValues>)
    {
        var cabinet = new Cabinet(data.values.id, data.x, data.y);
        return cabinet;
    }
}