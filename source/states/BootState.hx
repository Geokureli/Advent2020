package states;

import flixel.FlxG;

class BootState extends flixel.FlxState
{
    override function create()
    {
        super.create();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        FlxG.switchState(Main.initialState());
    }
}