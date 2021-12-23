package props;

import flixel.FlxObject;

import states.OgmoState;

typedef TeleportValues = { target:String, id:String, isDefault:Bool, enabled:Bool };

class Teleport extends FlxObject
{
    public var id:String = null;
    public var target:String = null;
    public var enabled(get, set):Bool;
    inline function get_enabled() return solid;
    inline function set_enabled(value:Bool) return solid = value;
    
    public function new(x = 0.0, y = 0.0, width = 0.0, height = 0.0)
    {
        super(x, y, width, height);
    }
    
    static public function fromEntity(data:OgmoEntityData<TeleportValues>)
    {
        var teleport = new Teleport();
        data.applyToObject(teleport);
        final values = data.values;
        teleport.id = values.id;
        teleport.target = values.target;
        teleport.solid = values.enabled;
        return teleport;
    }
}