package states.rooms;

import data.Manifest;
import states.OgmoState;
import data.Calendar;
import data.Game;
import data.Content;
import props.Cabinet;
import ui.Prompt;
import vfx.ShadowSprite;

import flixel.FlxG;
import flixel.math.FlxMath;

class PathRightState extends RoomState
{
    var shade:ShadowSprite;
    var floor:OgmoDecal;
    
    override function create()
    {
        super.create();
        
        add(new vfx.Snow(20));
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        if(Game.allowShaders)
        {
            floor = background.getByName("path_ground");
            floor.setBottomHeight(floor.frameHeight);
            shade = new ShadowSprite(floor.x, floor.y);
            shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
            
            shade.shadow.setLightRadius(1, 60);
            topGround.add(shade);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (Game.allowShaders)
        {
            final ditherTop = floor.y + 32;
            final ditherBottom = floor.y + 240;
            final ditherHeight = ditherBottom - ditherTop;
            final maxRadius = 120;
            final minRadius = 60;
            final progress = FlxMath.bound((player.y - ditherTop) / ditherHeight, 0, 1);
            
            shade.shadow.setLightPos(1, player.x + player.width / 2, player.y - floor.y - 8);
            shade.shadow.setLightRadius(1, maxRadius + (progress * (minRadius - maxRadius)));
            shade.shadow.setAmbientDither(progress);
        }
    }
}