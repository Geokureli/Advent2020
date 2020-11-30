package states.rooms;

class HallwayState extends RoomState
{
    override function initEntities()
    {
        super.initEntities();
        
        for (door in background.getAllWithName("door"))
        {
            door.animation.add("open", [0]);
            door.animation.add("closed", [1]);
            door.animation.play("closed");
        }
    }
}