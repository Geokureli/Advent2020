package props;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class Notif extends flixel.FlxSprite
{
    var tween:FlxTween;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y, "assets/images/props/shared/notif.png");
        offset.y = height;
    }
    
    public function animate()
    {
        if (tween != null)
            tween.cancel();
        
        offset.y = height;
        tween = FlxTween.tween(this, { "offset.y": height - 8 }, 0.75, { type:PINGPONG, ease:FlxEase.sineInOut, loopDelay: 0.25 });
    }
    
    override function destroy()
    {
        super.destroy();
        
        if (tween != null)
        {
            tween.cancel();
            tween = null;
        }
    }
}