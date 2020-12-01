package states.rooms;

import data.EventState;
import data.Game;
import data.Save;
import data.Manifest;
import props.InputPlayer;
import props.InfoBox;
import props.Notif;
import states.OgmoState;
import states.debug.AudioToolSubstate;
import utils.GameSize;
import vfx.PixelPerfectShader;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

import openfl.filters.ShaderFilter;

class BedroomState extends RoomState
{
    var dresser:OgmoDecal;
    var note:OgmoDecal;
    var dresserNotif:Notif;
    
    override function create()
    {
        // GameSize.setPixelSize(4);
        super.create();
        
        FlxG.camera.fade(FlxColor.BLACK, 1, true);
        switch (Game.state)
        {
            case NoEvent: Manifest.playMusic("albegian");
            // case Day1Intro(Started):
            default:
        }
        // #if debug FlxG.debugger.drawDebug = true; #end
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        note = foreground.getByName("note");
        
        dresser = foreground.getByName("dresser");
        dresser.setBottomHeight(16);
        addHoverTextTo(dresser, "CHANGE CLOTHES", onOpenDresser);
        dresserNotif = new Notif();
        dresserNotif.x = dresser.x + (dresser.width - dresserNotif.width) / 2;
        dresserNotif.y = dresser.y + dresser.height - dresser.frameHeight;
        dresserNotif.animate();
        add(dresserNotif);
    }
    
    function onOpenDresser()
    {
        dresserNotif.visible = false;
        var dressUp = new DressUpSubstate();
        dressUp.closeCallback = ()->player.settings.applyTo(player);
        openSubState(dressUp);
        
        if(Game.state.match(Day1Intro(Started)))
            Game.state = Day1Intro(Dressed);
    }
    
    override function activateTeleport(target:String)
    {
        if(Game.state.match(Day1Intro(Started)))
            return;
        
        super.activateTeleport(target);
    }
}