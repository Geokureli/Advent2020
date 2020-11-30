package props;

import flixel.FlxSprite;

import states.OgmoState;

typedef PresentValues = { id:String }

@:forward
abstract Present(OgmoDecal) from FlxSprite to OgmoDecal
{
    public function new (id:String, x = 0.0, y = 0.0)
    {
        this = new FlxSprite(x, y);
        this.loadGraphic('assets/images/props/presents/${id}.png', true, 32, 34);
        this.animation.add("closed", [0]);
        this.animation.add("opened", [1]);
        this.animation.play("closed");
    }
    
    inline public function open() this.animation.play("opened");
    inline public function close() this.animation.play("closed");
    
    static public function fromEntity(data:OgmoEntityData<PresentValues>)
    {
        return new Present(data.values.id, data.x - data.width / 2, data.y - data.height / 2);
    }
}