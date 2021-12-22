package data;

import flixel.FlxG;

enum abstract Order(String) to String
{
    inline static public final NUM_FRAMES = 2;
    
    static public final list = [DINNER, COFFEE];
    
    var RANDOM = null;
    var DINNER = "dinner";
    var COFFEE = "coffee";
    
    public function toInt()
    {
        return this == null ? 0 : list.indexOf(cast this) + 1;
    }
    
    public function toFrame(percentFull:Float = 1.0)
    {
        switch (cast this:Order)
        {
            case RANDOM: throw "no frame for order:RANDOM";
            case order: 
                trace('${order.toInt() - 1} * 2 + ${Math.ceil(percentFull * (NUM_FRAMES - 1))}'
                    + ' = ${(order.toInt() - 1) * NUM_FRAMES + Math.ceil(percentFull * (NUM_FRAMES - 1))}');
                return (order.toInt() - 1) * NUM_FRAMES + Math.ceil(percentFull * (NUM_FRAMES - 1));
        }
    }
    
    static public function fromInt(i:Int)
    {
        return i == 0 ? RANDOM : list[i - 1];
    }
    
    static public function random() return FlxG.random.getObject(list);
}