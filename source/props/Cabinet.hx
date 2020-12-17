package props;

import data.Calendar;
import data.Content;
import data.Manifest;
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
            final path = 'assets/images/props/cabinets/${id}.png';
            #if debug
            if (Manifest.exists(path, IMAGE))
                loadGraphic(path, true, 40, 60);
            else
                loadGraphic('assets/images/props/arcade/cabinet_ogmo.png');
            #else
            loadGraphic(path, true, 40, 60);
            #end
            animation.add("anim", [for (i in 0...animation.frames) i], 4);
            animation.play("anim");
        }
        else
            loadGraphic('assets/images/props/arcade/cabinet_broken.png');
        
        (this:OgmoDecal).setBottomHeight(this.frameHeight / 4);
        immovable = true;
    }
    
    static public function fromEntity(data:OgmoEntityData<CabinetValues>)
    {
        var cabinet = new Cabinet(data.values.id, data.x, data.y);
        return cabinet;
    }
}