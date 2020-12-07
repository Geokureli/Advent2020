package props;

import Types;
import data.PlayerSettings;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class InputPlayer extends Player
{
    public var interacting = false;
    public var wasInteracting = false;
    public var touched:FlxObject = null;
    
    public var timer = 0.0;
    public var lastSend = FlxPoint.get();
    public var lastSendEmote = EmoteType.None;
    public var sendDelay = 1.0 / 6;
    
    public function new(x = 0.0, y = 0.0)
    {
        if (PlayerSettings.user == null)
            PlayerSettings.user = PlayerSettings.fromSave();
        
        super(x, y, PlayerSettings.user);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        timer += elapsed;
        
        final pad = FlxG.gamepads.lastActive;
        if (FlxG.keys.pressed.ANY || pad == null || !pad.pressed.ANY)
            updateKeys(elapsed);
        else if (pad != null)
            updateGamepad(elapsed);
        
        // prevents a bug on gamepads
        if (wasInteracting && interacting)
            interacting = false;
        else
            wasInteracting = interacting;
    }
    
    function updateKeys(elapsed:Float)
    {
        var right = FlxG.keys.anyPressed([RIGHT, D]);
        var left = FlxG.keys.anyPressed([LEFT, A]);
        var up = FlxG.keys.anyPressed([UP, W]);
        var down = FlxG.keys.anyPressed([DOWN, S]);
        var smooch = FlxG.keys.anyJustPressed([X, K]);
        interacting = FlxG.keys.anyJustPressed([SPACE, Z, J]);
        checkMouseInteracting();
        
        updateMovement(up, down, left, right, smooch, FlxG.mouse.pressed);
    }
    
    function updateGamepad(elapsed:Float)
    {
        var pressed = FlxG.gamepads.anyPressed;
        function anyPressed(idArray:Array<FlxGamepadInputID>)
        {
            while(idArray.length > 0)
            {
                if (pressed(idArray.shift()))
                    return true;
            }
            return false;
        }
        interacting = FlxG.gamepads.lastActive.anyJustPressed([A]);
        
        var down   = anyPressed([DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN ]);
        var up     = anyPressed([DPAD_UP   , LEFT_STICK_DIGITAL_UP   ]);
        var left   = anyPressed([DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT ]);
        var right  = anyPressed([DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]);
        var smooch = FlxG.gamepads.anyJustPressed(B);
        checkMouseInteracting();
        
        updateMovement(up, down, left, right, smooch, FlxG.mouse.pressed);
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
    
    public function networkUpdate()
    {
        timer = 0;
        lastSend.set(Std.int(x), Std.int(y));
        lastSendEmote = emote.type;
    }
}