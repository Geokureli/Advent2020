package utils;

import haxe.Int64;

abstract BitArray(Int64) from Int64 to Int64
{
    static var LOG_2:Float = Math.log(2);
    
    inline public function new (value = 0)
    {
        this = value;
    }
    
    public function getLength():Int
    {
        if (this.high < 0)
            return 64;
        if (this.high > 0)
            return Math.floor(Math.log(this.high) / LOG_2) + 33;
        else if (this.low < 0)
            return 32;
        else if (this.low == 0)
            return 0;
        else
            return Math.floor(Math.log(this.low) / LOG_2) + 1;
    }
    
    public function countTrue():Int
    {
        var i = getLength();
        var count = 0;
        while (i-- > 0) if (get(i)) count++;
        return count;
    }
    
    inline public function reset():Void
    {
        this = 0;
    }
    
    @:arrayAccess
    inline public function get(key:Int):Bool
    {
        var part = this.low;
        if (key >= 32)
        {
            key -= 32;
            part = this.high;
        }
        return toBool((part >> key) & 1);
    }
    
    @:arrayAccess
    inline public function arrayWrite(key:Int, value:Bool):Bool
    {
        if (key >= 63)
            throw "Cannot have 63 or more bits";
        
        this = (this & ~((1:Int64) << key)) | ((toInt(value):Int64) << key);
        return value;
    }
    public function toString():String
    {
        var str = "";
        var copy:Int64 = this.copy();
        while (copy != 0)
        {
            str = Std.string(copy & 1) + str;
            copy >>= 1;
        }
        
        return str == "" ? "0" : str;
    }
    
    inline static function toBool(value:Int) return value == 1;
    
    inline static function toInt(value:Bool) return value ? 1 : 0;
    
    /** for debugging */
    inline static public function fromString(value:String):BitArray
    {
        inline function intFromChar(char:String):Int64
            return (char == "0" ? 0 : 1);
        
        var int:Int64 = intFromChar(value.charAt(0));
        
        for (i in 1...value.length)
        {
            int <<= 1;
            int |= intFromChar(value.charAt(i));
        }
        
        return int;
    }
}