package states.rooms;

import data.Game;
import data.Manifest;
import data.NGio;
import states.OgmoState;
import vfx.ShadowShader;
import vfx.ShadowSprite;
import vfx.PeekDitherShader;

import schema.Avatar;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import openfl.filters.ShaderFilter;

class EntranceState extends RoomState
{
    inline static var TREE_HIDE_Y = 160;
    
    var shade:ShadowSprite;
    var chandelier:OgmoDecal;
    var tree:OgmoDecal;
    var treeShader:PeekDitherShader;
    var chandelierShader:PeekDitherShader;
    
    override function create()
    {
        super.create();
        
        #if debug
        if(Game.state.match(Day1Intro(Started)|Day1Intro(Dressed)))
            Game.state = Day1Intro(Hallway);
        #end
        
        switch(Game.state)
        {
            case Day1Intro(Hallway):
                showIntroCutscene();
            case _:
        }
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        tree = getDaySprite(foreground, "tree");
        tree.setBottomHeight(32);
        tree.setMiddleWidth(56);
        treeShader = new PeekDitherShader();
        tree.shader = treeShader;
        if (player.y < TREE_HIDE_Y)
            treeShader.setAlpha(0);
        
        chandelier = background.getByName("Chandelier");
        if (chandelier != null)
        {
            background.remove(chandelier);
            topGround.add(chandelier);
            chandelier.scrollFactor.y = 2.0;
            chandelierShader = new PeekDitherShader();
            chandelier.shader = chandelierShader;
            // chandelierShader.setAlpha(0);
        }
        
        safeAddHoverText("jar_small", "Spread the Love",
            function ()
            {
                NGio.logEvent(donate);
                openUrl
                    ( "https://www.toysfortots.org/default.aspx"
                    , "Help bring Tankmas joy to less-fortunate children?"
                    , ()->NGio.logEvent(donate_yes)
                    );
            }
        );
    }
    
    function showIntroCutscene()
    {
        var floor = background.getByName("foyer");
        floor.setBottomHeight(floor.frameHeight);
        shade = new ShadowSprite(floor.x, floor.y);
        shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
        if (Game.allowShaders)
            topGround.add(shade);
        
        player.active = false;
        player.flipX = true;
        for (ghost in ghosts.members)
            ghost.visible = false;
        
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
                    NGio.logEvent(intro_complete);
                }
            });
    }
    
    function showGhosts(delay = 0.0, duration = 1.0)
    {
        for(ghost in ghosts)
        {
            ghost.visible = true;
            ghost.alpha = 0;
        }
        
        FlxTween.num(0, 1, 1.0, { startDelay: delay}, (num)->{ for(ghost in ghosts) ghost.alpha = num; });
    }
    
    override function onAvatarAdd(data:Avatar, key:String)
    {
        super.onAvatarAdd(data, key);
        
        if (ghostsById.exists(key) && Game.state.match(Day1Intro(_)))
            ghostsById[key].visible = false;
    }
    
    function tweenLightRadius(light:Int, from:Float, to:Float, duration:Float, options:TweenOptions)
    {
        if (options == null)
            options = {};
            
        if (options.ease == null)
            options.ease = FlxEase.circOut;
        
        return FlxTween.num(from, to, duration, options, (num)->shade.shadow.setLightRadius(light, num));
    }
    
    inline static var TREE_HIDE_TIME = 2.0;
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        switch(Game.state)
        {
            case Day1Intro(_):
                shade.shadow.setLightPos(1, player.x + player.width / 2, player.y + player.height / 2);
            case _:
        }
        
        // final isBehindTree = player.y < tree.y && player.x > tree.x && player.x + player.width < tree.x + tree.width;
        if (Game.allowShaders)
        {
            final hideTree = player.y < TREE_HIDE_Y;
            treeShader.setPlayerPosWithSprite(player.x + player.width / 2, player.y, tree);
            if (hideTree)
                treeShader.setAlpha(Math.max(0, treeShader.getAlpha() - elapsed / TREE_HIDE_TIME));
            else
                treeShader.setAlpha(Math.min(1, treeShader.getAlpha() + elapsed / TREE_HIDE_TIME));
            
            if (chandelier != null)
                chandelierShader.setPlayerPosWithSprite(player.x + player.width / 2, player.y, chandelier);
        }
        else// CANVAS
        {
            final isBehindTree = player.y < tree.y && player.x > tree.x && player.x + player.width < tree.x + tree.width;
            final hideTree = player.y < TREE_HIDE_Y || isBehindTree;
            if (hideTree)
                tree.alpha = Math.max(0, tree.alpha - elapsed / TREE_HIDE_TIME);
            else
                tree.alpha = Math.min(1, tree.alpha + elapsed / TREE_HIDE_TIME);
            
            if (chandelier != null)
            {
                if (hideTree)
                    chandelier.alpha = Math.min(1, chandelier.alpha + elapsed / TREE_HIDE_TIME);
                else
                    chandelier.alpha = Math.max(0, chandelier.alpha - elapsed / TREE_HIDE_TIME);
            }
        }
        
    }
}