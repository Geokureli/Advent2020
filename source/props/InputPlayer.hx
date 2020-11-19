package props;

import rig.Limb;
import data.PlayerSettings;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class InputPlayer extends Player
{
    public var interacting = false;
    public var wasInteracting = false;
    
    public var timer = 0.0;
    public var lastSend = FlxPoint.get();
    public var sendDelay = 0.5;
    
    public function new(x = 0.0, y = 0.0)
    {
        if (PlayerSettings.user == null)
            PlayerSettings.user = new PlayerSettings(FlxColor.fromHSB(FlxG.random.float(0, 36) * 10, 1, 1));
        
        super(x, y, PlayerSettings.user);
    }
    
    override function update(elapsed:Float)
    {
        interacting = FlxG.keys.justPressed.SPACE
            || (FlxG.mouse.justPressed && overlapsPoint(FlxG.mouse.getWorldPosition()));
        
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
        
        if (FlxG.keys.justPressed.ONE)
            setFullSkin("default");
        
        if (FlxG.keys.justPressed.TWO)
            setFullSkin("solid");
    }
    
    public function networkUpdate()
    {
        timer = 0;
        lastSend.set(Std.int(x), Std.int(y));
        color = FlxColor.WHITE;
        setGraphicSize(frameWidth + 4, frameWidth + 4);
    }
    
    function setFullSkin(skinName:String)
    {
        for (limb in Limb.getAll())
            rig.setSkin(limb, skinName);
    }
}