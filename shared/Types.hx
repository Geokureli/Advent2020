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
