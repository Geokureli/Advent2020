package states.rooms;

import states.OgmoState;
import data.Calendar;
import data.Game;
import data.Content;
import props.Cabinet;
import ui.Prompt;

import flixel.FlxG;
import flixel.math.FlxMath;

class ArcadeState extends RoomState
{
    override function create()
    {
        entityTypes["Cabinet"] = cast initCabinet;
        
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        for (light in foreground.getAllWithName("light"))
        {
            topGround.add(light);
            foreground.remove(light);
        }
    }
    
    function initCabinet(data:OgmoEntityData<CabinetValues>)
    {
        var cabinet = Cabinet.fromEntity(data);
        if (cabinet.enabled)
            addHoverTextTo(cabinet, cabinet.data.name, playCabinet.bind(cabinet.data));
        
        return cabinet;
    }
    
    function playCabinet(data:ArcadeCreation)
    {
        if (data.mobile == false && FlxG.onMobile)
            Prompt.showOKInterrupt("This game is not available on mobile\n...yet.");
        else
        {
            switch(data.type)
            {
                case State: Game.goToArcade(cast data.id);
                case Overlay: openOverlayArcade(cast data.id);
                case External: openExternalArcade(cast data.id);
            }
        }
    }
    
    function openOverlayArcade(id:ArcadeName)
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.music = null;
        var overlay = switch(id)
        {
            case Horse: new horse.HorseSubState();
            default:
                throw "Unhandled arcade id:" + id;
        }
        overlay.closeCallback = ()->
        {
            if (FlxG.sound.music != null)
                FlxG.sound.music.stop();
            Content.playTodaysSong();
        }
        openSubState(overlay);
    }
    
    function openExternalArcade(id:ArcadeName)
    {
        var url = switch(id)
        {
            case Advent2018: "https://www.newgrounds.com/portal/view/721061";
            case Advent2019: "https://www.newgrounds.com/portal/view/743161";
            default:
                throw "Unhandled arcade id:" + id;
        }
        openUrl(url);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}