package states;

import data.NGio;
import ui.Font;
import ui.OpenFlButton;

import flixel.FlxG;
import flixel.text.FlxBitmapText;
import flixel.system.FlxSound;

import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.display.MovieClip;
import openfl.utils.Assets;
import openfl.utils.AssetType;
import openfl.display.Sprite;

using states.ToyBoxState.SwfTools;

class ToyBoxState extends flixel.FlxSubState
{
    var toyBox:ToyBox;
    
    override function create()
    {
        super.create();
        
        final lib = Assets.getLibrary("butzbo");
        if (lib == null || !lib.exists("", cast AssetType.MOVIE_CLIP))
        {
            var text = new FlxBitmapText(new NokiaFont16());
            text.text = "Loading...";
            text.setBorderStyle(OUTLINE, 0xFF000000);
            text.screenCenter();
            add(text);
            
            Assets.loadLibrary("butzbo").onComplete(function(_)
            {
                remove(text);
                loadComplete();
            });
        }
        else
            loadComplete();
    }
    
    function loadComplete()
    {
        FlxG.stage.addChild(toyBox = new ToyBox());
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (toyBox != null)
        {
            toyBox.update(elapsed);
            
            if (toyBox.requestedExit || FlxG.keys.justPressed.ESCAPE)
                close();
        }
    }
    
    override function close()
    {
        FlxG.stage.removeChild(toyBox);
        super.close();
        toyBox.destroy();
    }
}

class ToyBox extends Sprite
{
    public var requestedExit = false;
    
    var swf:MovieClip;
    var toys = new Array<MovieClip>();
    var oneShots = new Array<MovieClip>();
    var sounds = new Map<String, FlxSound>();
    var clicked = new Map<String, Bool>();
    var backBtn:OpenFlBackButton;
    var cursor:MovieClip;
    var gearsSound:FlxSound;
    
    var songTime = 0.0;
    
    public function new ()
    {
        super();
        
        addChild(swf = Assets.getMovieClip("butzbo:animation"));
        swf.stopAllMovieClips();
        
        backBtn = new OpenFlBackButton(()->requestedExit = true);
        backBtn.x = FlxG.stage.stageWidth - backBtn.width * 2;
        addChild(backBtn);
        
        addChild(cursor = Assets.getMovieClip("butzbo:cursor"));
        cursor.mouseEnabled = false;
    }
    
    public function update(elapsed:Float)
    {
        backBtn.update(elapsed);
        if (swf.currentFrame == 1 && FlxG.mouse.justPressed)
        {
            swf.playTo("opened", onOpen);
            swf.requireByName("gearLeft" ).play();
            swf.requireByName("gearRight").play();
            gearsSound = playSound("gears", true);
        }
        else if (swf.currentLabel == "opened")
        {
            updateToys(elapsed);
        }
        
        cursor.x = mouseX;
        cursor.y = mouseY;
        cursor.gotoAndStop(FlxG.mouse.pressed ? 2 : 1);
    }
    
    function updateToys(elapsed:Float)
    {
        var minTime = Math.POSITIVE_INFINITY;
        for (sound in sounds)
        {
            sound.update(elapsed);
            if (sound.playing && sound.time < minTime && sound.looped)
                minTime = sound.time;
        }
        
        var hasReset = minTime < songTime;
        if (minTime < Math.POSITIVE_INFINITY)
            songTime = minTime / 1000;
        
        for (toy in toys)
        {
            var sound = sounds[toy.name];
            if (sound.playing)
            {
                if (hasReset)
                    sound.time = minTime;
                
                toy.gotoAndStop(Math.floor((sound.time / sound.length * (toy.totalFrames - 1)) + 1));
            }
        }
    }
    
    function onOpen()
    {
        function initToy(name:String, onClick:(MouseEvent)->Void, loops = false)
        {
            var sound = new FlxSound();
            sound.loadEmbedded('assets/sounds/butzbo/$name.mp3', loops);
            @:privateAccess
            sound.name = name;
            sounds[name] = sound;
            var toy = swf.requireByName(name);
            toy.gotoAndStop(1);
            toy.addEventListener(MouseEvent.CLICK, onClick);
            toy.buttonMode = true;
            toy.useHandCursor = true;
            clicked[toy.name] = false;
            return toy;
        }
        

        function initLooper(name:String)
        {
            var toy = initToy(name, clickToy, true);
            toys.push(toy);
            var sound = sounds[name];
            return toy;
        }
        
        function initOneShot(name:String)
        {
            return initToy(name, clickOneShot);
        }
        
        initLooper("snow"    );
        initLooper("tree"    );
        initLooper("tankman" );
        initLooper("tank"    );
        initLooper("frog"    );
        initLooper("reindeer");
        
        initOneShot("bird" );
        initOneShot("splat");
        initOneShot("cake" );
    }
    
    function clickOneShot(e:MouseEvent)
    {
        final toy = cast (e.target, MovieClip);
        
        sounds[toy.name].play(true);
        toy.playFromTo(2, 1);
        clicked[toy.name] = true;
        checkClicks();
    }
    
    function clickToy(e:MouseEvent)
    {
        final toy = cast (e.target, MovieClip);
        if (toy.currentFrame == 1)
        {
            toy.gotoAndStop(2);
            sounds[toy.name].play(true, songTime * 1000);
        }
        else
        {
            toy.gotoAndStop(1);
            sounds[toy.name].stop();
        }
        
        clicked[toy.name] = true;
        checkClicks();
    }
    
    function checkClicks()
    {
        if (NGio.isLoggedIn && NGio.hasMedalByName("butzbo") == false)
        {
            var clickedAll = true;
            for (click in clicked)
            {
                if (click == false)
                    clickedAll = false;
            }
            
            if (clickedAll)
                NGio.unlockMedalByName("butzbo");
        }
    }
    
    static function playSound(id:String, looped = false)
    {
        return FlxG.sound.play('assets/sounds/butzbo/$id.mp3', 1, looped);
    }
    
    public function destroy()
    {
        if (gearsSound != null)
            gearsSound.kill();
        gearsSound = null;
            
        for (sound in sounds)
            sound.kill();
        sounds.clear();
        
        var i = toys.length;
        while (i-- > 0)
            toys.shift().removeEventListener(MouseEvent.CLICK, clickToy);
        
        var i = oneShots.length;
        while (i-- > 0)
            oneShots.shift().removeEventListener(MouseEvent.CLICK, clickOneShot);
        
        backBtn.destroy();
    }
}

class SwfTools
{
    static public function getFrameOfLabel(mc:MovieClip, label:String)
    {
        for (data in mc.currentLabels)
        {
            if (data.name == label)
                return data.frame;
        }
        
        return 0;
    }
    
    static public function setFrameListener(mc:MovieClip, frame:Frame, listener:()->Void)
    {
        setFrameListenerHelper(mc, frame, listener, false);
    }
    
    static function setFrameListenerHelper(mc:MovieClip, frame:Frame, listener:()->Void, once = false)
    {
        final index = frame.getFrame(mc) - 1;
        
        var func = listener;
        if (listener != null && once)
        {
            func = function()
            {
                mc.addFrameScript(index, null);
                listener();
            }
        }
        
        mc.addFrameScript(index, func);
    }
    
    static public function setFrameListenerOnce(mc:MovieClip, frame:Frame, listener:()->Void)
    {
        setFrameListenerHelper(mc, frame, listener, true);
    }
    
    inline static public function playTo(mc:MovieClip, end:Frame, ?callback:()->Void)
    {
        mc.play();
        var func = mc.stop;
        if (callback != null)
        {
            func = function()
            {
                mc.stop();
                callback();
            }
        }
        setFrameListenerOnce(mc, end, func);
    }
    
    inline static public function playFromTo(mc:MovieClip, start:Frame, end, ?callback)
    {
        mc.gotoAndPlay(start.getFrame(mc));
        playTo(mc, end, callback);
    }
    
    static public function requireByName(mc:MovieClip, name:String):MovieClip
    {
        var child = mc.getChildByName(name);
        if (child == null)
            throw "Missing child:" + name;
        
        if (!Std.is(child, MovieClip))
            throw "Target must be a movieclip, child:" + name;
        
        return cast child;
    }
}

abstract Frame(Dynamic) from Int from String to Int to String
{
    public function getFrame(mc:MovieClip):Int
    {
        if (Std.is(this, Int))
            return cast this;
        
        return SwfTools.getFrameOfLabel(mc, cast this);
    }
}