package data;

import data.Content;
import data.Calendar;
import states.rooms.RoomState;
import states.rooms.*;
import ui.Controls;

import flixel.FlxG;
import flixel.FlxState;

class Game
{
    static public var room(get, never):RoomState;
    static function get_room() return Std.downcast(FlxG.state, RoomState);
    static public var arcadeName(default, null):ArcadeName = null;
    
    static public var state:EventState = NoEvent;
    
    static var roomTypes:Map<RoomName, RoomConstructor>;
    static var arcadeTypes:Map<ArcadeName, ()->FlxState>;
    
    public static var initialRoom(default, null) = 
        #if debug
        RoomName.Bedroom;
        // RoomName.Hallway + "." + RoomName.Bedroom;
        // RoomName.Entrance + "." + RoomName.Hallway;
        // RoomName.Outside + "." + RoomName.Entrance;
        // RoomName.Arcade + "." + RoomName.Entrance;
        // RoomName.Studio + "." + RoomName.Entrance;
        #else
        RoomName.Bedroom;
        #end
    
    static function init():Void
    {
        roomTypes = [];
        roomTypes[Bedroom ] = BedroomState.new;
        roomTypes[Hallway ] = HallwayState.new;
        roomTypes[Entrance] = EntranceState.new;
        roomTypes[Outside ] = OutsideState.new;
        roomTypes[Arcade  ] = ArcadeState.new;
        roomTypes[Studio  ] = StudioState.new;
        
        arcadeTypes = [];
        #if INCLUDE_DIG_GAME
        arcadeTypes[Digging] = digging.MenuState.new.bind(0);
        #end
        
        if (Calendar.day == 13 && !Save.hasOpenedPresentByDay(13))
            state = LuciaDay(Started);
        else if (Save.noPresentsOpened())
            state = Day1Intro(Started);
        
        #if FORCE_LUCIA
        state = LuciaDay(Started);
        #elseif FORCE_INTRO
        state = Day1Intro(Started);
        #end
    }
    
    static public function goToRoom(target:String):Void
    {
        var name:RoomName = cast target;
        if (target.indexOf(".") != -1)
        {
            final split = target.split(".");
            split.pop();
            name = cast split.join(".");
        }
        
        final constructor = roomTypes.exists(name) ? roomTypes[name] : RoomState.new;
        Net.safeLeaveCurrentRoom();
        FlxG.switchState(constructor(target));
    }
    
    @:allow(states.BootState)
    inline static function goToInitialRoom()
    {
        init();
        Controls.init();
        
        switch (Game.state)
        {
            case NoEvent: Content.playTodaysSong();
            // case Day1Intro(Started):
            default:
        }
        
        #if SKIP_TO_DIG_GAME
        Game.goToArcade(Digging);
        #else
        Game.goToRoom(initialRoom);
        #end
    }
    
    static public function goToArcade(name:ArcadeName):Void
    {
        if (!arcadeTypes.exists(name))
            throw "No constructor found for arcade:" + name;
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        
        arcadeName = name;
        FlxG.switchState(arcadeTypes[name]());
    }
    
    static public function exitArcade():Void
    {
        goToRoom(Arcade + "." + arcadeName);
        
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        Content.playTodaysSong();
    }
}

