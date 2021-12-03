package utils;

import haxe.Int64;

abstract BitArray(Array<UInt>) from Array<UInt> to Array<UInt>
{
    inline static var BYTE = 32;
    
    static var LOG_2:Float = Math.log(2);
    
    static public function isOldFormat(value:Any)
    {
        return Int64.isInt64(value);
    }
    
    static public function fromOldFormat(value:Int64)
    {
        if (value == 0)
            return [];
        if (value.high != 0)
            return [value.low, value.high];
        return [value.low];
    }
    
    inline public function new (value = 0)
    {
        this = [value];
    }
    
    public function getLength():Int
    {
        var len = this.length;
        return Math.floor(Math.log(this[len - 1]) / LOG_2) + (len * BYTE) + 1;
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
        this = [0];
    }
    
    @:arrayAccess
    inline public function get(key:Int):Bool
    {
        return getFromByte(Math.floor(key / BYTE), key % BYTE);
    }
    
    inline function getFromByte(i:Int, key:Int)
    {
        return i < this.length && toBool((this[i] >> key) & 1);
    }
    
    @:arrayAccess
    inline public function arrayWrite(key:Int, value:Bool):Bool
    {
        var i = Math.floor(key / BYTE);
        key = key % BYTE;
        
        if (getFromByte(i, key) != value)
        {
            while(i >= this.length)
                this.push(0);
            
            this[i] = (this[i] & ~(1 << key)) | (toInt(value) << key);
            
            while(this[this.length - 1] == 0)
                this.pop();
        }
        return value;
    }
    
    public function toString():String
    {
        var str = "";
        
        for (i in 0...this.length)
        {
            var copy = this[i];
            var byteLength = 0;
            while (copy != 0 || (i < this.length - 1 && byteLength < BYTE))
            {
                str = Std.string(copy & 1) + str;
                copy >>= 1;
                byteLength++;
            }
        }
        
        return str == "" ? "0" : str;
    }
    
    inline static function toBool(value:Int) return value == 1;
    
    inline static function toInt(value:Bool) return value ? 1 : 0;
    
    static var trim = ~/^(0*)([10]+?)0*$/;
    /** for debugging */
    static public function fromBinaryString(value:String)
    {
        if (trim.match(value) == false)
            throw 'invalid binary string: $value';
        
        var bits = new BitArray();
        var length = value.length - trim.matched(1).length;
        value = trim.matched(2);
        
        for (i in 0...value.length)
        {
            if (value.charAt(i) == "1")
                bits[length - i - 1] = true;
        }
        
        return bits;
    }
}