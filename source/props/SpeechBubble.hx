package props;

import flixel.math.FlxRect;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import flixel.addons.display.FlxSliceSprite;

class SpeechBubble extends flixel.group.FlxSpriteGroup
{
    inline static var PADDING = 2;
    
    public var bubble(default, null):Bubble;
    public var text(default, null):Text;
    public var tail(default, null):Tail;
    public var minWidth = 0.0;
    public var minHeight = 0.0;
    
    var tween:FlxTween = null;
    
    public function new (x = 0.0, y = 0.0)
    {
        super(x, y);
        
        add(bubble = new Bubble());
        add(tail = new Tail());
        add(text = new Text());
        
        text.color = 0xFF000000;
    }
    
    inline static var PAD = 4;
    public function show(msg:String)
    {
        visible = true;
        text.text = msg;
        tail.height = tail.frameHeight;
        bubble.offset.y = 0;
        bubble.width = Math.max(minWidth, text.width + PAD * 2);
        bubble.height = Math.max(minHeight, text.height + PAD * 2);
        bubble.y = tail.y - bubble.height + 1;
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
        // tail.killTweens();
        if (tween != null)
        {
            tween.cancelChain();
            tween = null;
        }
    }
    
    public function animateNextMessage(msg, ?callback)
    {
        var oldMsg = text.text;
        show(msg);
        var height = bubble.height;
        var width = bubble.width;
        var textY = text.y;
        show(oldMsg);
        
        function startOrChain(newTween)
        {
            if (tween != null)
                tween.then(newTween);
            else
                tween = newTween;
        }
        
        var changingSize = bubble.width != width || bubble.height != height;
        var moveText = null;
        if (changingSize)
            moveText = ()-> { text.y = textY; }
        
        if (oldMsg != "")
            startOrChain(text.tweenOut(oldMsg, moveText));
        
        if (changingSize)
            startOrChain(bubble.tweenTo(width, height, FlxEase.cubeInOut));
        
        startOrChain(text.tweenIn(msg, callback));
    }
    
    public function animateIn(msg, ?callback)
    {
        show(msg);
        var height = bubble.height;
        bubble.height = 1;
        if (bubble.facing.has(UP))
            bubble.y = tail.y;
        text.text = " ";
        
        tail.animateIn();
        tween = bubble.tweenHeightTo(height, FlxEase.cubeOut)
            .then(text.tweenIn(msg, callback));
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
        
        tween = text.tweenOut(msg);
        var bubbleTween = bubble.tweenHeightTo(0, FlxEase.cubeIn, func);
        bubbleTween.onStart = (_)->tail.animateOut();
        tween.then(bubbleTween);
    }
}

inline var BUBBLE_TWEEN_TIME = 0.25;
inline var MIN_TEXT_TWEEN_TIME = 0.5;
inline var MAX_CHAR_TIME = 0.02;

@:forward
private abstract Bubble(FlxSliceSprite) to FlxSliceSprite
{
    
    inline public function new (width = 1, height = 1)
    {
        this = new FlxSliceSprite
            ( "assets/images/emotes/bubble.png"
            , flixel.math.FlxRect.weak(1, 1, 7, 7)
            , width, height
            );
        
        this.facing = UP;
    }
    
    inline public function tweenHeightTo(height:Float, ease, ?callback):FlxTween
    {
        return tweenTo(null, height, ease, callback);
    }
    
    public function tweenTo(?width:Float, height:Float, ease:EaseFunction, ?callback:()->Void):FlxTween
    {
        var options:TweenOptions = { ease:ease };
        
        if (callback != null)
            options.onComplete = (_)->callback();
        
        var vars:Dynamic = { height:height };
        
        if (this.facing.has(UP) && this.height != height)
        {
            vars.y = this.y + this.height - height;
        }
        
        if (width != null && width != this.width)
            vars.width = width;
        
        return FlxTween.tween(this, vars, BUBBLE_TWEEN_TIME, options);
    }
}

@:forward
private abstract Text(flixel.text.FlxBitmapText) to flixel.text.FlxBitmapText
{
    inline public function new ()
    {
        this = new flixel.text.FlxBitmapText(new ui.Font.NokiaFont());
    }
    
    inline public function getTweenTime(msg:String):Float
    {
        return Math.min(MIN_TEXT_TWEEN_TIME, msg.length * MAX_CHAR_TIME);
    }
    
    public function tweenIn(msg:String, ?callback:()->Void):FlxTween
    {
        var options:TweenOptions = { ease:FlxEase.cubeOut };
        if (callback != null)
            options.onComplete = (_)->callback();
        
        return FlxTween.num(0, 1, getTweenTime(msg), options, showMsgPercent.bind(msg, _));
    }
    
    public function tweenOut(msg:String, ?callback:()->Void):FlxTween
    {
        var options:TweenOptions = { ease:FlxEase.cubeIn };
        if (callback != null)
            options.onComplete = (_)->callback();
        
        return FlxTween.num(1, 0, getTweenTime(msg), options, showMsgPercent.bind(msg, _));
    }
    
    inline public function showMsgPercent(msg:String, pecent:Float)
    {
        this.text = msg.substr(0, Std.int(msg.length * pecent));
    }
}

@:forward
private abstract Tail(FlxSprite) to FlxSprite
{
    public var height(get, set):Float;
    inline public function get_height() return this.height;
    public function set_height(value:Float)
    {
        this.height = value;
        updateRect();
        return this.height;
    }
    
    public var flipX(get, set):Bool;
    public function get_flipX() return this.flipX;
    public function set_flipX(value:Bool)
    {
        updateRect();
        return this.flipX;
    }
    
    inline public function new (x = 0, y = 0)
    {
        this = new FlxSprite(x, y, "assets/images/emotes/bubbleTail.png");
        this.y -= this.frameHeight;
        this.clipRect = FlxRect.get();
    }
    
    public function killTweens()
    {
        FlxTween.cancelTweensOf(this);
    }
    
    public function animateIn():FlxTween
    {
        this.height = 0;
        function update(_) updateRect();
        return FlxTween.tween(this, { height:this.frameHeight }, BUBBLE_TWEEN_TIME,
            { onUpdate: update, onComplete: update }
        );
    }
    
    public function animateOut():FlxTween
    {
        function update(_) updateRect();
        return FlxTween.tween(this, { height:0 }, BUBBLE_TWEEN_TIME,
            { onUpdate: update, onComplete: update }
        );
    }
    
    inline function updateRect()
    {
        this.offset.y = Std.int(this.frameHeight - height);
        this.clipRect.set(flipX ? -this.width: 0, this.offset.y, this.width, this.height);
        this.clipRect = this.clipRect;
    }
}