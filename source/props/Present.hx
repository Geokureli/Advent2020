package props;

import states.OgmoState;

typedef PresentValues = { id:String }

@:forward
class Present extends flixel.FlxSprite
{
    public final id:String;
    public function new (id:String, x = 0.0, y = 0.0)
    {
        this.id = id;
        super(x, y);
        loadGraphic('assets/images/props/presents/${id}.png', true, 32, 34);
        animation.add("closed", [0]);
        animation.add("opened", [1]);
        animation.play("closed");
        (this:OgmoDecal).setBottomHeight(this.frameHeight >> 1);
        drag.set(5000, 5000);
    }
    
    inline public function open() animation.play("opened");
    inline public function close() animation.play("closed");
    
    static public function fromEntity(data:OgmoEntityData<PresentValues>)
    {
        return new Present(data.values.id, data.x - 16, data.y - 17);
    }
}