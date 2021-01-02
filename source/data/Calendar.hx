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
        
        #if debug
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
        #if FORGET_TODAY
        Save.debugForgetDay(day);
        #end
    }
    
    static function onDateReceived(date:Date, callback:()->Void):Void
    {
        trace("month:" + date.getMonth(), "day:" + date.getDate());
        isAdvent = date.getMonth() == 11 || (date.getMonth() == 0 && date.getDate() == 1);
        isChristmas = date.getMonth() == 11 && date.getDate() == 25;
        
        if (isAdvent)// && date.getFullYear() == 2019)
        {
            day = date.getDate() + (date.getMonth() == 11 ? 1 : 31);
            #if FORGET_TODAY
            Save.debugForgetDay(day);
            #end
            isUnseenDay = !Save.hasSeenDay(day);
            Save.daySeen(day);
        }
        else
            day = 32;
        
        callback();
    }
    
    @:allow(states.BootState)
    static function canSkip()
    {
        return isAdvent && day != 32 && NGio.isContributor
            #if debug && DEBUG_DAY == 0 #end;
    }
    
    @:allow(states.BootState)
    static function showDebugNextDay():Void
    {
        day++;
        isDebugDay = true;
        isUnseenDay = !Save.hasSeenDay(day);
    }
}