package states.rooms;

import data.Game;
import data.Manifest;

class HallwayState extends RoomState
{
    override function create()
    {
        super.create();
        
        
    }
    
    override function initClient()
    {
        if(Game.state == NoEvent)
            super.initClient();
    }
}