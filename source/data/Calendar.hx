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
}