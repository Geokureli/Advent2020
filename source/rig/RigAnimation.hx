package rig;

import openfl.display.MovieClip;

class RigAnimation
{
    public var name:String;
    public var start:Int;
    public var end:Int;
    public var frames:Array<Frame>;
    public var loops:Bool;
    
    public function new (name, start, end = -1)
    {
        loops = StringTools.endsWith(name, "_loop");
        if (loops)
        {
            var split = name.split("_");
            split.pop();
            name = split.join("_");
        }
        this.name = name;
        this.start = start;
        this.end = end;
        frames = [];
    }
    
    public function pushFrameFrom(parent:MovieClip)
    {
        frames.push(Frame.fromParent(parent));
    }
}

@:forward
abstract Frame(Map<Limb, LimbFrameData>)
{
    inline public function new () { this = new Map(); }
    
    inline public function toString() return toDelimitedString;
    
    public function toDelimitedString(delimiter = "; ")
    {
        var string = "";
        for (limb=>data in this)
            string += '$limb=>${limbDataToString(data)}$delimiter';
        
        return string;
    }
    
    function limbDataToString(data:LimbFrameData)
    {
        inline function FLOAT(value:Float) return Math.round(value * 100) / 100;
        
        return '(${FLOAT(data.x)},${FLOAT(data.y)}) x(${FLOAT(data.xScale)},${FLOAT(data.yScale)}) @${FLOAT(data.rotation)}';
    }
    
    @:arrayAccess
    inline public function get(key) return this[key];
    
    @:arrayAccess
    inline public function set(key, value) return this[key] = value;
    
    static public function fromParent(parent:MovieClip)
    {
        var frame = new Frame();
        
        for (i in 0...parent.numChildren)
        {
            var child = cast (parent.getChildAt(i), MovieClip);
            var limb = Limb.lowerCaseAs(child.name);
            if (limb == null)
                throw 'invalid limb:${child.name}';
            
            if (frame.exists(limb))
                throw 'duplicate limb:$limb';
            
            frame[limb] =
                { x       :child.x
                , y       :child.y
                , xScale  :child.scaleX
                , yScale  :child.scaleY
                , rotation:child.rotation
                };
        }
        
        return frame;
    }
}

typedef LimbFrameData =
{
    var x:Float;
    var y:Float;
    var xScale:Float;
    var yScale:Float;
    var rotation:Float;
}