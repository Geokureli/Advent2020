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

import flixel.FlxSprite;

class PathLeftState extends RoomState
{
    var shade:ShadowSprite;
    var snowman_brandy:Bool;
    
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
            var floor = background.getByName("path_ground");
            floor.setBottomHeight(floor.frameHeight);
            shade = new ShadowSprite(floor.x, floor.y);
            shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
            
            shade.shadow.setLightRadius(1, 60);
            topGround.add(shade);
        }

        snowman_brandy = FlxG.random.bool(100); // 100% chance to return 'true'

        if(snowman_brandy){
            var snowman = new FlxSprite();
            snowman.loadGraphic("assets/images/props/path_left/snowman_brandy.png");
            add(snowman);
            snowman.x = 152;
            snowman.y = 376;
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