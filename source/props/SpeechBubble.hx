package props;

import ui.Controls;
import data.PlayerSettings;
import flixel.tweens.FlxEase;
import ui.Font;

import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxTween;

import flixel.addons.display.FlxSliceSprite;


class SpeechBubble extends flixel.group.FlxSpriteGroup
{
    inline static var PADDING = 2;
    
    public var bubble(default, null):Bubble;
    public var text(default, null):FlxBitmapText;
    public var minWidth = 0.0;
    public var minHeight = 0.0;
    
    var tween:FlxTween = null;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        
        add(bubble = new Bubble());
        add(text = new FlxBitmapText(new NokiaFont()));
        
        text.color = 0xFF000000;
    }
    
    inline static var PAD = 4;
    public function show(msg:String)
    {
        visible = true;
        text.text = msg;
        bubble.width = Math.max(minWidth, text.width + PAD * 2);
        bubble.height = Math.max(minHeight, text.height + PAD * 2);
        text.x = bubble.x + PAD + 1;
        text.y = bubble.y + PAD + 1;
        
        killTween();
    }
    
    public function hide()
    {
        visible = false;
    }
    
    inline function killTween()
    {
        if (tween != null)
        {
            tween.cancelChain();
            tween = null;
        }
    }
    
    public function animateNextMessage(msg, ?callback)
    {
        var oldMsg = text.text;
        var oldHeight = bubble.height;
        var oldWidth = bubble.width;
        show(msg);
        var height = bubble.height;
        var width = bubble.width;
        
        text.text = oldMsg;
        bubble.width = oldWidth;
        bubble.height = oldHeight;
        
        function startOrChain(newTween)
        {
            if (tween != null)
                tween.then(newTween);
            else
                tween = newTween;
        }
        
        if (oldMsg != "")
            startOrChain(tweenTextOut(oldMsg));
        
        if (oldWidth != width || oldHeight != height)
            startOrChain(tweenBubbleTo(width, height, FlxEase.cubeInOut));
        
        startOrChain(tweenTextIn(msg, callback));
    }
    
    public function animateIn(msg, ?callback)
    {
        show(msg);
        var height = bubble.height;
        bubble.height = 1;
        text.text = " ";
        
        tween = tweenBubbleHeightTo(height, FlxEase.cubeOut)
            .then(tweenTextIn(msg, callback));
    }
    
    public function animateOut(?callback)
    {
        var msg = text.text;
        show(msg);
        
        // hide on completion
        function func ()
        {
            hide();
            if (callback != null) callback();
        }
        
        
        tween = tweenTextOut(msg)
            .then(tweenBubbleHeightTo(0, FlxEase.cubeIn, func));
    }
    
    inline static var BOX_TWEEN_TIME = 0.25;
    inline function tweenBubbleHeightTo(height:Float, ease, ?callback):FlxTween
    {
        return tweenBubbleTo(null, height, ease, callback);
    }
    
    function tweenBubbleTo(?width:Float, height:Float, ease:EaseFunction, ?callback:()->Void):FlxTween
    {
        var options:TweenOptions = { ease:ease };
        if (callback != null)
            options.onComplete = (_)->callback();
        
        var vars:Dynamic = { height:height };
        if (width != null && width != bubble.width)
            vars.width = width;
        
        return FlxTween.tween(bubble, vars, BOX_TWEEN_TIME, options);
    }
    
    inline static var MIN_TEXT_TWEEN_TIME = 0.5;
    inline static var MAX_CHAR_TIME = 0.02;
    inline function getTextTweenTime(msg:String):Float
    {
        return Math.min(MIN_TEXT_TWEEN_TIME, msg.length * MAX_CHAR_TIME);
    }
    
    function tweenTextIn(msg:String, ?callback:()->Void):FlxTween
    {
        var options:TweenOptions = { ease:FlxEase.cubeOut };
        if (callback != null)
            options.onComplete = (_)->callback();
        
        return FlxTween.num(0, 1, getTextTweenTime(msg), options, showMsgPercent.bind(msg, _));
    }
    
    function tweenTextOut(msg:String, ?callback:()->Void):FlxTween
    {
        var options:TweenOptions = { ease:FlxEase.cubeIn };
        if (callback != null)
            options.onComplete = (_)->callback();
        
        return FlxTween.num(1, 0, getTextTweenTime(msg), options, showMsgPercent.bind(msg, _));
    }
    
    inline function showMsgPercent(msg:String, pecent:Float)
    {
        text.text = msg.substr(0, Std.int(msg.length * pecent));
    }
}

class SpeechBubbleQueue extends SpeechBubble
{
    /** Time to move on in the queue, automatically. */
    public var advanceTimer = Math.POSITIVE_INFINITY;
    public var allowSkip = true;
    public var allowCancel = true;
    
    var state:BubbleState = HIDDEN;
    var queue:Array<String>;
    var queueCallback:()->Void;
    var timer = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
    }
    
    public function showMsgQueue(queue:Array<String>, ?callback:()->Void)
    {
        if (state != HIDDEN)
            throw "Already showing a message";
        
        this.queue = queue;
        queueCallback = callback;
        
        advanceQueue();
    }
    
    public function showMsgQueueUniformSize(queue:Array<String>, ?callback:()->Void)
    {
        if (state != HIDDEN)
            throw "Already showing a message";
        
        this.minWidth = 0;
        this.minHeight = 0;
        var minWidth = 0.0;
        var minHeight = 0.0;
        for (msg in queue)
        {
            show(msg);
            
            if (minWidth < bubble.width)
                minWidth = bubble.width;
            
            if (minHeight < bubble.height)
                minHeight = bubble.height;
        }
        
        hide();
        this.minWidth = minWidth;
        this.minHeight = minHeight;
        showMsgQueue(queue, callback);
    }
    
    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (state == SHOWING && Math.isFinite(advanceTimer))
        {
            timer += elapsed;
            if (timer > advanceTimer)
            {
                advanceQueue();
                return;
            }
        }
        
        if (allowCancel && Controls.justPressed.B)
            cancelQueue();
        else if (allowSkip && state == SHOWING && Controls.justPressed.A)
            advanceQueue();
    }
    
    function advanceQueue()
    {
        if (queue.length == 0)
            cancelQueue();
        else if (state == HIDDEN)
            animateIn(queue.shift());
        else
            animateNextMessage(queue.shift());
    }
    
    public function cancelQueue()
    {
        if (state != HIDDEN) // SHOWING | ANIMATING
            animateOut(queueCallback);
        else if (queueCallback != null)
            queueCallback();
        
        queueCallback = null;
    }
    
    override function show(msg:String)
    {
        super.show(msg);
        state = SHOWING;
    }
    
    override function hide()
    {
        super.hide();
        state = HIDDEN;
    }
    
    inline function addToCallback(callback:()->Void, addition:()->Void)
    {
        return
            if (callback == null)
                addition;
            else
                function () { addition(); callback(); }
    }
    
    override function animateNextMessage(msg, ?callback)
    {
        timer = 0;
        super.animateNextMessage(msg, addToCallback(callback, ()->state = SHOWING));
        state = ANIMATING;
    }
    
    override function animateIn(msg, ?callback)
    {
        timer = 0;
        super.animateIn(msg, addToCallback(callback, ()->state = SHOWING));
        state = ANIMATING;
    }
    
    override function animateOut(?callback)
    {
        super.animateOut(callback);// already calls hide() on complete
        state = ANIMATING;
    }
}

@:forward
abstract Bubble(FlxSliceSprite) to FlxSliceSprite
{
    inline public function new (width = 1, height = 1)
    {
        this = new FlxSliceSprite
            ( "assets/images/emotes/bubble.png"
            , flixel.math.FlxRect.weak(1, 1, 7, 7)
            , width, height
            );
    }
}

enum abstract BubbleState(Int)
{
    var HIDDEN;
    var ANIMATING;
    var SHOWING;
}