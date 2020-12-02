package states.rooms;

import data.NGio;
import flixel.text.FlxBitmapText;
import openfl.utils.Assets;
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
        note.setBottomHeight(note.frameHeight);
        var noteText = Assets.getText("assets/data/letter_december_01.txt");
        var name = NGio.userName;
        // if (name == null || name == "")
            name = "UNREGISTERED NG LURKER";
        noteText = noteText.split("[NAME]").join(name);
        var text = new FlxBitmapText();
        text.x = note.x + 16;
        text.y = note.y + 20;
        text.text = noteText;
        text.color = 0xFF000000;
        add(text);
        
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