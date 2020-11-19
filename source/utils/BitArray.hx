package utils;

abstract BitArray(Int) from Int to Int
{
    static var LOG_2:Float = Math.log(2);
    
    inline public function new (value = 0)
    {
        this = value;
    }
    
    public function getLength():Int
    {
        return Math.floor(Math.log(this) / LOG_2) + 1;
    }
    
    inline public function reset():Void
    {
        this = 0;
    }
    
    @:arrayAccess
    inline public function get(key:Int):Bool
    {
        return toBool((this >> key) & 1);
    }
    
    @:arrayAccess
    inline public function arrayWrite(key:Int, value:Bool):Bool
    {
        this = (this & ~(1 << key)) | (toInt(value) << key);
        return value;
    }
    public function toString():String
    {
        var str = "";
        var copy:Int = this;
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
        inline function intFromChar(char:String):Int
            return (char == "0" ? 0 : 1);
        
        var int = intFromChar(value.charAt(0));
        
        for (i in 1...value.length)
        {
            int <<= 1;
            int |= intFromChar(value.charAt(i));
        }
        
        return int;
    }
}