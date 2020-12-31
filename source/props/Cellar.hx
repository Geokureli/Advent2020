package props;

import data.Calendar;
import data.Content;
import data.Manifest;
import data.Save;
import states.OgmoState;

import flixel.FlxSprite;

typedef TeleportValues = { target:String, id:String };

class Cellar extends FlxSprite
{
    public var id:String = null;
    public var target:String = null;

    public function new (id:String, x = 0.0, y = 0.0)
    {
        super(x, y);
        
        final path = 'assets/images/props/outside/cellar.png';
        loadGraphic(path, true, 40, 60);
        (this:OgmoDecal).setBottomHeight(this.frameHeight / 4);
        immovable = true;
    }
    
    static public function fromEntity(data:OgmoEntityData<TeleportValues>)
    {
        var teleport = new Cellar();
        data.applyToObject(teleport);
        final values = data.values;
        teleport.id = values.id;
        teleport.target = values.target;
        return teleport;
    }
}