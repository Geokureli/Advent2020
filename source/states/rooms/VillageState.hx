package states.rooms;

import vfx.PeekDitherShader;
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
    var knose_note:OgmoDecal;
    var tree:OgmoDecal;
    var treeShader:PeekDitherShader;

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

        tree = getDaySprite(foreground, "pinecone_stage5");
        if(tree != null){
            treeShader = new PeekDitherShader(tree);
            tree.shader = treeShader;
        }

        var barrack = background.getByName("barrack");
        var sign = foreground.getByName("sign_1");
        addHoverTextTo(barrack, "UNDER CONSTRUCTION", () -> {});
        addHoverTextTo(sign, "POST OFFICE UNDER CONSTRUCTION", () -> {});
        
        knose_note = foreground.getByName("knose-note");
        if(knose_note != null){
            knose_note.visible = false;
        }
        if(Calendar.day == 8){
            addHoverTextTo(foreground.getByName("garbage_can"), "LOOK", ()->{ knose_note.visible = !knose_note.visible; });
        }else if(Calendar.day == 9){
            knose_note.loadGraphic("assets/images/props/village/knose-note9.png");
            addHoverTextTo(foreground.getByName("garbage_can"), "LOOK", ()->{ knose_note.visible = !knose_note.visible; });
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(Game.state.match(Intro(_)) == false){
            var top = 700;
            var bottom = FlxG.worldBounds.height - 32;
            var height = bottom - top;
            var progress = FlxMath.bound((player.y - top) / height, 0, 1);
            camera.zoom = 1.0 + progress;
        }
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
        FlxTween.tween(cam.scroll, { y: cam.scroll.y - 300 }, 4.00, 
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