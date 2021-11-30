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
    static public var chosenSong:String = null;
    
    static var roomTypes:Map<RoomName, RoomConstructor>;
    static var arcadeTypes:Map<ArcadeName, ()->FlxState>;
    static public var allowShaders(default, null):Bool = true;
    static public var disableShaders(get, never):Bool;
    inline static function get_disableShaders() return !allowShaders;
    
    public static var initialRoom(default, null) = 
        #if debug
        RoomName.Outside;
        // RoomName.PicosShop + "." + RoomName.Village;
        #else
        RoomName.Outside;
        #end
    
    static function init():Void
    {
        #if js
        allowShaders = switch(FlxG.stage.window.context.type)
        {
            case OPENGL, OPENGLES, WEBGL: true;
            default: false;
        }
        #end
        
        roomTypes = [];
        // roomTypes[Bedroom] = BedroomState.new;
        // roomTypes[Hallway] = HallwayState.new;
        // roomTypes[Entrance] = EntranceState.new;
        // roomTypes[Arcade] = ArcadeState.new;
        // roomTypes[Studio] = StudioState.new;
        // roomTypes[Movie] = MovieState.new;
        // roomTypes[Credits] = CreditsState.new;
        roomTypes[Outside] = OutsideState.new;
        roomTypes[PathLeft] = PathLeftState.new;
        roomTypes[PathCenter] = PathCenterState.new;
        roomTypes[PathRight] = PathRightState.new;
        roomTypes[Village] = VillageState.new;
        roomTypes[PicosShop] = PicosShopState.new;
        
        arcadeTypes = [];
        
        // if (Calendar.day == 13 && !Save.hasOpenedPresentByDay(13))
        //     state = LuciaDay(Started);
        // else if (Save.noPresentsOpened())
        //     state = Day1Intro(Started);
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
            case Day1Intro(Started):
            default: Content.playTodaysSong();
        }
        
        Game.goToRoom(initialRoom);
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
        Manifest.playMusic(chosenSong);
    }
}

