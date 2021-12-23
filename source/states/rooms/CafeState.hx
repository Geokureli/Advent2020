package states.rooms;

import data.Net;
import props.CafeTable;
import props.GhostPlayer;
import props.Player;
import props.Placemat;
import props.SpeechBubble;
import props.SpeechBubbleQueue;
import props.Waiter;
import states.OgmoState;
import utils.DebugLine;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;

class CafeState extends RoomState
{
    var seats = new FlxTypedGroup<FlxObject>();
    var spots = new Map<FlxObject, Placemat>();
    var tableSeats = new Map<FlxObject, CafeTable>();
    var waiters = new Array<Waiter>();
    var waiterNodes:OgmoPath = null;
    var tables = new Array<CafeTable>();
    var patrons = new Map<Player, Placemat>();
    
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
        entityTypes["Waiter"] = cast function (data)
        {
            var waiter = Waiter.fromEntity(data);
            waiters.push(waiter);
            waiter.onServe.add(onWaiterServe);
            waiter.onBus.add(onWaiterBus);
            waiter.onBus.add(onWaiterRefill);
            if (waiter.ogmoPath != null && waiterNodes == null)
                waiterNodes = waiter.ogmoPath;
            return waiter;
        }
        
        super.create();
        
        
        #if debug
        if (waiterNodes != null)
        {
            var path = waiterNodes.drawNodes(2, 0xFF000000);
            topGround.add(path);
            path.camera = debugCamera;
        }
        #end
        
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
            var seat = seatsByName[name];
            if (placematsByName.exists(name) == false)
                throw 'Seat:$name found with no placemat';
            
            var placemat = placematsByName[name];
            placemat.seat = seat;
            spots[seat] = placemat;
        }
        
        for (name in placematsByName.keys())
        {
            if (seatsByName.exists(name) == false)
                throw 'Placemat:$name found with no seat';
        }
        
        var tableHitboxes = new FlxTypedGroup<FlxObject>();
        var tableGroups = new Map<FlxObject, CafeTable>();
        
        for (name in ["cafe-table", "cafe-tablemedium", "cafe-tablelong"])
        {
            var group = foreground.getAllWithName(name);
            if (group.length == 0)
                throw 'Missing foreground decals named:$name';
            
            while(group.length > 0)
            {
                // replace table decal with new group
                var tableDecal = group.remove(group.members[0], true);
                var hitbox = new FlxObject(tableDecal.x - tableDecal.offset.x, tableDecal.y - tableDecal.offset.y, tableDecal.frameWidth, tableDecal.frameHeight);
                hitbox.immovable = true;
                var tableGroup = CafeTable.fromDecal(tableDecal);
                tables.push(tableGroup);
                tableGroups[hitbox] = tableGroup;
                foreground.remove(tableDecal, true);
                foreground.add(cast tableGroup);
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
        
        var placemats = new FlxTypedGroup<Placemat>();
        for (placemat in spots)
            placemats.add(placemat);
        
        var propsLayer:OgmoEntityLayer = cast byName["Props"];
        var addedPlacemats = new Array<Placemat>();
        
        inline function createBarTable(name1:String, name2:String)
        {
            var mat1 = placematsByName[name1];
            var mat2 = placematsByName[name2];
            addedPlacemats.push(placemats.remove(mat1));
            addedPlacemats.push(placemats.remove(mat2));
            var table = CafeTable.fromPlacemats([mat1, mat2]);
            tableSeats[seatsByName[name1]] = table;
            tableSeats[seatsByName[name2]] = table;
            tables.push(table);
            foreground.add(table);
            return table;
        }
        
        createBarTable("bar1", "bar2");
        createBarTable("bar3", "bar4");
        createBarTable("bar5", "bar6");
        
        FlxG.overlap(placemats, tableHitboxes,
            (placemat:Placemat, tableHitbox:FlxObject)->
            {
                var table = tableGroups[tableHitbox];
                // double check, not sure why this is needed
                if (placemat.overlaps(tableHitbox) == false)
                    return;
                
                if (addedPlacemats.contains(placemat) && table.contains(placemat) == false)
                    throw 'Placemat already added';
                
                propsLayer.remove(placemat, true);
                table.addPlacemat(placemat);
                tableSeats[placemat.seat] = table;
                
                addedPlacemats.push(placemat);
            }
        );
        
        if (waiterNodes == null)
            throw "Could not find waiter nodes";
        
        for (table in tables)
            table.getClosestNode(waiterNodes);
        
        for (waiter in waiters)
        {
            waiter.ogmoPath = waiterNodes;
        }
        
        #if debug
        add(tableHitboxes);
        
        for (name=>placemat in placematsByName)
        {
            if (addedPlacemats.contains(placemat) == false)
                throw 'Not added to table - placemat:$name';
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
        
        for (waiter in waiters)
            addHoverTextTo(waiter, "TALK", talkToWaiter.bind(waiter));
        
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
            ghost.onJoinFinish.addOnce(seatExistingPlayer.bind(ghost));
        else
            seatExistingPlayer(ghost);
    }
    
    function seatExistingPlayer(patron:Player)
    {
        FlxG.overlap(patron, seats, function seatGhost(_, seat)
            {
                if (canSeatPatron(seat, patron))
                {
                    seatPatron(seat, patron);
                    spots[seat].orderUp(patron.state.order);
                }
            }
        );
    }
    
    function canSeatPatron(seat:FlxObject, patron:Player)
    {
        return spots[seat].patron == null
            && patrons.exists(patron) == false;
    }
    
    function seatPatron(seat:FlxObject, patron:Player )
    {
        var placemat = spots[seat];
        placemat.patron = patron;
        patrons[patron] = placemat;
    }
    
    function talkToWaiter(waiter:Waiter)
    {
        var seated = patrons.exists(player);
        player.enabled = false;
        waiter.enabled = false;
        var speech = new SpeechBubbleQueue(waiter);
        topGround.add(speech);
        var msgs =
            [ "Welcome to the\nNew Grounds Cafe!"
            , "What can I do for ya?"
            ];
        
        speech.showMsgQueue(msgs,
            function onComplete()
            {
                var menu = new CafeOrderSubstate();
                menu.closeCallback = function()
                {
                    player.settings.applyTo(player);
                    player.enabled = true;
                    waiter.enabled = true;
                    if (seated == false)
                    {
                        speech.enableAutoMode();
                        speech.showMsgQueue
                            ( ["Sit anywhere and I'll\nbring it right to you."]
                            , topGround.remove.bind(speech)
                            );
                    }
                }
                openSubState(menu);
            }
        );
    }
    
    function onWaiterServe(placemat:Placemat)
    {
        if (placemat.patron == player)
        {
            var text = switch(placemat.getOrder())
            {
                case COFFEE: "SIP";
                case DINNER: "EAT";
                case unexpected: throw 'Unexpected order:$unexpected';
            }
            addHoverTextTo(placemat, text, ()->
                {
                    if (placemat.getBitesLeft() == 1)
                        removeHoverFrom(placemat);
                    placemat.bite();
                }
            );
        }
        else if (placemat.patron != null)
            sayThx(placemat.patron);
    }
    
    function onWaiterRefill(placemat:Placemat)
    {
        if (placemat.patron != null && placemat.patron != player)
            sayThx(placemat.patron);
    }
    
    static var msgs = 
        [ "thx!"
        , "Thanks!"
        , ":)"
        , "yum!"
        , "Such great\nservice!"
        ];
    function sayThx(patron:Player)
    {
        // if (FlxG.random.bool())
        {
            var bubble = new SpeechBubbleQueue(patron.x, patron.y - 24);
            bubble.enableAutoMode();
            add(bubble);
            bubble.showMsgQueue([FlxG.random.getObject(msgs)], remove.bind(bubble));
        }
    }
    
    function onWaiterBus(placemat:Placemat)
    {
        removeHoverFrom(placemat);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        function seatPatronIfCan(patron:Player, seat:FlxObject)
        {
            if (canSeatPatron(seat, patron))
                seatPatron(seat, patron);
        }
        
        FlxG.overlap(player, seats, seatPatronIfCan);
        FlxG.overlap(avatars, seats, seatPatronIfCan);
        
        var serviceTables = new Array<CafeTable>();
        for (table in tables)
        {
            table.checkServiceNeeds();
            if (table.needsService)
                serviceTables.push(table);
        }
        
        for (waiter in waiters)
            waiter.goToPriorityTable(serviceTables);
        
        for (patron=>placemat in patrons)
        {
            if (placemat.patron != patron)
                patrons.remove(patron);
        }
        
        for (placemat in spots)
        {
            if (placemat.patron != null && placemat.visible == false && placemat.getSeatedPatron() == null)
                placemat.patron = null;
        }
    }
}