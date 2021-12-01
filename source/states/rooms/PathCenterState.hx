package states.rooms;

import vfx.ShadowSprite;
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

class PathCenterState extends RoomState
{
    var shade:ShadowSprite;
    
    override function create()
    {
        super.create();
        
        add(new vfx.Snow(15));
    }
    
    override function initEntities()
    {
        super.initEntities();

        foreground.getByName("path_center_overlay").scrollFactor.set(1.40, 1);
        
        if(Game.allowShaders){
            var floor = background.getByName("path_center");
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
            shade.shadow.setLightPos(1, player.x + player.width / 2, player.y-8);
        }
    }
}