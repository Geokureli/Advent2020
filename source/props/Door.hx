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
    
    public function new (x = 0.0, y = 0.0, isOpen = false, big = false)
    {
        super(x, y);
        if (big)
            loadGraphic('assets/images/props/shared/big_door.png', true, 50, 40);
        else
            loadGraphic('assets/images/props/shared/door.png', true, 43, 54);
        
        immovable = true;
        animation.add("opened", [0]);
        animation.add("closed", [1]);
        isOpen ? open() : close();
    }
    
    inline public function open()
    {
        animation.play("opened");
        solid = false;
    }
    inline public function close()
    {
        animation.play("closed");
        solid = true;
    }
    
    static public function fromEntity(data:OgmoEntityData<DoorValues>)
    {
        var door = new Door(data.x - 16, data.y - 17, data.values.open, data.name == "BigDoor");
        data.applyToSprite(door);
        return door;
    }
}