package ui;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import data.Content;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;

class MusicPopup extends FlxTypedSpriteGroup<FlxSprite>
{
    static var instance(default, null):MusicPopup;
    
    inline static var DURATION = 5.0;
    inline static var MAIN_PATH = "assets/images/ui/music/popup.png";
    inline static var BAR_PATH = "assets/images/ui/music/popup_bar.png";
    
    static var info:SongCreation;
    var tweener:FlxTweenManager = new FlxTweenManager();
    
    var main:FlxSprite;
    var bar:FlxSprite;
    var text:FlxBitmapText;
    
    public function new()
    {
        super();
        
        FlxG.signals.preStateSwitch.remove(tweener.clear);
        
        add(bar = new FlxSprite(BAR_PATH));
        add(main = new FlxSprite());
        add(text = new FlxBitmapText());
        
        main.loadGraphic(MAIN_PATH, true, 56, 72);
        main.animation.add("idle", [for (i in 0...main.animation.frames) i], 10);
        main.animation.play("idle");
        
        bar.x = main.width;
        bar.y = main.y + main.height - bar.height;
        
        text.x = 4;
        text.y = main.y + main.height - text.height;
        
        // visible = false;
        x = 0;
        y = FlxG.height;
        scrollFactor.set(0,0);
        
        if (info != null)
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
        text.text = info.name + " by " + Content.listAuthorsProper(info.authors);
        info = null;
        
        tweener.cancelTweensOf(this);
        final duration = 0.5;
        function tweenOutro(?_)
        {
            var outroTween = tweener.tween(this, { y:FlxG.height }, duration,
                { startDelay:DURATION, ease:FlxEase.circInOut, onComplete:(_)->visible = false });
        }
        
        // if (y > FlxG.height - bar.height)
            bar.x = text.x + text.width - bar.width + 6;
        
        if (y > FlxG.height - main.height)
        {
            final introTime = (y - (FlxG.height - main.height)) / main.height * duration;
            tweener.tween(this, { y:FlxG.height - main.height }, introTime,
                { ease:FlxEase.circInOut, onComplete:tweenOutro });
        }
        else
            tweenOutro();
    }
    
    static public function showInfo(info:SongCreation)
    {
        MusicPopup.info = info;
        if (instance != null)
            instance.playAnim();
    }
    
    static public function getInstance()
    {
        if (instance == null)
            instance = new MusicPopup();
        return instance;
    }
}