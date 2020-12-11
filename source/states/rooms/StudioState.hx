package states.rooms;

import data.Save;
import data.Calendar;
import data.Content;

class StudioState extends RoomState
{
    override function create()
    {
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        for (id=>data in Content.instruments.keys())
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
        addHoverTextTo(sprite, data.name, ()->pickupInstrument(data));
    }
    
    function pickupInstrument(sprite:FlxSprite, data:InstrumentData)
    {
        Save.setInstrument = data.index;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}