package states.rooms;

import data.NGio;
import io.newgrounds.NG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import data.Manifest;
import states.OgmoState;
import data.Calendar;
import data.Game;
import data.Content;
import props.Cabinet;
import ui.Prompt;

import flixel.FlxG;
import flixel.math.FlxMath;

class VillageState extends RoomState
{
    override function create()
    {
        super.create();
        
        add(new vfx.Snow(40));

        if(Game.state.match(Intro(Started))){
            Game.state = Intro(Village);
            showIntroCutscene();
        }
    }
    
    override function initEntities()
    {
        super.initEntities();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }

    private function showIntroCutscene(){
        player.active = false;
        
        var cam = FlxG.camera;
        Manifest.playMusic("midgetsausage");
       //FlxG.sound.music.fadeIn(3);
        
        var delay = 0.0;
        //zoom in on player
        FlxTween.tween(cam, { zoom: 2 }, 0.75, 
            { startDelay:delay + 0.25
            , ease:FlxEase.quadInOut
            , onComplete: (_)->cam.follow(null)
            });
        delay += 1.0;
        //move up
        FlxTween.tween(cam.scroll, { y: cam.scroll.y - 800 }, 4.00, 
            { startDelay:delay + 0.5
            , ease:FlxEase.quadInOut
            });
        delay += 6.0;
        //move down
        FlxTween.tween(cam.scroll, { y: cam.scroll.y }, 4.00, 
            { startDelay:delay
            , ease:FlxEase.quadInOut
            , onComplete:function(_)
                {
                    player.active = true;
                    cam.follow(player, 0.1);
                    Game.state = NoEvent;
                    NGio.unlockMedal(66220);
                }
        });
    }
}