package props;

import rig.Limb;
import data.PlayerSettings;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class InputPlayer extends Player
{
    public var interacting = false;
    public var wasInteracting = false;
    public var touched:FlxObject = null;
    
    public var timer = 0.0;
    public var lastSend = FlxPoint.get();
    public var sendDelay = 0.5;
    
    public function new(x = 0.0, y = 0.0)
    {
        if (PlayerSettings.user == null)
            PlayerSettings.user = new PlayerSettings(0);
        
        super(x, y, PlayerSettings.user);
    }
    
    override function update(elapsed:Float)
    {
        interacting = FlxG.keys.justPressed.SPACE;
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
        // prevents a bug on gamepads
        if (wasInteracting && interacting)
            interacting = false;
        else
            wasInteracting = interacting;
        
        super.update(elapsed);
        
        timer += elapsed;
        
        var right = FlxG.keys.anyPressed([RIGHT, D]);
        var left = FlxG.keys.anyPressed([LEFT, A]);
        var up = FlxG.keys.anyPressed([UP, W]);
        var down = FlxG.keys.anyPressed([DOWN, S]);
        
        updateMovement(up, down, left, right, FlxG.mouse.pressed);
        #if USE_RIG updateRigDebug(); #end
    }
    
    #if USE_RIG
    function updateRigDebug(elapsed:Float)
    {
        if (FlxG.keys.justPressed.ONE)
            setFullSkin("default");
        
        if (FlxG.keys.justPressed.TWO)
            setFullSkin("solid");
        
        if (FlxG.keys.justPressed.THREE)
            setFullSkin("pico");
        
        if (FlxG.keys.justPressed.FOUR)
            setFullSkin("vector");
        
        if (FlxG.keys.justPressed.ZERO)
            rig.color = rig.color == 0xffffff ? settings.color : 0xffffff;
    }
    
    function setFullSkin(skinName:String)
    {
        rig.color = skinName == "default" ? settings.color : 0xffffff;//debug
        
        for (limb in Limb.getAll())
            rig.setSkin(limb, skinName);
    }
    #end
    
    public function networkUpdate()
    {
        timer = 0;
        lastSend.set(Std.int(x), Std.int(y));
        color = FlxColor.WHITE;
        // setGraphicSize(frameWidth + 4, frameWidth + 4);
    }
}