package states.rooms;

import ui.Prompt;
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
        
        var authorsFound = new Array<String>();
        for (data in Content.songs)
        {
            for (author in data.authors)
            {
                authorsFound.push(author);
                var avatar = background.getByName(author);
                if (avatar != null)// && data.day > Calendar.day)
                    avatar.kill();
            }
        }
        
        for (user in Content.credits.keys())
        {
            if (!authorsFound.contains(user))
            {
                var avatar = background.getByName(user);
                if (avatar != null)// && data.day > Calendar.day)
                    avatar.kill();
            }
        }
        
        var juke = foreground.getByName("juke");
        addHoverTextTo(juke, "Music", selectJuke);
    }
    
    public function selectJuke()
    {
        openSubState(new MusicSelectionSubstate());
    }
    
    function initInstrument(sprite:FlxSprite, data:InstrumentData)
    {
        addHoverTextTo(sprite, data.name, ()->pickupInstrument(sprite, data));
    }
    
    function pickupInstrument(sprite:FlxSprite, data:InstrumentData)
    {
        Save.setInstrument(data.id);
        if (!Save.seenInstrument(data.id))
        {
            Save.instrumentSeen(data.id);
            Prompt.showOKInterrupt('You got the ${data.name}, play by pressing the ERTYUIOP\nkeys or by clicking it icon in the top right');
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
    }
}