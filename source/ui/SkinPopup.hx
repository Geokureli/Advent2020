package ui;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;

class SkinPopup extends FlxTypedSpriteGroup<FlxSprite>
{
    static var instance(default, null):SkinPopup;
    
    inline static var DURATION = 5.0;
    inline static var PATH = "assets/images/ui/skin_unlock.png";
    
    static var numUnseen:Int;
    var tweener:FlxTweenManager = new FlxTweenManager();
    
    var bg:FlxSprite;
    var text:FlxBitmapText;
    
    public function new()
    {
        super();
        
        FlxG.signals.preStateSwitch.remove(tweener.clear);
        
        add(bg = new FlxSprite(PATH));
        add(text = new FlxBitmapText());
        
        text.x = 4;
        text.y = 4;
        
        x = FlxG.width - bg.width - 30;
        y = -bg.height;
        scrollFactor.set(0,0);
        
        if (numUnseen > 0)
            playAnim();
        
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        tweener.update(elapsed);
    }
    
    override function destroy()
    {
        // super.destroy();
    }
    
    function playAnim():Void
    {
        visible = true;
        text.text = numUnseen == 1 ? "New skin unlocked!" : numUnseen + " new skins unlocked!";
        text.x = bg.x + (bg.width - text.width) / 2;
        numUnseen = 0;
        
        tweener.cancelTweensOf(this);
        final duration = 0.5;
        function tweenOutro(?_)
        {
            var outroTween = tweener.tween(this, { y:-bg.height }, duration,
                { startDelay:DURATION, ease:FlxEase.circInOut, onComplete:(_)->visible = false });
        }
        
        if (y < 0)
        {
            final introTime = -y / bg.height * duration;
            tweener.tween(this, { y:0 }, introTime,
                { ease:FlxEase.circInOut, onComplete:tweenOutro });
        }
        else
            tweenOutro();
    }
    
    static public function show(numUnseen:Int)
    {
        SkinPopup.numUnseen = numUnseen;
        if (instance != null)
            instance.playAnim();
    }
    
    static public function getInstance()
    {
        if (instance == null)
            instance = new SkinPopup();
        return instance;
    }
}