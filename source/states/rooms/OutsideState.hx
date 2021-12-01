package states.rooms;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.math.FlxMath;

import data.Game;
import props.Note;
import states.OgmoState;
import vfx.ShadowSprite;

class OutsideState extends RoomState
{
    var shade:ShadowSprite;
    var floor:OgmoDecal;
    
    var note:Note;
    
    override function create()
    {
        entityTypes["Note"] = cast function(data)
        {
            note = Note.fromEntity(data);
            return note;
        }
        
        super.create();
        
        add(new vfx.Snow());
        FlxG.camera.fade(FlxColor.BLACK, 1, true);
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        var note_door = foreground.getByName("note_door");
        // foreground.remove(note_door);
        // topGround.add(note_door);
        addHoverTextTo(note_door, "READ", ()->{ note.visible = !note.visible; });
        
        foreground.remove(note);
        topGround.add(note);
        note.visible = false;
        
        var shine = background.setAnimFrameRate("shine", 4);
        background.getByName("stars").scrollFactor.y = 0.15;
        background.getByName("moon").scrollFactor.y = 0.35;
        background.getByName("mountains").scrollFactor.y = 0.5;
        background.getByName("lake").scrollFactor.y = 0.75;
        background.getByName("ice_1").scrollFactor.y = 0.75;
        background.getByName("shine").scrollFactor.y = 0.75;
        foreground.getByName("house_3").setBottomHeight(72);
        
        
        if(Game.allowShaders)
        {
            floor = background.getByName("snow_3");
            floor.setBottomHeight(floor.frameHeight);
            shade = new ShadowSprite(floor.x, floor.y);
            shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
            
            shade.shadow.setAmbientDither(0.0);
            shade.shadow.setLightRadius(1, 60);
            topGround.add(shade);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateCam(elapsed);
        
        if (Game.allowShaders)
        {
            final ditherTop = floor.y + 200;
            final ditherBottom = floor.y + floor.height - 64;
            final ditherHeight = ditherBottom - ditherTop;
            final maxRadius = 120;
            final minRadius = 60;
            final progress = FlxMath.bound((player.y - ditherTop) / ditherHeight, 0, 1);
            
            shade.shadow.setLightPos(1, player.x + player.width / 2, player.y - floor.y - 8);
            shade.shadow.setLightRadius(1, maxRadius + (progress * (minRadius - maxRadius)));
            shade.shadow.setAmbientDither(progress);
        }
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