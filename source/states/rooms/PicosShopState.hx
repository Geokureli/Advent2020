package states.rooms;

import data.Calendar;
import data.Content;
import data.Game;
import data.Manifest;
import data.Skins;
import props.Cabinet;
import props.Notif;
import props.SpeechBubble;
import states.OgmoState;
import ui.Prompt;

import flixel.FlxG;
import flixel.math.FlxMath;

class PicosShopState extends RoomState
{
    var changingRoom:OgmoDecal;
    var changingRoomNotif:Notif;
    var picoBubble:SpeechBubbleQueue;
    
    override function create()
    {
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        var pico = npcsByName["Pico"];
        if (pico == null)
            throw 'Missing pico npc';
        addHoverTextTo(pico, "TALK", startPicoChat);
        pico.hitbox.width += 56;
        pico.hitboxOffset.x -= 24;
        
        
        changingRoom = foreground.getByName("changing-room-door");
        changingRoom.setBottomHeight(16);
        addHoverTextTo(changingRoom, "CHANGE CLOTHES", onOpenDresser);
        changingRoomNotif = new Notif();
        changingRoomNotif.x = changingRoom.x + (changingRoom.width - changingRoomNotif.width) / 2;
        changingRoomNotif.y = changingRoom.y + changingRoom.height - changingRoom.frameHeight;
        changingRoomNotif.animate();
        topGround.add(changingRoomNotif);
        
        if (!Skins.checkHasUnseen())
            changingRoomNotif.kill();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
    
    function startPicoChat()
    {
        if (picoBubble == null)
        {
            var pico = npcsByName["Pico"];
            picoBubble = new SpeechBubbleQueue(pico.x, pico.y - 48);
            picoBubble.advanceTimer = 1.0;
            picoBubble.allowSkip = false;
            picoBubble.allowCancel = false;
            picoBubble.camera = topWorldCamera;
            add(picoBubble);
            picoBubble.showMsgQueue
            (   [ "Welcome!"
                , "Try on anything you like."
                ]
            ,   function onComplete()
                {
                    remove(picoBubble);
                    picoBubble = null;
                }
            );
        }
    }
    
    function onOpenDresser()
    {
        changingRoomNotif.visible = false;
        var dressUp = new DressUpSubstate();
        dressUp.closeCallback = function()
        {
            player.settings.applyTo(player);
        }
        openSubState(dressUp);
    }
}