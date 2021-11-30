package states.rooms;

import data.Game;
import data.Manifest;
import states.OgmoState;
import states.LuciaReadySetGo;
import vfx.ShadowShader;
import vfx.ShadowSprite;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import openfl.filters.ShaderFilter;

class HallwayState extends RoomState
{
    var shade:ShadowSprite;
    
    override function create()
    {
        #if debug
        if(Game.state.match(Intro(Started)))
            Game.state = Intro(Dressed);
        #end
        
        if(Game.state.match(Intro(Dressed)))
            forceDay = 1;
        
        super.create();
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        if (Game.allowShaders)
        {
            switch(Game.state)
            {
                case Intro(Dressed):
                {
                    var floor = getDaySprite(background, "hallway");
                    floor.setBottomHeight(floor.frameHeight);
                    shade = new ShadowSprite(floor.x, floor.y);
                    shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
                    for (i=>candle in background.getAllWithName("candle").members)
                        shade.shadow.setLightPos(i + 2, candle.x + candle.width / 2, candle.y);
                    topGround.add(shade);
                    
                    player.active = false;
                    
                    tweenLightRadius(1, 0, 60, 0.35, { startDelay:1.0, onComplete:(_)->player.active = true });
                }
                case Intro(Hallway):
                {
                    var floor = getDaySprite(background, "hallway");
                    floor.setBottomHeight(floor.frameHeight);
                    shade = new ShadowSprite(floor.x, floor.y);
                    shade.makeGraphic(floor.frameWidth, floor.frameHeight, 0xD8000022);
                    
                    shade.shadow.setLightRadius(1, 60);
                    for (i=>candle in background.getAllWithName("candle").members)
                        shade.shadow.setLightPos(i + 2, candle.x + candle.width / 2, candle.y);
                    topGround.add(shade);
                }
                case _:
            }
        }
        else if (Game.state.match(Intro(Dressed)))
            Game.state = Intro(Hallway);
    }
    
    function tweenLightRadius(light:Int, from:Float, to:Float, duration:Float, options:TweenOptions)
    {
        if (options == null)
            options = {};
            
        if (options.ease == null)
            options.ease = FlxEase.circOut;
        
        FlxTween.num(from, to, duration, options, (num)->shade.shadow.setLightRadius(light, num));
    }
    
    override function initClient()
    {
        if(!Game.state.match(Intro(_)))
            super.initClient();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        switch(Game.state)
        {
            case Intro(eventState):
            {
                if (Game.allowShaders)
                {
                    shade.shadow.setLightPos(1, player.x + player.width / 2, player.y - 48);
                    
                    if (eventState == Dressed && player.x > shade.shadow.getLightX(2))
                    {
                        Game.state = Intro(Hallway);
                        for (i in 0...4)
                            tweenLightRadius(i + 2, 0, 80, 0.6, { startDelay:i * 0.75 });
                    }
                }
            }
            case LuciaDay(Started):
            {
                Game.state = LuciaDay(Finding);
                var substate = new LuciaReadySetGo();
                substate.closeCallback = function ()
                {
                    initLuciaUi();
                }
                openSubState(substate);
            }
            case _:
        }
    }
}