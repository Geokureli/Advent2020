package states.rooms;

import flixel.group.FlxSpriteGroup;
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

import flixel.FlxSprite;

class PathLeftState extends RoomState
{
    var shade:ShadowSprite;
    
    override function create()
    {
        super.create();
        
        add(new vfx.Snow(20));
    }
    
    override function initEntities()
    {
        super.initEntities();

        foreground.getByName("snowman").setBottomHeight(28);
        
        if(Game.allowShaders)
        {
            var floor = background.getByName("path_ground");
            floor.setBottomHeight(floor.frameHeight);
            shade = new ShadowSprite(floor.x, floor.y);
            shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
            
            shade.shadow.setLightRadius(1, 60);
            topGround.add(shade);
        }
        
        var easter_egg_snowman_brandy = FlxG.random.bool(1); // 1% chance to return 'true'
        
        if(easter_egg_snowman_brandy)
        {
            var snowman = foreground.getByName("snowman");
            snowman.loadGraphic("assets/images/props/path_left/snowman_brandy.png");
            snowman.x -= 32;
            snowman.y -= 40;
            snowman.scale.set(0.5, 0.5);
            snowman.setBottomHeight(100);
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