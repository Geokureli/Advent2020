package states.rooms;

import data.Save;
import data.Calendar;
import data.Content;
import states.MusicSelectionSubstate;

import flixel.FlxG;
import flixel.FlxSprite;

class StudioState extends RoomState
{
    override function create()
    {
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        for (id=>data in Content.instruments)
        {
            var instrument = foreground.getByName(id);
            if (instrument != null)
            {
                if (data.day > Calendar.day)
                    instrument.kill();
                else
                    initInstrument(instrument, data);
            }
        }
    }
    
    function initInstrument(sprite:FlxSprite, data:InstrumentData)
    {
        addHoverTextTo(sprite, data.name, ()->pickupInstrument(sprite, data));
    }
    
    function pickupInstrument(sprite:FlxSprite, data:InstrumentData)
    {
        Save.setInstrument(data.id);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        #if debug
        if (FlxG.keys.justPressed.H)
        {
            openSubState(new MusicSelectionSubstate());
        }
        #end
    }
}