package props;

import flixel.FlxG;
import ui.Controls;

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
        else if (allowSkip && state == SHOWING && pressedAdvance())
            advanceQueue();
    }
    
    function pressedAdvance()
    {
        return Controls.justPressed.A || FlxG.mouse.justPressed;
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

enum abstract BubbleState(Int)
{
    var HIDDEN;
    var ANIMATING;
    var SHOWING;
}