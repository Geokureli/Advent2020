package props;

import Types;
import data.Instrument;
import data.NGio;
import data.PlayerSettings;
import data.Save;
import ui.Button;
import ui.Controls;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class InputPlayer extends Player
{
    public var interacting = false;
    public var wasInteracting = false;
    public var touched:InfoBox = null;
    
    public var timer = 0.0;
    public var lastSend = FlxPoint.get();
    public var lastSendEmote = EmoteType.None;
    public var lastSkin = 0;
    public var lastState = new PlayerState();
    public var sendDelay = 1.0 / 6;
    
    public function new(x = 0.0, y = 0.0)
    {
        if (PlayerSettings.user == null)
            PlayerSettings.user = PlayerSettings.fromSave();
        
        super(x, y, NGio.userName, PlayerSettings.user);
        
        state.infected = NGio.hasMedalByName("warm_winter_feelings");
    }
    
    override function updateNameText(name:String)
    {
        super.updateNameText(name);
        nameText.visible = name != null && Save.showName;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (this.enabled)
        {
            timer += elapsed;
            var right   = Controls.pressed.RIGHT;
            var left    = Controls.pressed.LEFT ;
            var up      = Controls.pressed.UP   ;
            var down    = Controls.pressed.DOWN ;
            interacting = Controls.justPressed.A;
            var smooch  = Controls.justPressed.B;
            checkMouseInteracting();
            
            final mousePressed = FlxG.mouse.pressed
                && !FlxG.mouse.justPressed
                && !Button.isBlockingMouse();
            
            updateMovement(up, down, left, right, smooch, mousePressed);
        }
        else
            updateMovement(false, false, false, false, false, false);
        
        // prevents a bug on gamepads
        if (wasInteracting && interacting)
            interacting = false;
        else
            wasInteracting = interacting;
        
        Instrument.checkKeys();
    }
    
    override function set_flipX(value:Bool):Bool
    {
        state.flipped = value;
        return super.set_flipX(value);
    }
    
    function checkMouseInteracting()
    {
        if (!interacting && FlxG.mouse.justPressed)
        {
            var mouse = FlxG.mouse.getWorldPosition();
            interacting = hitbox.overlapsPoint(mouse);
            if (!interacting && touched != null)
            {
                interacting = Std.is(touched, FlxSprite)
                    ? (cast touched:FlxSprite).pixelsOverlapPoint(mouse)
                    : hitbox.overlapsPoint(mouse);
            }
        }
    }
    
    public function gotKissed(player:Player)
    {
        if (state.infected == false && (player.state.infected || player.name.toLowerCase() == "tomfulp"))
        {
            NGio.unlockMedalByName("warm_winter_feelings");
            state.infected = true;
        }
    }
    
    public function mobileEmotePressed()
    {
        if (emote.type == None)
        {
            justEmoted = true;
            emote.animate(Smooch);
        }
    }
    
    override function setSkin(skin:Int)
    {
        super.setSkin(skin);
        // force update
        timer = sendDelay;
    }
    
    public function networkUpdate()
    {
        timer = 0;
        lastSend.set(Std.int(x), Std.int(y));
        lastSendEmote = emote.type;
        lastSkin = settings.skin;
        lastState = state;
    }
}