package states;

import props.InputPlayer;
import props.InfoBox;
import states.OgmoState;
import utils.GameSize;
import vfx.PixelPerfectShader;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;

import openfl.filters.ShaderFilter;

class CabinState extends BaseState
{
    override public function new ()
    {
        super();
    }
    
    override function create()
    {
        GameSize.setPixelSize(4);
        super.create();
        
        FlxG.camera.setFilters([new ShaderFilter(new PixelPerfectShader(4))]);
        FlxG.camera.pixelPerfectRender = true;
    }
    
    override function loadLevel():Void
    {
        parseLevel("assets/data/ogmo/cabin22.json");
        
        // #if debug FlxG.debugger.drawDebug = true; #end
    }
    
    override function initEntities()
    {
        super.initEntities();
        
        initClient();
        
        var tree = foreground.getByName("tree_22");
        if (tree != null)
        {
            tree.setBottomHeight(10);
            tree.setMiddleWidth(25);
        }
        
        var arcade = foreground.getByName("arcade");
        if (arcade != null)
        {
            // arcade.animation.curAnim.frameRate = 6;
            // addHoverTextTo(arcade, "2018 Advent", openUrl.bind(ADVENT_LINK));
        }
        var tv:FlxSprite = foreground.getByName("tv");
        tv.animation.curAnim.frameRate = 6;
        addHoverTextTo(tv, "");
        var tvBubble = cast props.getByName("TvBubble");
        tvBubble.kill();
        
        var arcade;
        arcade = foreground.getByName("arcade");
        if (arcade != null)
            arcade.animation.curAnim.frameRate = 6;
        
        arcade = foreground.getByName("arcade2");
        if (arcade != null)
            arcade.animation.curAnim.frameRate = 6;
        
        background.safeSetAnimFrameRate("neon", 2);
        
        var calendar = foreground.getByName("calendar");
        // if (Calendar.isPast || Calendar.day + 1 == 25 || Calendar.isDebugDay)
        // {
        // 	var label = "Calendar";
        // 	if (!Calendar.isPast && Calendar.day + 1 != 25)
        // 		label += "\n(debug)";
        // 	addHoverTextTo(calendar, label, ()->openSubState(new CalendarSubstate(onCalendarDateChange)));
        // }
        // else
        // 	calendar.kill();
        
        var jukebox = foreground.getByName("jukebox");
        // if (Calendar.isPast || Calendar.day + 1 == 25 || Calendar.isDebugDay)
        // {
            var label = "Switch Music";
            // if (!Calendar.isPast && Calendar.day + 1 != 25)
            // 	label += "\n(debug)";
            addHoverTextTo(jukebox, label, 
                function()
                {
                    if (FlxG.sound.music == null)
                    {
                        FlxG.sound.music = dj.SongLoader.loadSong("976686", 
                            function (response)
                            {
                                switch(response)
                                {
                                    case Fail(type):
                                        trace("SongLoader failed: " + type);
                                        FlxG.sound.music = null;
                                    case Success(sound):
                                        FlxG.sound.music.play();
                                }
                            }
                        );
                    }
                }
            );
        // }
        // else
        // 	jukebox.kill();
        
        //Music Credit
        safeAddHoverText
            ( "stereo"
            , "Music by [redacted]"
            // , openUrl.bind(Calendar.today.musicProfileLink)
            );
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (FlxG.keys.justPressed.Z)
            GameSize.setPixelSize(1);
        else if (FlxG.keys.justPressed.X)
            GameSize.setPixelSize(2);
        else if (FlxG.keys.justPressed.C)
            GameSize.setPixelSize(4);
        
        if (FlxG.keys.justPressed.ENTER)
        {
            trace("resetting");
            FlxG.resetState();
        }
    }
}