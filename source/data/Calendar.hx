package data;

class Calendar
{
    #if debug
    /**
     * Decides what day it is, use SERVER to use NG time, otherwise pick a day to test.
     * NOTE: you should only use LIVE to test medal unlocks
     */
    static final GAME_DATE:GameDate
        // = SERVER;
        = DAY(1, LIVE);
        // = STRING("2021-12-04", DEBUG);
    #end
    static public var isDebugDay = false;
    static public var isPast(default, null) = false;
    static public var participatedInAdvent(default, null) = false;
    static public var day(default, null) = 32;
    static public var hanukkahDay(default, null) = 7;
    static public var isAdvent(default, null) = false;
    static public var isDecember(default, null) = false;
    static public var isChristmas(default, null) = false;
    static public var isUnseenDay(default, null) = false;
    static public function init(callback:()->Void):Void
    {
        #if debug
        if (GAME_DATE != SERVER)
            setDebugDay(callback);
        else
        #end
            NGio.checkNgDate(()->onDateReceived(NGio.ngDate, callback));
    }
    
    #if debug
    inline static function setDebugDay(callback:()->Void)
    {
        isDebugDay = GAME_DATE.match(DAY(_, DEBUG) | STRING(_, DEBUG));
        
        switch(GAME_DATE)
        {
            case DAY(32, _):
                onDateReceived(Date.fromString("2022-01-01"), callback);
            case DAY(n, _) if (n < 10):
                onDateReceived(Date.fromString('2021-12-0$n'), callback);
            case DAY(n, _):
                onDateReceived(Date.fromString('2021-12-$n'), callback);
            case STRING(date, _):
                onDateReceived(Date.fromString(date), callback);
            case SERVER: throw "Unexpected DEBUG_DAY:ServerDate";
        }
    }
    #end
    
    static function onDateReceived(date:Date, callback:()->Void):Void
    {
        trace("month:" + date.getMonth(), "day:" + date.getDate());
        isAdvent = date.getMonth() == 11 || (date.getMonth() == 0 && date.getDate() == 1);
        isChristmas = date.getMonth() == 11 && date.getDate() == 25;
        
        if (isAdvent)// && date.getFullYear() == 2019)
        {
            day = date.getDate() + (date.getMonth() == 11 ? 0 : 31);
            #if FORGET_TODAY
            Save.debugForgetDay(day);
            #end
            isUnseenDay = !Save.hasSeenDay(day);
            Save.daySeen(day);
        }
        
        callback();
    }
    
    @:allow(states.BootState)
    static function canSkip()
    {
        return isAdvent && day != 32 && NGio.isContributor
            #if debug && GAME_DATE == SERVER #end;
    }
    
    @:allow(states.BootState)
    static function showDebugNextDay():Void
    {
        day++;
        isDebugDay = true;
        isUnseenDay = !Save.hasSeenDay(day);
    }
}

enum DateDebugLevel
{
    LIVE;
    DEBUG;
}
enum GameDate
{
    /** Whatever date the NG server says. */
    SERVER;
    /** The Nth day of advent, 2021 */
    DAY(num:Int, level:DateDebugLevel);
    /** example "2021-12-1" */
    STRING(date:String, level:DateDebugLevel);
}