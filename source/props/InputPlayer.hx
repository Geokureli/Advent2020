package props;

import rig.Limb;
import flixel.FlxG;

class InputPlayer extends Player
{
    public var interacting = false;
    public var wasInteracting = false;
    
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
    
    function setFullSkin(skinName:String)
    {
        for (limb in Limb.getAll())
            rig.setSkin(limb, skinName);
    }
}