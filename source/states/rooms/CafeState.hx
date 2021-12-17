package states.rooms;

import flixel.group.FlxGroup;
import props.SpeechBubble;
import states.OgmoState;

typedef NamedEntity = { name:String };

class CafeState extends RoomState
{
    var seatsGroup = new FlxTypedGroup<FlxObject>();
    var spots = new Map<FlxObject, FlxObject>();
    override function create()
    {
        var seatsByName = new Map<String, FlxObject>();
        var placematsByName = new Map<String, FlxObject>();
        entityTypes["Seat"] = cast function (data:OgmoEntityData<NamedEntity>)
        {
            var seat = OgmoEntityData.createFlxObject(data);
            seatsGroup.add(seat);
            seatsByName[data.values.name] = seat;
            return seat;
        }
        entityTypes["Placemat"] = cast function (data:OgmoEntityData<NamedEntity>)
        {
            var placemat = OgmoEntityData.createFlxObject(data);
            placematsByName[data.values.name] = placemat;
            return placemat;
        }
        
        super.create();
        
        for (name in seatsByName.keys())
        {
            foreground.remove(seatsByName[name]);
            if (placematsByName.exists(name) == false)
                throw 'Seat:$name found with no placemat';
            spots[seatsByName[name]] = placematsByName[name];
        }
        
        for (name in placematsByName.keys())
        {
            foreground.remove(placematsByName[name]);
            if (seatsByName.exists(name) == false)
                throw 'Placemat:$name found with no seat';
        }
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        #if LOAD_DISK_CAROUSEL
        var juke = foreground.assertByName("cafe-juke");
        addHoverTextTo(juke, "Music", ()->openSubState(new MusicSelectionSubstate()));
        #end
    }

    // override function update(elapsed:Float) { super.update(elapsed); }
}
