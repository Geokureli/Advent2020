package props;

import flixel.FlxSprite;
import states.OgmoState;

typedef DoorValues = { open:Bool }

@:forward
class Door extends FlxSprite
{
    public var isOpen(get, never):Bool;
    inline public function get_isOpen() return animation.name == "opened";
    
    public var contents:FlxSprite;
    
    var confetti:FlxSprite;
    
    public function new (x = 0.0, y = 0.0, open = false)
    {
        super(x, y);
        loadGraphic('assets/images/props/shared/door.png', true, 43, 54);
        animation.add("opened", [0]);
        animation.add("closed", [1]);
        animation.play(open ? "opened" : "closed");
    }
    
    inline public function open() animation.play("opened");
    inline public function close() animation.play("closed");
    
    static public function fromEntity(data:OgmoEntityData<DoorValues>)
    {
        var door = new Door(data.x - 16, data.y - 17, data.values.open);
        data.applyToSprite(door);
        return door;
    }
}