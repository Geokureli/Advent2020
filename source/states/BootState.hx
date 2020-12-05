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
        state = Initing;
        
        var callbacks = new MultiCallback(
            function ()
            {
                state = Waiting;
                #if ALLOW_DAY_SKIP
                if ((Calendar.isAdvent || Calendar.isDebugDay)
                    && Calendar.day != 24
                    && NGio.isContributor)
                {
                    waitTime = MSG_TIME;
                    msg.text = "(debug)\n Press SPACE to time travel";
                }
                #end
            }
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
        }
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
                    state = Checking;
                case Checking:
                    
                    var errors = Content.verifyTodaysContent();
                    if (errors != null)
                    {
                        state = Error;
                        if (NGio.isContributor)
                        {
                            msg.font = new NokiaFont();
                            msg.text = "ERROR (debug):\n" + errors.join("\n");
                        }
                        else
                        {
                            msg.font = new NokiaFont();
                            msg.text = "Today's content is almost done,\nplease try again soon.\n Sorry";
                        }
                        msg.screenCenter(XY);
                        return;
                    }
                    
                    state = Success;
                    onComplete();
                case Success:
                case Error:
            }
        }
    }
    function onComplete()
    {
        Game.init();
        Game.goToRoom(Main.initialRoom);
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
