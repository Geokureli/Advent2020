abstract NetBits(Int) from Int
{
    inline static var TOTAL = 8;
    inline static function checkMax(i:Int)
    {
        #if debug
        // only check in debug so we get errors when we add new ones
        // to force check all properties, create a toString that outputs all values
        // and call it in debug in the constrctor
        if (i > TOTAL) throw 'bit:$i is too high';
        #end
    }
    
    inline public function new (value:Int) this = value;
    
    inline public function getBool(i:Int)
    {
        checkMax(i);
        return 1 == (this >> i) & 1;
    }
    
    inline public function setBool(i:Int, value:Bool)
    {
        this = (this & ~(1 << i)) | ((value ? 1 : 0) << i);
        return value;
    }
    
    static var LG = Math.log(2);
    inline static function ceilPow2(num)
    {
        return 1 << Math.ceil(Math.log(num)/LG);
    }
    
    inline public function getBits(i:Int, numBits:Int):NetBits
    {
        return getInt(i, numBits);
    }
    
    inline public function setBits(i:Int, numBits:Int, value:NetBits)
    {
        return setInt(i, numBits, cast value);
    }
    
    inline public function getInt(i:Int, numBits:Int)
    {
        checkMax(i + numBits - 1);
        final bitmask = (1 << numBits) - 1;
        return (this >> i) & bitmask;
    }
    
    inline public function setInt(i:Int, numBits:Int, value:Int)
    {
        if (Math.ceil(Math.log(value + 1) / LG) > numBits)
            throw '$value is too high, max:${1 << numBits}';
        
        final bitmask = (1 << numBits) - 1;
        return this = (this & ~(bitmask << i)) | (value << i);
    }
    
    public function toString()
    {
        var copy = this;
        var str = "";
        while (copy != 0)
        {
            str = Std.string(copy & 1) + str;
            copy >>= 1;
        }
        
        return str;
    }
}