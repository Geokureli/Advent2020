package states.rooms;

import flixel.text.FlxBitmapText;
import props.InfoBox;
import data.Content;
import data.Net;
import data.Skins;
import data.PlayerSettings;
import flixel.group.FlxGroup;
import props.GhostPlayer;
import flixel.FlxObject;
import states.OgmoState;

import flixel.math.FlxPoint;
import flixel.FlxG;

import schema.Avatar;

class MovieState extends RoomState
{
    var seats = new Array<FlxPoint>();
    #if debug
    var debugGhosts = new FlxTypedGroup<GhostPlayer>();
    var debugGhostSettings = new PlayerSettings();
    #end
    var alreadySeatedTimer = 0.5;
    var selectedMovie = "grinch";
    var isPremier = false;
    
    override function create()
    {
        var unpopularSeats = new Array<FlxPoint>();
        var overflowSeats = new Array<FlxPoint>();
        entityTypes["Seat"] = cast function(data:OgmoEntityData<{popular:Bool}>)
        {
            var obj = new FlxObject(data.x + 2, data.y, data.width, data.height);
            final numSeats = Math.ceil(obj.width / 16);
            for (i in 0...numSeats)
            {
                var seat = new FlxPoint(obj.x + i * 16, obj.y);
                if (data.values.popular)
                    seats.push(seat);
                else
                    unpopularSeats.push(seat);
                
                //overflow seats
                if (numSeats > 1)
                    overflowSeats.push(new FlxPoint(obj.x + i * 16 + 8, obj.y));
            }
            return obj;
        }
        
        super.create();
        
        shuffle(seats);
        shuffle(unpopularSeats);
        shuffle(overflowSeats);
        while(unpopularSeats.length > 0)
            seats.push(unpopularSeats.shift());
        while(overflowSeats.length > 0)
            seats.push(overflowSeats.shift());
    }
    
    function shuffle<T>(array:Array<T>)
    {
        for (i in 0...array.length)
        {
            var j = FlxG.random.int(0, array.length - 1);
            var temp = array[j];
            array[j] = array[i];
            array[i] = temp;
        }
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        var screen = background.getByName("screen");
        if (screen == null)
            throw "missing screen";
        addHoverTextTo(screen, "watch", watchMovie);
        
        for (id in Content.movies.keys())
        {
            final data = Content.movies[id];
            final poster = background.getByName(id);
            if (poster != null)
            {
                var text = data.name;
                if (isPremier && id == selectedMovie)
                    text = "Now Playing!";
                
                addHoverTextTo(poster, text, ()->onPosterSelect(data));
            }
        }
    }
    
    function onPosterSelect(movie:MovieCreation)
    {
        if (isPremier)
            return;
        
        selectedMovie = movie.id;
    }
    
    function watchMovie()
    {
        final movie = Content.movies[selectedMovie];
        openSubState(new VideoSubstate(movie.path));
        if (isPremier)
        {
            isPremier = false;
            final poster = background.getByName(selectedMovie);
            cast(infoBoxes[poster].sprite, FlxBitmapText).text = movie.name;
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (Net.room != null)
            alreadySeatedTimer -= elapsed;
        
        #if debug 
        if (FlxG.keys.pressed.H)
            addDebugGhost();
        
        if (FlxG.keys.pressed.G)
            removeDebugGhost();
        #end
    }
    
    #if debug 
    function addDebugGhost()
    {
        final name = "debug " + debugGhosts.length;
        var ghost = new GhostPlayer(name, name, 0, 0, debugGhostSettings);
        ghost.setSkin(FlxG.random.int(0, Skins.getLength() - 2));
        ghosts.add(ghost);
        ghostsById[name] = ghost;
        foreground.add(ghost);
        debugGhosts.add(ghost);
        addToSeats(ghost);
    }
    
    function removeDebugGhost()
    {
        var ghost = debugGhosts.members[0];
        debugGhosts.remove(ghost);
        ghosts.remove(ghost);
        ghostsById.remove(ghost.key);
    }
    #end
    
    override function onAvatarAdd(data:Avatar, key:String)
    {
        super.onAvatarAdd(data, key);
        
        if (ghostsById.exists(key))
        {
            var ghost = ghostsById[key];
            addToSeats(ghost);
        }
        data.onChange = (_)->{};
    }
    
    function addToSeats(ghost:GhostPlayer)
    {
        if (alreadySeatedTimer <= 0)
        {
            ghost.x = 248;
            ghost.y = 384;
            @:privateAccess
            ghost.skinOffset.y -= 8;
            var overflow = (Math.floor(ghosts.length / seats.length) % 2) * 4;
            final seat = seats.shift();
            seat.x += overflow;
            ghost.setTargetPos(seat);
            seat.x -= overflow;
            seats.push(seat);
        }
        else
        {
            var overflow = (Math.floor(ghosts.length / seats.length) % 2) * 4;
            final seat = seats.shift();
            ghost.x = seat.x + overflow;
            ghost.y = seat.y + 8;
            ghost.cancelTargetPos();
            seats.push(seat);
        }
    }
    
    override function destroy()
    {
        super.destroy();
        while(seats.length > 0)
            seats.pop().put();
    }
}