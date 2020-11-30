package states;


import openfl.Assets;

import flixel.FlxG;
import flixel.ui.FlxButton;
import flixel.util.FlxTimer;
import flixel.text.FlxBitmapText;

import data.Content;
import data.Game;
import data.APIStuff;
import data.Manifest;
import data.NGio;
import ui.Button;
import ui.Font;

class BootState extends flixel.FlxState
{
    inline static var MSG_TIME = 1.5;
    var msg:FlxBitmapText;
    var timeout:FlxTimer;
    var state = LoggingIn;
    var waitTime = MSG_TIME;
    
    var debugFutureEnabled = false;
    
    override public function create():Void
    {
        super.create();
        
        Game.init();
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
        #if BYPASS_LOGIN
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
        
        add(yes = new YesButton(100, msg.y + msg.height + 5, onDecide.bind(true )));
        add(no  = new NoButton (190, msg.y + msg.height + 5, onDecide.bind(false)));
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
        // Calendar.init(()->state = Waiting);
        state = Waiting;
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
    
    function startLoading()
    {
        state = Loading;
        
        // final canSkip
        //     = (Calendar.isAdvent || Calendar.isDebugDay)
        //     && Calendar.day != 24
        //     #if !(debug) && NGio.isWhitelisted #end;
        // 
        // if (canSkip && debugFutureEnabled)
        // {
        //     Calendar.showDebugNextDay();
        //     msg.text += "\nTime travel activated";
        //     if (waitTime < 0.5)
        //         waitTime = 0.5;
        // }
        
        Manifest.init(()->state = Checking);
    }
    
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);
        waitTime -= elapsed;
        
        if (state.match(Initing|Waiting) && FlxG.keys.pressed.SPACE)
            debugFutureEnabled = true;
        
        if (waitTime < 0)
        {
            switch (state)
            {
                case LoggingIn:
                case Initing:
                case Waiting:
                    startLoading();
                case Loading:
                case Checking:
                    // Todo check assets
                    state = Success;
                    Game.goToRoom(Main.initialRoom);
                case Success:
                case Error:
            }
        }
    }
}

private enum State
{
    LoggingIn;
    Initing;
    Waiting;
    Loading;
    Checking;
    Success;
    Error;
}
