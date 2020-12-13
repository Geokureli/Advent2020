package data;

import data.Content;
import states.rooms.RoomState;
import utils.BitArray;

import flixel.math.FlxPoint;

typedef Location = { room:String, pos:FlxPoint }

class Lucia
{
    inline public static var TOTAL = 99;
    inline public static var USER = User.midgetsausage;
    
    public static var active(get, never):Bool;
    inline static function get_active() return Game.state.match(LuciaDay(_));
    public static var finding(get, never):Bool;
    inline static function get_finding() return Game.state.match(LuciaDay(Finding));
    public static var present(get, never):Bool;
    inline static function get_present() return Game.state.match(LuciaDay(Present));
    public static var collected(default, null) = 0;
    public static var timer = 0.0;
    public static var presentLoc:Location = null;
    
    static var roomTotals = new Map<RoomName, Int>();
    static var roomCollected = new Map<RoomName, BitArray>();
    static var roomCleared = new Map<RoomName, Bool>();
    static var debugSkipped = false;
    
    static public function update(elapsed:Float)
    {
        timer += elapsed;
    }
    
    static public function reset()
    {
        roomTotals.clear();
        roomCollected.clear();
        roomCleared.clear();
        debugSkipped = false;
        presentLoc = null;
        timer = 0.0;
        collected = 0;
    }
    
    static public function debugSkip()
    {
        debugSkipped = true;
        collected = 98;
    }
    
    static public function onComplete(room:RoomName, pos:FlxPoint)
    {
        presentLoc = { room:room, pos:pos };
        if (!debugSkipped)
            NGio.postPlayerHiscore("Hot Bun Run", Math.floor(timer * 1000));
    }
    
    static public function isCleared(room:RoomName)
    {
        return roomCleared.exists(room) && roomCleared[room];
    }
    
    static public function initRoom(room:RoomName, count:Int)
    {
        if (!roomTotals.exists(room))
        {
            roomTotals[room] = count;
            roomCollected[room] = new BitArray();
            roomCleared[room] = false;
        }
    }
    
    /**
     * called to notify a lucia was collected
     * @param room  The room it was collected
     * @param index the index of the collected bun
     * @return the amount remaining.
     */
    static public function collect(room:RoomName, index:Int):Int
    {
        var local = roomCollected[room];
        if (!isCollected(room, index))
        {
            local[index] = true;
            roomCollected[room] = local;
            collected++;
        }
        
        var collected = local.countTrue();
        if (collected == roomTotals[room])
            roomCleared[room] = true;
        
        return roomTotals[room] - collected;
    }
    
    static public function isCollected(room:RoomName, index:Int)
    {
        var local = roomCollected[room];
        return roomCollected[room][index];
    }
    
    static public function getDisplayTimer()
    {
        final seconds = Math.floor(timer % 60);
        return Math.floor(timer / 60) + ":" + (seconds < 10 ? "0" : "") + seconds;
    }
}