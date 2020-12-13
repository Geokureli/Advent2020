package states;

import flixel.util.FlxTimer;
import flixel.text.FlxBitmapText;
import flixel.FlxSubState;

class LuciaReadySetGo extends FlxSubState
{
    override function create()
    {
        var field = new FlxBitmapText(new ui.Font.XmasFont());
        field.text = "Collect all the buns!";
        field.screenCenter(XY);
        add(field);
        
        var totalDelay = 0.0;
        inline function delayText(msg:String, delay:Float)
        {
            totalDelay += delay;
            new FlxTimer().start(totalDelay, 
                function (_)
                {
                    field.text = msg;
                    field.screenCenter(XY);
                }
            );
        }
        delayText("Ready", 1.0);
        delayText("Set"  , 1.0);
        delayText("Go!"  , 1.0);
        
        new FlxTimer().start(totalDelay, (_)->close());
    }
    
}