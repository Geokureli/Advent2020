package states.rooms;

import data.NGio;
import props.Notif;
import props.Teleport;
import states.rooms.RoomState;

import flixel.util.FlxTimer;

class TheaterLobbyState extends RoomState
{
    var movieTeleport:Teleport;
    override function create()
    {
        entityTypes["Teleport"] = cast function (data)
        {
            var teleport = addTeleport(data);
            if (teleport.id == RoomName.TheaterScreen)
                movieTeleport = teleport;
            return teleport;
        }
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        if (movieTeleport.enabled == false && NGio.moviePremier == null)
            checkForPremier();
        else if (movieTeleport.enabled == false && NGio.moviePremier != null)
            openForPremier();
    }
    
    function checkForPremier()
    {
        new FlxTimer().start(30,
            (timer)->
            {
                NGio.checkForMoviePremier((path)->
                    {
                        if (path != null)
                        {
                            timer.cancel();
                            openForPremier(true);
                        }
                    }
                );
            }
        , 0 // loop forever
        );
    }
    
    function openForPremier(showNotif = false)
    {
        movieTeleport.enabled = true;
        if (showNotif)
        {
            var notif = new Notif();
            notif.x = movieTeleport.x + (movieTeleport.width - notif.width) / 2;
            notif.y = movieTeleport.y - 8;
            topGround.add(notif);
        }
        var door = background.getByName("theater_lobby_door");
        if (door != null)
            door.kill();
    }
}