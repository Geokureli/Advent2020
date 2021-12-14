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
import flixel.text.FlxText;
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
    var loadedMedals2020 = #if SHOW_2020_SKINS_WARNING false #else true #end;
    
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
        
        var versionText = new FlxText(0, 0, 100);
        versionText.text = 'Version: ' + lime.app.Application.current.meta.get('version');
        versionText.y = FlxG.height - versionText.height;
        add(versionText);
        
        timeout = new FlxTimer().start(20, showErrorAndBegin);
        NGio.attemptAutoLogin(Save.getNgioSessionId(), onAutoConnectResult);
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
        Save.setNgioSessionId(NG.core.sessionId);
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
                if (Calendar.canSkip()
                    && (Calendar.isAdvent || Calendar.isDebugDay)
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
        load2020Medals(callbacks.add("2020medals"));
        NGio.updateServerVersion(callbacks.add("server version"));
        if (NG.core.loggedIn && NG.core.medals == null)
            NG.core.onMedalsLoaded.addOnce(callbacks.add("medal list"));
        
        callbacksSet();
    }
    
    inline public function load2020Medals(callback:()->Void)
    {
        #if LOAD_2020_SKINS
        var ngioSessionId2020 = Save.getNgioSessionId2020();
        if (ngioSessionId2020 == null)
        {
            callback();
            return;
        }
        NGio.fetch2020Medals(ngioSessionId2020, function (success)
            {
                #if SHOW_2020_SKINS_WARNING
                loadedMedals2020 = success || Save.hasSave2020();
                #end
                callback();
            }
        );
        #else
        callback();
        #end
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
        
        if (state.match(Error(false)) && FlxG.keys.justPressed.SPACE)
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
                        setCenteredNokiaMessage
                            ( "This browser is not supported, Chrome is recommended\n"
                            + "If you're using brave, try disabling shields for this page\n"
                            + "Sorry for the inconvenience"
                            );
                        setState(Error(true));
                        return;
                    }
                    
                    final showWarnings  = #if debug true #else false #end;
                    var errors = Content.verifyTodaysContent(showWarnings);
                    
                    if (errors != null)
                    {
                        var warningsOnly = true;
                        var blockingList = new Array<String>();
                        var warningList = new Array<String>();
                        for (error in errors)
                        {
                            switch (error)
                            {
                                case Blocking(msg):
                                    warningsOnly = false;
                                    blockingList.push(msg);
                                case Warning(msg):
                                    warningList.push(msg);
                            }
                        }
                        
                        if (showWarnings || NGio.isContributor)
                        {
                            if (debugFutureEnabled)
                                msg.text = "(debug) You pressed space to see tommorow's content.\n";
                            else
                                msg.text = "";
                            
                            if (blockingList.length > 0)
                            {
                                msg.text += "This day is not ready yet."
                                    + "\n\nErrors:\n" + blockingList.join("\n") + "\n";
                            }
                            else
                                msg.text += "There are no errors but there are non-blocking issues.\n"
                                    + "Non-collab players will not see this message.\n";
                            
                            if (warningList.length > 0)
                                msg.text += "\nWarnings:\n" + warningList.join("\n") + "\n";
                            
                            msg.text += "\nYou are only seeing this message because you are in the credits"
                                + "\n !NEW! Wait here and we'll tell you when it's ready!";
                            
                            // change text when it's loaded
                            startRefreshChecks(()->setCenteredNokiaMessage("IT'S UP, REFRESH THE PAGE! GO GO GO GO!1"));
                            
                            setState(Error(false));
                        }
                        else
                        {
                            setCenteredNokiaMessage
                                ( "Today's content is almost done, Sorry"
                                + "\n !NEW! Wait here and we'll tell you"
                                + "\n when it's ready!"
                                );
                            setState(Error(true));
                            
                            // change text when it's loaded
                            startRefreshChecks(()->setCenteredNokiaMessage("IT'S UP, REFRESH THE PAGE! GO GO GO GO!1"));
                            
                            return;
                        }
                    }
                    
                    if (state == Checking && (loadedMedals2020 == false || !isWebGl()))
                    {
                        msg.text = "";
                        state = Error(false);
                    }
                    
                    switch (state)
                    {
                        case Error(false):
                        {
                            msg.font = new NokiaFont();
                            
                            inline function appendSection(text:String)
                            {
                                if (msg.text != "")
                                    msg.text += "\n\n";
                                
                                msg.text += text;
                            }
                            
                            if (!isWebGl())
                            {
                                appendSection
                                    ( "You browser does not support webgl, meaning"
                                    + "\ncertain features and flourishes will not work"
                                    + "\nSorry for the inconvenience"
                                    );
                            }
                            
                            if (loadedMedals2020 == false)
                            {
                                appendSection
                                    ( "Could not find save data for previous years."
                                    + "\nLoad Tankmas ADVENTure 2020 to unlock more characters."
                                    );
                            }
                            
                            msg.text += "\nPress SPACE to play, anyway";
                            msg.screenCenter(XY);
                            return;
                        }
                        case Checking:
                        {
                            setState(Success);
                            onComplete();
                        }
                        default: throw "Unexpected state:" + state.getName();
                    }
                    
                case Success:
                case Error(_):
            }
        }
    }
    
    inline function startRefreshChecks(callback:()->Void)
    {
        // change text when it's loaded
        function checkServerVersion(timer:FlxTimer)
        {
            if (false == NGio.validVersion)
            {
                callback();
                timer.cancel();
            }
        }
        
        new FlxTimer().start(5, (t)->NGio.updateServerVersion(checkServerVersion.bind(t)), 0);
    }
    
    inline function setCenteredNokiaMessage(text:String)
    {
        msg.font = new NokiaFont();
        msg.text = text;
        msg.screenCenter(XY);
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
    
    function isWebGl()
    {
        return switch(FlxG.stage.window.context.type)
        {
            case OPENGL, OPENGLES, WEBGL: true;
            default: false;
        }
    }
    
    function onComplete()
    {
        preloadArt();
        
        Game.goToInitialRoom();
    }
    
    function preloadArt()
    {
        for (artwork in Content.artwork)
        {
            if (artwork.preload || (artwork.day == Calendar.day && artwork.comic != null))
                Manifest.loadArt(artwork.id);
        }
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
    Error(blocking:Bool);
}
