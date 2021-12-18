package utils;

import flixel.FlxSprite;
import flixel.math.FlxVector;

class DebugLine extends FlxSprite
{
    public var x1(get, set):Float;
    public var y1(get, set):Float;
    public var x2(default, set):Float;
    public var y2(default, set):Float;
    public var thickness(get, set):Int;
    
    inline public function get_x1() return x;
    inline public function set_x1(value:Float) { set(value, y1, x2, y2); return value; }
    
    inline public function get_y1() return y;
    inline public function set_y1(value:Float) { set(x1, value, x2, y2); return value; }
    
    inline public function set_x2(value:Float) { setEnd(value, y2); return value; }
    inline public function set_y2(value:Float) { setEnd(x2, value); return value; }
    
    inline public function get_thickness() return frameHeight;
    inline public function set_thickness(value:Int)
    {
        makeGraphic(100, value);
        origin.set(value / 2, value / 2);
        offset.set(value / 2, value / 2);
        setEnd(x2, y2);
        return value;
    }
    
    public function new (x = 0, y = 0, x2 = 0, y2 = 0, thickness = 2, color = 0xFFffffff)
    {
        super(x, y);
        @:bypassAccessor
        this.x2 = x2;
        @:bypassAccessor
        this.y2 = y2;
        set_thickness(thickness);
        this.color = color;
        #if debug
        this.ignoreDrawDebug = true;
        #end
    }
    
    public function set(x:Float, y:Float, x2:Float, y2:Float)
    {
        this.x = x;
        this.y = y;
        setEnd(x2, y2);
    }
    
    public function setEnd(x2:Float, y2:Float)
    {
        var line = FlxVector.get(x2 - x, y2 - y);
        setGraphicSize(Std.int(Math.max(line.length, 1)), Std.int(thickness));
        @:bypassAccessor this.x2 = x2;
        @:bypassAccessor this.y2 = y2;
        angle = line.degrees;
        line.put();
    }
}