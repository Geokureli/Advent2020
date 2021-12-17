package states.rooms;

import data.Net;
import props.GhostPlayer;
import props.Placemat;
import props.SpeechBubble;
import states.OgmoState;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;

class CafeState extends RoomState
{
    var seats = new FlxTypedGroup<FlxObject>();
    var spots = new Map<FlxObject, Placemat>();
    override function create()
    {
        var seatsByName = new Map<String, FlxObject>();
        var placematsByName = new Map<String, Placemat>();
        entityTypes["Seat"] = cast function (data:OgmoEntityData<NamedEntity>)
        {
            var seat = OgmoEntityData.createFlxObject(data);
            seats.add(seat);
            seatsByName[data.values.name] = seat;
            return seat;
        }
        entityTypes["Placemat"] = cast function (data:OgmoEntityData<NamedEntity>)
        {
            var placemat = Placemat.fromEntity(data);
            placematsByName[data.values.name] = placemat;
            return placemat;
        }
        
        super.create();
        
        initPlacemats(seatsByName, placematsByName);
    }
    
    /**
     * This a doozy, map seats to placemats by ids, create a group for each table and
     * add overlapping placemats to it so all the layering works.
     * @param seatsByName 
     * @param placematsByName 
     */
    function initPlacemats(seatsByName:Map<String, FlxObject>, placematsByName:Map<String, Placemat>)
    {
        // verify seats match placemats
        for (name in seatsByName.keys())
        {
            if (placematsByName.exists(name) == false)
                throw 'Seat:$name found with no placemat';
            spots[seatsByName[name]] = placematsByName[name];
        }
        
        for (name in placematsByName.keys())
        {
            if (seatsByName.exists(name) == false)
                throw 'Placemat:$name found with no seat';
        }
        
        var tableHitboxes = new FlxTypedGroup<FlxObject>();
        var decalGroups = new Map<FlxObject, DecalGroup>();
        for (name in ["cafe-table", "cafe-tablemedium", "cafe-tablelong"])
        {
            var group = foreground.getAllWithName(name);
            if (group.length == 0)
                throw 'Missing foreground decals named:$name';
            
            while(group.length > 0)
            {
                // replace table decal with new group
                var table = group.remove(group.members[0], true);
                var hitbox = new FlxObject(table.x - table.offset.x, table.y - table.offset.y, table.frameWidth, table.frameHeight);
                hitbox.immovable = true;
                decalGroups[hitbox] = new DecalGroup(table);
                foreground.remove(table, true);
                foreground.add(cast decalGroups[hitbox]);
                tableHitboxes.add(hitbox);
                
                //testing
                // table.x -= table.offset.x;
                // table.y -= table.offset.y;
                // table.offset.x = 0;
                // table.offset.y = 0;
                // table.width = table.frameWidth;
                // table.height = table.frameHeight;
                // trace ( '${table.x} == ${hitbox.x}'
                //     + ', ${table.y} == ${hitbox.y}'
                //     + ', ${table.y} == ${hitbox.y}'
                //     + ', ${table.width} == ${hitbox.width}'
                //     + ', ${table.height} == ${hitbox.height}'
                //     );
                //end
            }
        }
        
        // for debugging
        function getPlacematName(placemat)
        {
            for (name in placematsByName.keys())
            {
                if (placemat == placematsByName[name])
                    return name;
            }
            throw "Placemat name not found";
        }
        
        var placemats = new FlxTypedGroup<Placemat>();
        for (placemat in spots)
            placemats.add(placemat);
        
        var propsLayer:OgmoEntityLayer = cast byName["Props"];
        var addedPlacemats = new Array<Placemat>();
        FlxG.overlap(placemats, tableHitboxes,
            (placemat:Placemat, table:FlxObject)->
            {
                var group = decalGroups[table];
                if (placemat.overlaps(table) == false)
                    return;
                
                if (addedPlacemats.contains(placemat) && group.contains(placemat) == false)
                    throw 'Placemat already added';
                
                propsLayer.remove(placemat, true);
                group.add(placemat);
                addedPlacemats.push(placemat);
            }
        );
        
        #if debug
        add(tableHitboxes);
        
        for (name=>placemat in placematsByName)
        {
            if (addedPlacemats.contains(placemat) == false)
                trace ('Not added to table - placemat:$name');
        }
        #else
        tableHitboxes.clear();
        #end
        placemats.clear();
        seatsByName.clear();
        placematsByName.clear();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        #if LOAD_DISK_CAROUSEL
        var juke = foreground.assertByName("cafe-juke");
        addHoverTextTo(juke, "Music", ()->openSubState(new MusicSelectionSubstate()));
        #end
    }
    
    override function onAvatarAdd(data, key:String)
    {
        super.onAvatarAdd(data, key);
        
        if (key == Net.room.sessionId)
            return;
        
        var ghost = ghostsById[key];
        
        if (ghost.netState == Joining)
            ghost.onJoinFinish.addOnce(seatNewGhost.bind(ghost));
        else
            seatNewGhost(ghost);
    }
    
    function seatNewGhost(ghost:GhostPlayer)
    {
        var seekingSeat = true;
        FlxG.overlap(ghost, seats, function seatGhost(_, seat)
            {
                if (seekingSeat && spots[seat].visible == false)
                {
                    seekingSeat = false;
                    spots[seat].randomOrderUp();
                }
            }
        );
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        FlxG.overlap(player, seats,
            (_, seat)->
            {
                //Todo: add order for player
                // if (spots[seat].visible == false)
                //     spots[seat].randomOrderUp();
            }
        );
    }
}

abstract DecalGroup(FlxSpriteGroup) to FlxSpriteGroup
{
    public function new (bottom:OgmoDecal)
    {
        this = new FlxSpriteGroup(bottom.x, bottom.y);
        bottom.x = 0;
        bottom.y = 0;
        this.add(bottom);
        #if debug
        this.ignoreDrawDebug = true;
        #end
    }
    
    public function add(placemat:Placemat)
    {
        placemat.x -= this.x;
        placemat.y -= this.y;
        this.add(placemat);
    }
    
    inline public function contains(sprite:FlxSprite)
    {
        return this.members.contains(sprite);
    }
}