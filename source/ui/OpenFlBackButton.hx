package ui;

import flixel.FlxG;

import openfl.geom.Rectangle;
import openfl.utils.Assets;
import openfl.display.Bitmap;

class OpenFlBackButton extends openfl.display.Sprite
{
    inline static var WIDTH = 27;
    inline static var HEIGHT = 30;
    
    override function get_width():Float return scrollRect.width;
    override function get_height():Float return scrollRect.height;
    
    var frame:Int = 0;
    var callback:()->Void;
    
    public function new(callback:()->Void)
    {
        this.callback = callback;
        super();
        addChild(new Bitmap(Assets.getBitmapData("assets/images/ui/buttons/back.png")));
        scaleX = scaleY = 2;
        scrollRect = new Rectangle(0, 0, WIDTH, HEIGHT);
        useHandCursor = true;
        buttonMode = true;
    }
    
    public function update(elapsed:Float):Void
    {
        var mouseX = this.mouseX - WIDTH * frame;
        var isMouseOver = mouseX > 0 && mouseX < WIDTH && mouseY > 0 && mouseY < HEIGHT;
        if (FlxG.mouse.justPressed && isMouseOver)
            setFrame(1);
        else if (!FlxG.mouse.pressed && frame == 1)
        {
            setFrame(0);
            if (isMouseOver)
                callback();
        }
    }
    
    function setFrame(frame:Int)
    {
        var rect = scrollRect;
        rect.x = rect.width * frame;
        scrollRect = rect;
        this.frame = frame;
    }
    
    public function destroy()
    {
        callback = null;
        removeChildren();
    }
}