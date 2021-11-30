package states.rooms;

import flixel.ui.FlxVirtualPad;
import data.Calendar;
import data.Content;
import data.EventState;
import data.Game;
import data.Lucia;
import data.NGio;
import data.Save;
import data.Skins;
import props.Door;
import props.InfoBox;
import props.Notif;
import props.Note;
import states.OgmoState;
import states.ToyBoxState;
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
    var door:Door;
    var desk:OgmoDecal;
    
    var notesById = new Map<String, Note>();
    
    override function create()
    {
        entityTypes["Note"] = cast function(data)
        {
            var note = Note.fromEntity(data);
            notesById[data.values.id] = note;
            return note;
        }
        
        if(Game.state.match(Day1Intro(Started)))
            forceDay = 1;
        
        super.create();
        
        FlxG.camera.fade(FlxColor.BLACK, 1, true);
        // #if debug FlxG.debugger.drawDebug = true; #end
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        door = cast props.getByName("Door");
        
        dresser = foreground.getByName("dresser");
        dresser.setBottomHeight(16);
        addHoverTextTo(dresser, "CHANGE CLOTHES", onOpenDresser);
        dresserNotif = new Notif();
        dresserNotif.x = dresser.x + (dresser.width - dresserNotif.width) / 2;
        dresserNotif.y = dresser.y + dresser.height - dresser.frameHeight;
        dresserNotif.animate();
        topGround.add(dresserNotif);
        
        if (!Skins.checkHasUnseen())
            dresserNotif.kill();
        
        if(Game.state.match(Day1Intro(Started)))
        {
            door.close();
            addHoverTextTo(door, "Get dressed first");
            notesById["december01"].animateIn(1.5);
        }
        else if (Calendar.isUnseenDay)
        {
            var noteId = "december" + StringTools.lpad(Std.string(roomDay), "0", 2);
            if (notesById.exists(noteId))
                notesById[noteId].animateIn(1.5);
        }
        
        initLuciaDesk();
        // initChest();
    }
    
    function initLuciaDesk()
    {
        desk = foreground.getByName("desk_lucia");
        if (desk != null && Game.state.match(NoEvent|LuciaDay(Finding)|LuciaDay(Present)))
            addHoverTextTo(desk, "Replay Lucia Hunt", replayLuciaHunt);
    }
    
    function initChest()
    {
        var chest = foreground.getByName("chest");
        if (chest != null)
        {
            var notif = new Notif();
            if (NGio.hasMedalByName("butzbo") == false)
            {
                notif.x = chest.x + (chest.width - notif.width) / 2;
                notif.y = chest.y + chest.height - chest.frameHeight - notif.height;
                notif.animate();
                topGround.add(notif);
            }
            
            addHoverTextTo(chest, "Butzbo's Music Box", function()
                {
                    notif.kill();
                    // playOverlay(new ToyBoxState());
                }
            );
        }
    }
    
    function replayLuciaHunt()
    {
        var wasPlaying = Game.state.match(NoEvent);
        Game.state = LuciaDay(Started);
        Lucia.reset();
        if (luciaUi != null)
            luciaUi.kill();
        
        removeHoverFrom(desk);
        var field = new FlxBitmapText();
        field.setBorderStyle(OUTLINE, 0xFF000000);
        field.text = wasPlaying ? "Activated" : "Restarted";
        field.x = desk.x + (desk.width - field.width) / 2;
        field.y = desk.y;
        topGround.add(field);
        FlxTween.tween(field, { y:field.y - 16 }, 0.25, { ease:FlxEase.backOut });
    }
    
    function onOpenDresser()
    {
        dresserNotif.visible = false;
        var dressUp = new DressUpSubstate();
        dressUp.closeCallback = function()
        {
            player.settings.applyTo(player);
            door.open();
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
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}