package states.debug;

import ui.DialogBg;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;

class AudioToolSubstate extends flixel.FlxSubState
{
    inline static var BAR_MARGIN = 6;
    
    var songPath:String;
    var loopTime:Float;
    
    var bar:FlxBar;
    var loopSlider:FlxSprite;
    var dragTarget:FlxSprite;
    
    public function new(songPath:String, loopTime:Float)
    {
        this.songPath = songPath;
        super();
    }
    
    override function create()
    {
        FlxG.sound.playMusic(songPath);
        FlxG.sound.music.loopTime = loopTime;
        
        var bg = DialogBg.fromBuffer();
        add(bg);
        
        loopSlider = new FlxSprite(bg.x + BAR_MARGIN, bg.y + BAR_MARGIN);
        loopSlider.scrollFactor.set(0, 0);
        loopSlider.makeGraphic(10, 30);
        add(loopSlider);
        
        final width = FlxG.width - (BAR_MARGIN + Std.int(bg.x)) * 2;
        bar = new Bar(loopSlider.x, loopSlider.y, LEFT_TO_RIGHT, width, 0, FlxG.sound.music.length);
        bar.scrollFactor.set(0, 0);
        add(bar);
        
        super.create();
    }
    
    override function update(elapsed:Float)
    {
        final music = FlxG.sound.music;
        final mouse = FlxG.mouse;
        
        if (dragTarget != bar)
            bar.value = music.time;
        
        if(dragTarget == null)
        {
            if (mouse.justPressed)
            {
                final mouseScreen = mouse.getScreenPosition(camera);
                loopSlider.x -= loopSlider.offset.x;
                if (loopSlider.overlapsPoint(mouseScreen))
                    dragTarget = loopSlider;
                else if (bar.overlapsPoint(mouseScreen))
                    dragTarget = bar;
                loopSlider.x += loopSlider.offset.x;
                mouseScreen.put();
            }
        }
        else
        {
            final dragX = FlxMath.bound(mouse.screenX, bar.x, bar.x + bar.width);
            final barValue = (dragX - bar.x) / bar.width * music.length;
            
            if (dragTarget == loopSlider)
                loopSlider.x = dragX + loopSlider.offset.x;
            else
                bar.value = barValue;
            
            if (mouse.justReleased)
            {
                if (dragTarget == loopSlider)
                    music.loopTime = barValue;
                else
                    music.time = barValue;
                dragTarget = null;
            }
        }
    }
}

abstract Bar(FlxBar) to FlxBar
{
    inline public function new (x, y, ?direction:FlxBarFillDirection, length = 100, min = 0.0, max = 1.0, showBorder = false)
    {
        final horizontal = direction.match(LEFT_TO_RIGHT|RIGHT_TO_LEFT|HORIZONTAL_INSIDE_OUT|HORIZONTAL_OUTSIDE_IN);
        this = new FlxBar(x, y, direction, horizontal ? length : 10, horizontal ? 10 : length, null, "", min, max, showBorder);
    }
}