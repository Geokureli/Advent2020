package ui;

import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxBitmapFont;

@:forward
abstract Font(FlxBitmapFont) to FlxBitmapFont
{
    function new (chars:String, widths:Array<Int>, path:String, lineHeight = 9, spaceWidth = 4)
    {
        @:privateAccess
        this = cast new FlxBitmapFont(FlxG.bitmap.add(path).imageFrame.frame);
        @:privateAccess
        this.lineHeight = lineHeight;
        this.spaceWidth = spaceWidth;
        var frame:FlxRect;
        var x:Int = 0;
        for (i in 0...widths.length)
        {
            frame = FlxRect.get(x, 0, widths[i] - 1, this.lineHeight);
            @:privateAccess
            this.addCharFrame(chars.charCodeAt(i), frame, FlxPoint.weak(), widths[i]);
            x += widths[i];
        }
    }
}

@:forward
abstract NokiaFont(FlxBitmapFont) to FlxBitmapFont
{
    static var instance:NokiaFont = null;
    public function new ()
    {
        if (instance == null)
        {
            final chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&*()-_+=[]',.|:?/";
            final widths = 
            [
                6,6,6,6,6,6,6,6,3,5,7,5,8,7,7,6,7,6,5,7,6,7,8,7,7,6,	//UPPERCASE
                6,6,5,6,6,4,6,6,3,4,6,3,9,6,6,6,6,5,5,4,6,6,8,6,6,6,	//LOWERCASE
                6,4,6,6,6,6,6,6,6,6,									//DIGITS
                3,6,6,7,7,6,4,4,5,6,6,5,4,4,2,3,3,3,3,6,4				//SYMBOLS
            ];
            
            @:privateAccess
            instance = cast new Font(chars, widths, "assets/images/ui/NokiaFont.png", 9, 4);
        }
        this = instance;
    }
}

@:forward
abstract NokiaFont16(FlxBitmapFont) to FlxBitmapFont
{
    static var instance:NokiaFont16 = null;
    public function new ()
    {
        if (instance == null)
        {
            final chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&*()-_+=[]',.|:?/";
            final widths = 
            [
                6,6,6,6,6,6,6,6,3,5,7,5,8,7,7,6,7,6,5,7,6,7,8,7,7,6,	//UPPERCASE
                6,6,5,6,6,4,6,6,3,4,6,3,9,6,6,6,6,5,5,4,6,6,8,6,6,6,	//LOWERCASE
                6,4,6,6,6,6,6,6,6,6,									//DIGITS
                3,6,6,7,7,6,4,4,5,6,6,5,4,4,2,3,3,3,3,6,4				//SYMBOLS
            ];
            
            @:privateAccess
            instance = cast new Font(chars, widths.map((n)->n*2), "assets/images/ui/NokiaFont16.png",  18, 8);
        }
        this = instance;
    }
}

@:forward
abstract XmasFont(FlxBitmapFont) to FlxBitmapFont
{
    static var instance:XmasFont = null;
    public function new ()
    {
        if (instance == null)
        {
            final chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789,.:'!?";
            final widths = [];
            var bmd = openfl.Assets.getBitmapData('assets/images/ui/XmasFont24.png');
            var curWidth = 0;
            var bottom = bmd.height - 1;
            for (x in 0...bmd.width)
            {
                if (bmd.getPixel(x, bottom) == 0xfbf236)
                {
                    if (curWidth > 0)
                        widths.push(curWidth + 1);
                    curWidth = 0;
                }
                else
                    curWidth++;
            }
            if (curWidth > 0)
                widths.push(curWidth + 1);
            
            // trace("Xmas widths:" + widths);
            
            @:privateAccess
            instance = cast new Font(chars, widths, "assets/images/ui/XmasFont24.png", bmd.height - 1, 4);
        }
        this = instance;
    }
}

@:forward
abstract GravFont(FlxBitmapFont) to FlxBitmapFont
{
    static var instance:GravFont = null;
    public function new ()
    {
        if (instance == null)
        {
            final chars = "1234567890";
            final widths = [];
            var bmd = openfl.Assets.getBitmapData('assets/images/ui/GravFont5.png');
            var curWidth = 0;
            var bottom = bmd.height - 1;
            for (x in 0...bmd.width)
            {
                if (bmd.getPixel(x, bottom) == 0xfbf236)
                {
                    if (curWidth > 0)
                        widths.push(curWidth + 1);
                    curWidth = 0;
                }
                else
                    curWidth++;
            }
            if (curWidth > 0)
                widths.push(curWidth + 1);
            
            // trace("Xmas widths:" + widths);
            
            @:privateAccess
            instance = cast new Font(chars, widths, "assets/images/ui/GravFont5.png", bmd.height - 1, 4);
        }
        this = instance;
    }
}