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

import openfl.filters.ShaderFilter;

class BedroomState extends RoomState
{
    var dresser:OgmoDecal;
    var dresserNotif:Notif;
    
    override function create()
    {
        // GameSize.setPixelSize(4);
        super.create();
        
        if(Game.state == NoEvent)
            Manifest.playMusic("albegian");
        
        // #if debug FlxG.debugger.drawDebug = true; #end
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        var door = background.getByName("door");
        door.animation.add("open", [0]);
        door.animation.add("closed", [1]);
        door.animation.play("closed");
        
        dresser = foreground.getByName("dresser");
        dresser.setBottomHeight(16);
        addHoverTextTo(dresser, "DRESS UP", onOpenDresser);
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