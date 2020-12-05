package states.rooms;

class OutsideState extends RoomState
{
    override function create()
    {
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        background.setAnimFrameRate("shine", 4);
    }
}