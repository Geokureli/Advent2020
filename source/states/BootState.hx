package states;

import data.Save;
import data.Calendar;
import data.Content;
import data.Game;
import data.APIStuff;
import data.Manifest;
import data.NGio;
import ui.Button;
import ui.Font;
import utils.MultiCallback;

import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import flixel.text.FlxBitmapText;
import flixel.graphics.frames.FlxBitmapFont;

import openfl.Assets;

import io.newgrounds.NG;

class BootState extends flixel.FlxState
{
    inline static var MSG_TIME = 1.5;
    var msg:FlxBitmapText;
    var timeout:FlxTimer;
    var state = LoggingIn;
    var waitTime = 0.0;
    
    var debugFutureEnabled = false;
    
    override public function create():Void
    {
        super.create();
        
        Save.init();
        Content.init(Assets.getText("assets/data/content.json"));
        FlxG.autoPause = false;
        
        FlxG.camera.bgColor = FlxG.stage.color;
        
        add(msg = new FlxBitmapText(new XmasFont()));
        msg.text = "Checking naughty list...";
        if (APIStuff.DebugSession != null)
            msg.text += "\n Debug Session";
        // if (Calendar.isDebugDay)
        //     msg.text += "\n Debug Day";
        
        msg.alignment = CENTER;
        msg.screenCenter(XY);
        
        timeout = new FlxTimer().start(20, showErrorAndBegin);
        NGio.attemptAutoLogin(onAutoConnectResult);
    }
    
    function onAutoConnectResult():Void
    {
        timeout.cancel();
        #if NG_BYPASS_LOGIN
        showMsgAndBegin("Login bypassed\nNot eligible for medals");
        #else
        if (NGio.isLoggedIn)
            onLogin();
        else
            NGio.startManualSession(onManualConnectResult, onManualConnectPending);
        #end
    }
    
    function onManualConnectPending(callback:(Bool)->Void)
    {
        msg.text = "Log in to Newgrounds?";
        msg.screenCenter(XY);
        var yes:Button = null;
        var no:Button = null;
        
        function onDecide(isYes:Bool)
        {
            remove(yes);
            remove(no);
            callback(isYes);
        }
        
        add(yes = new YesButton(150, msg.y + msg.height + 5, onDecide.bind(true )));
        add(no  = new NoButton (FlxG.width - 150, msg.y + msg.height + 5, onDecide.bind(false)));
        no.x -= no.width;
    }
    
    function onManualConnectResult(result:ConnectResult):Void
    {
        switch(result)
        {
            case Succeeded: onLogin();
            case Failed(_): showErrorAndBegin();
            case Cancelled: showMsgAndBegin("Login cancelled\nNot eligible for medals");
        }
    }
    
    function onLogin()
    {
        beginGame();
    }
    
    function beginGame():Void
    {
        setState(Initing);
        
        var callbacks = new MultiCallback(
            function ()
            {
                setState(Waiting);
                #if ALLOW_DAY_SKIP
                if ((Calendar.isAdvent || Calendar.isDebugDay)
                    && Calendar.day != 24
                    && NGio.isContributor)
                {
                    waitTime = MSG_TIME;
                    msg.text = "(debug)\n Press SPACE to time travel";
                    msg.screenCenter(XY);
                }
                #end
            }
            #if BOOT_LOG , "BootState" #end// add logid
        );
        var callbacksSet = callbacks.add("wait");
        Manifest.init(callbacks.add("manifest"));
        Calendar.init(callbacks.add("calendar"));
        if (NG.core.loggedIn && NG.core.medals == null)
            NG.core.onMedalsLoaded.addOnce(callbacks.add("medal list"));
        callbacksSet();
    }
    
    inline function showErrorAndBegin(_ = null)
    {
        showMsgAndBegin("Could not connect to Newgrounds\nNot eligible for medals");
    }
    
    function showMsgAndBegin(message:String)
    {
        msg.text = message;
        msg.screenCenter(XY);
        waitTime = MSG_TIME;
        beginGame();
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        waitTime -= elapsed;
        
        #if ALLOW_DAY_SKIP
        if (!debugFutureEnabled && state.match(Initing|Waiting) && FlxG.keys.pressed.SPACE)
        {
            debugFutureEnabled = true;
            msg.text = "DEBUG\nTime travel activated";
            msg.screenCenter(XY);
        }
        
        if (debugFutureEnabled && state.match(Error) && FlxG.keys.justPressed.SPACE)
            onComplete();
        #end
        
        if (waitTime < 0)
        {
            switch (state)
            {
                case LoggingIn:
                case Initing:
                case Waiting:
                    #if ALLOW_DAY_SKIP
                    
                    if (Calendar.canSkip() && debugFutureEnabled)
                    {
                        Calendar.showDebugNextDay();
                        if (waitTime < 0.5)
                            waitTime = 0.5;
                    }
                    #end
                    setState(Checking);
                case Checking:
                    
                    if(isBrowserFarbling())
                    {
                        msg.font = new NokiaFont();
                        msg.text = "This browser is not supported, Chrome is recommended\n"
                            + "If you're using brave, try disabling shields for this page\n"
                            + "Sorry for the inconvenience";
                        msg.screenCenter(XY);
                        setState(Error);
                        return;
                    }
                    
                    var errors = Content.verifyTodaysContent();
                    
                    if (errors != null)
                    {
                        setState(Error);
                        if (NGio.isContributor)
                        {
                            msg.font = new NokiaFont();
                            msg.text = "ERROR (debug):\n" + errors.join("\n")
                                + "\nPress SPACE to play, anyway";
                        }
                        else
                        {
                            msg.font = new NokiaFont();
                            msg.text = "Today's content is almost done,\nplease try again soon.\n Sorry";
                        }
                        msg.screenCenter(XY);
                        return;
                    }
                    
                    setState(Success);
                    onComplete();
                case Success:
                case Error:
            }
        }
    }
    
    function isBrowserFarbling()
    {
        #if js
        var bmd = new openfl.display.BitmapData(10, 10, false, 0xFF00FF);
        for(i in 0...bmd.width * bmd.height)
        {
            if (bmd.getPixel(i % 10, Std.int(i / 10)) != 0xFF00FF)
                return true;
        }
        #end
        return false;
    }
    
    function onComplete()
    {
        preloadArt("einmeister"); // takes forever to load, people think it froze
        
        Game.init();
        #if SKIP_TO_DIG_GAME
        Game.goToArcade(Digging);
        #else
        Game.goToRoom(Main.initialRoom);
        #end
    }
    
    function preloadArt(id:String)
    {
        final data = Content.artwork[id];
        if (Calendar.day >= data.day)
            Manifest.loadArt(id);
    }
    
    function preloadSong(id:String)
    {
        final data = Content.songs[id];
        if (Calendar.day >= data.day)
            Manifest.loadSong(id);
    }
    
    inline function setState(state:State)
    {
        #if BOOT_LOG
        log('state:${this.state}->$state');
        #end
        this.state = state;
    }
    
    inline static function log(msg)
    {
        #if BOOT_LOG trace(msg); #end
    }
}

private enum State
{
    LoggingIn;
    Initing;
    Waiting;
    Checking;
    Success;
    Error;
}
