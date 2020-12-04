package states.rooms;

import data.Content;
import data.EventState;
import data.Game;
import data.NGio;
import data.Save;
import props.InputPlayer;
import props.InfoBox;
import props.Notif;
import props.Note;
import states.OgmoState;
import states.debug.AudioToolSubstate;
import utils.GameSize;
import vfx.PixelPerfectShader;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

import openfl.filters.ShaderFilter;
import openfl.utils.Assets;

class BedroomState extends RoomState
{
    var dresser:OgmoDecal;
    var dresserNotif:Notif;
    var door:OgmoDecal;
    
    var notesById = new Map<String, Note>();
    
    override function create()
    {
        entityTypes["Note"] = cast function(data)
        {
            var note = Note.fromEntity(data);
            notesById[data.values.id] = note;
            return note;
        }
        
        super.create();
        
        FlxG.camera.fade(FlxColor.BLACK, 1, true);
        switch (Game.state)
        {
            case NoEvent: Content.playTodaysSong();
            // case Day1Intro(Started):
            default:
        }
        // #if debug FlxG.debugger.drawDebug = true; #end
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        // notesById["december01"].animateIn();
        
        door = background.getByName("door");
        door.animation.add("close", [1]);
        door.animation.play("close");
        
        dresser = foreground.getByName("dresser");
        dresser.animation.add("closed", [0]);
        dresser.animation.add("open", [1]);
        dresser.animation.play("closed");
        dresser.setBottomHeight(16);
        addHoverTextTo(dresser, "CHANGE CLOTHES", onOpenDresser);
        dresserNotif = new Notif();
        dresserNotif.x = dresser.x + (dresser.width - dresserNotif.width) / 2;
        dresserNotif.y = dresser.y + dresser.height - dresser.frameHeight;
        dresserNotif.animate();
        add(dresserNotif);
        
        if(Game.state.match(Day1Intro(Started)))
            addHoverTextTo(door, "Get dressed first");
        else
            dresserNotif.kill();
    }
    
    function onOpenDresser()
    {
        // player.active = false;
        dresserNotif.visible = false;
        dresser.animation.play("open");
        var dressUp = new DressUpSubstate();
        dressUp.closeCallback = function()
        {
            // dresser.animation.finishCallback = null;
            // player.active = true;
            player.settings.applyTo(player);
            dresser.animation.play("closed");
        }
        openSubState(dressUp);
        
        if(Game.state.match(Day1Intro(Started)))
        {
            removeHoverFrom(door);
            Game.state = Day1Intro(Dressed);
        }
    }
    
    override function activateTeleport(target:String)
    {
        if(Game.state.match(Day1Intro(Started)))
            return;
        
        super.activateTeleport(target);
    }
}