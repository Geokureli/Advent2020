package states.rooms;

import flixel.FlxObject;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import openfl.filters.ShaderFilter;
import vfx.ShadowShader;
import flixel.tweens.FlxTween;
import vfx.ShadowSprite;
import data.Game;
import data.Manifest;

class EntranceState extends RoomState
{
    var shade:ShadowSprite;
    
    override function create()
    {
        super.create();
        
        foreground.getByName("tree").setBottomHeight(32);
        
        #if debug
        if(Game.state.match(Day1Intro(Started)|Day1Intro(Dressed)))
            Game.state = Day1Intro(Hallway);
        #end
        
        switch(Game.state)
        {
            case Day1Intro(Hallway):
            {
                var floor = background.getByName("foyer");
                floor.setBottomHeight(floor.frameHeight);
                shade = new ShadowSprite(floor.x, floor.y);
                shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xEE000000);
                add(shade);
                
                player.active = false;
                ghostsGrp.visible = false;
                
                var present = null;
                for (p in presents)
                {
                    if (p.id == "cymbourine")
                    {
                        present = p;
                        break;
                    }
                }
                
                if (present == null)
                    throw "missing cymbouring present";
                
                shade.shadow.setLightPos(2, present.x + present.width / 2, present.y);
                var cam = FlxG.camera;
                
                Manifest.playMusic("albegian");
                var delay = 0.0;
                tweenLightRadius(1, 0, 60, 0.5,
                    { startDelay:1.0 });
                delay += 1.5;
                FlxTween.tween(cam, { zoom: 2 }, 0.75, 
                    { startDelay:delay + 0.25
                    , ease:FlxEase.quadInOut
                    , onComplete: (_)->cam.follow(null)
                    });
                // delay = tween.duration + tween.delay;
                delay += 1.0;
                FlxTween.tween(cam.scroll, { x: cam.scroll.x + 300 }, 1.00, 
                    { startDelay:delay + 0.5
                    , ease:FlxEase.quadInOut
                    });
                delay += 1.5;
                tweenLightRadius(2, 0, 100, 2.0, 
                    { startDelay:delay + 0.5
                    ,   onComplete: function(_)
                        {
                            tweenLightRadius(2, 100, 1000, 3.0, 
                                { startDelay:0.25
                                , ease:FlxEase.circInOut
                                });
                            FlxTween.tween(cam, { zoom: 1 }, 2.00, 
                                { startDelay: 0.25
                                , ease:FlxEase.quadInOut
                                });
                            showGhosts(0.5, 1.0);
                        }
                    });
                delay += 2.5 + 3.25;
                FlxTween.tween(cam.scroll, { x: cam.scroll.x }, 1.0, 
                    { startDelay:delay
                    , ease:FlxEase.quadInOut
                    ,   onComplete:function(_)
                        {
                            player.active = true;
                            cam.follow(player, 0.1);
                            remove(shade);
                            Game.state = NoEvent;
                        }
                    });
            }
            case _:
        }
    }
    
    function showGhosts(delay = 0.0, duration = 1.0)
    {
        ghostsGrp.visible = true;
        FlxTween.num(0, 1, 1.0, { startDelay: delay}, (num)->{ for(ghost in ghosts) ghost.alpha = num; });
    }
    
    // override function initEntities()
    // {
    //     super.initEntities();
        
        
    // }
    
    function tweenLightRadius(light:Int, from:Float, to:Float, duration:Float, options:TweenOptions)
    {
        if (options == null)
            options = {};
            
        if (options.ease == null)
            options.ease = FlxEase.circOut;
        
        return FlxTween.num(from, to, duration, options, (num)->shade.shadow.setLightRadius(light, num));
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        switch(Game.state)
        {
            case Day1Intro(_):
            {
                shade.shadow.setLightPos(1, player.x + player.width / 2, player.y + player.height / 2);
            }
            case _:
        }
    }
}