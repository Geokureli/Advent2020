package states.rooms;

import flixel.math.FlxMath;

class OutsideState extends RoomState
{
    override function create()
    {
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        var shine = background.setAnimFrameRate("shine", 4);
        background.getByName("stars").scrollFactor.y = 0.5;
        background.getByName("moon").scrollFactor.y = 0.5;
        background.getByName("lake").scrollFactor.y = 0.75;
        background.getByName("shine").scrollFactor.y = 0.75;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateCam(elapsed);
    }
    
    inline static var TREE_FADE_TIME = 3.0;
    inline static var MAX_CAM_OFFSET = 100;
    inline static var CAM_SNAP_OFFSET = 30;
    inline static var CAM_SNAP_TIME = 3.0;
    inline static var CAM_LERP_OFFSET = MAX_CAM_OFFSET - CAM_SNAP_OFFSET;
    var camLerp = 0.0;
    var camSnap = 0.0;
    function updateCam(elapsed:Float)
    {
        final top = 210;
        final height = 50;
        final snapY = 275;
        // snap camera when above threshold
        if (player.y < snapY && camSnap < CAM_SNAP_OFFSET)
            camSnap += elapsed / CAM_SNAP_TIME * CAM_SNAP_OFFSET;
        else if (camOffset > 0)
            camSnap -= elapsed / CAM_SNAP_TIME * CAM_SNAP_OFFSET;
        // lerp camera in threshold
        camLerp = (height - (player.y - top)) / height * CAM_LERP_OFFSET;
        
        camOffset = camSnap + FlxMath.bound(camLerp, 0, CAM_LERP_OFFSET);
    }
}