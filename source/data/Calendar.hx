package data;

class Calendar
{
    inline static var DEBUG_DAY:Int = 0;// 0 to disable debug feature
    static public var isDebugDay = DEBUG_DAY > 0;
    static public var isPast(default, null) = false;
    static public var participatedInAdvent(default, null) = false;
    static public var day(default, null) = 24;
    static public var hanukkahDay(default, null) = 7;
    static public var isAdvent(default, null) = false;
    static public var isDecember(default, null) = false;
    static public var isChristmas(default, null) = false;
    static public var isUnseenDay(default, null) = false;
    static public function init(callback:()->Void = null):Void
    {
        if (DEBUG_DAY == 0)
        {
            NGio.checkNgDate(()->onDateReceived(NGio.ngDate, callback));
        }
        else
        {
            day = DEBUG_DAY;
            isAdvent = true;
            isDecember = true;
        }
    }
    
    static function onDateReceived(date:Date, callback:()->Void):Void
    {
        isDecember = date.getMonth() == 11;
        isChristmas = date.getDate() == 25;
        
        if (isDecember)// && date.getFullYear() == 2019)
        {
            hanukkahDay = date.getDate() - 10;
            if (date.getDate() < 26)
            {
                isAdvent = true;
                day = date.getDate();
                isUnseenDay = !Save.hasSeenDay(day);
                Save.daySeen(day);
            }
        }
        
        callback();
    }
    
    @:allow(states.BootState)
    static function canSkip()
    {
        return isAdvent && day != 32 && NGio.isContributor;
    }
    
    @:allow(states.BootState)
    static function showDebugNextDay():Void
    {
        day++;
        isDebugDay = true;
        isUnseenDay = !Save.hasSeenDay(day);
    }
}