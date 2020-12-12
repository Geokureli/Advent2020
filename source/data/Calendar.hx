package data;

class Calendar
{
    #if debug
    inline static var DEBUG_DAY:Int = 0;// 0 to disable debug feature
    static public var isDebugDay = DEBUG_DAY > 0;
    #else
    static public var isDebugDay = false;
    #end
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
        inline function setDebugDayAndCall(debugDay:Int)
        {
            setDebugDay(debugDay);
            if (callback != null)
                callback();
        }
        
        #if FORCE_INTRO
        setDebugDayAndCall(1);
        #elseif debug
        if (DEBUG_DAY > 0)
            setDebugDayAndCall(DEBUG_DAY);
        else
        #end
            NGio.checkNgDate(()->onDateReceived(NGio.ngDate, callback));
    }
    
    static function setDebugDay(debugDay:Int)
    {
        day = debugDay;
        isAdvent = true;
        isDecember = true;
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