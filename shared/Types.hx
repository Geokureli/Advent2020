package;

@:structInit
class GState
{
    public var avatars:Map<String, AvatarState>;
}

@:structInit
class AvatarState
{
    public var id:String;
    public var x:Float;
    public var y:Float;
    public var skin:Int;
    public var emote:EmoteType;
    public var netState:PlayerNetState;
    public var state:PlayerState;
}

abstract PlayerState(NetBits) from Int
{
    inline public function new (value = 0)
    {
        this = new NetBits(value);
        // #if debug
        // verifies max bit
        @:keep
        toString();
        // #end
    }
    
    public var flipped(get, set):Bool;
    inline function get_flipped() return this.getBool(0);
    inline function set_flipped(value:Bool) return this.setBool(0, value);
    
    public var infected(get, set):Bool;
    inline function get_infected() return this.getBool(1);
    inline function set_infected(value:Bool) return this.setBool(1, value);
    
    public function toString()
    {
        return '{ flipped:$flipped, infected:$infected }';
    }
    
    inline public function toBinaryString() return this.toString();
}

enum abstract PlayerNetState(Int)
{
    var Joining;
    var Idle;
    var Leaving;
}

enum abstract EmoteType(Int)
{
    var None;
    var Smooch;
}
