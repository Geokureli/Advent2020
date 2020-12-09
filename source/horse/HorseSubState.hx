package horse;

import data.NGio;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxVector;
import flixel.text.FlxBitmapText;

class HorseSubState extends flixel.FlxSubState
{
    inline static var COUNT_DOWN = 10.0;
    inline static var CANE_EDGE = 22;
    
    var gameLayer = new FlxGroup();
    var uiLayer = new FlxGroup();
    var nick:Nick;
    var tail:FlxSprite;
    var instructions:FlxBitmapText;
    
    var state = State.Unstarted;
    var time = 0.0;
    var score = 0;
    
    override function create()
    {
        super.create();
        
        add(gameLayer);
        add(uiLayer);
        
        var frame = new FlxSprite("assets/images/ui/cane_frame.png");
        frame.screenCenter(X);
        frame.y = FlxG.height - frame.height;
        uiLayer.add(frame);
        
        var bg = new FlxSprite(frame.x + CANE_EDGE, frame.y + CANE_EDGE);
        bg.makeGraphic(frame.frameWidth - CANE_EDGE * 2, frame.frameHeight - CANE_EDGE * 2);
        gameLayer.add(bg);
        
        var title = new FlxBitmapText(new ui.Font.XmasFont());
        title.text = "Pin the tail on Nick Conter!";
        title.y = (bg.y - title.height) / 2;
        title.screenCenter(X);
        title.x += 2; // kerning
        add(title);
        
        instructions = new FlxBitmapText(new ui.Font.XmasFont());
        instructions.alignment = CENTER;
        instructions.text = "Click to start";
        instructions.color = 0xFF000000;
        instructions.y = bg.y + instructions.height / 2;
        instructions.screenCenter(X);
        instructions.x += 2; // kerning
        add(instructions);
        
        nick = new Nick();
        nick.setMaskfrom(bg);
        
        gameLayer.add(nick);
        
        tail = new FlxSprite("assets/images/horse/tail.png");
        tail.offset.set(35, 35);
        tail.origin.copyFrom(tail.offset);
        tail.scale.scale(1 / 4);
        gameLayer.add(tail);
        FlxG.mouse.visible = false;
        
        restart();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        switch(state)
        {
            case Unstarted:
            {
                if (FlxG.mouse.justPressed)
                {
                    state = HidingMouse;
                    setInstructions("Ready");
                    time = 3.0;
                }
                tail.x = FlxG.mouse.x;
                tail.y = FlxG.mouse.y;
            }
            case HidingMouse:
            {
                var oldTime = time;
                time -= elapsed;
                
                if (time <= 1 && oldTime > 1)
                {
                    setInstructions("Set");
                }
                if (time <= 0)
                {
                    setInstructions("Go");
                    instructions.visible = true;
                    state = Playing;
                    time = COUNT_DOWN + 1;
                }
                tail.x = FlxG.mouse.x;
                tail.y = FlxG.mouse.y;
                final rate = 1 << (3 - Math.floor(time));
                tail.visible = time > 1 && ((rate * time) % 1) >= 0.5;
                nick.moveRandomly();
            }
            case Playing:
            {
                time -= elapsed;
                if (time < COUNT_DOWN)
                    setInstructions(Std.string(Math.ceil(time)));
                
                nick.moveRandomly();
                tail.x = FlxG.mouse.x;
                tail.y = FlxG.mouse.y;
                
                if (time < 0)
                {
                    time = 1.0;
                    state = Fail;
                    setInstructions("Out of time");
                }
                else if (FlxG.mouse.justPressed)
                {
                    nick.stop();
                    tail.visible = true;
                    FlxG.mouse.visible = true;
                    state = Results;
                    showScore();
                }
            }
            case Results | Fail:
            {
                var oldTime  = time;
                time -= elapsed;
                if (time <= 0)
                {
                    if (FlxG.mouse.justPressed)
                    {
                        // if (state == Results)
                        //     NGio.postPlayerHiscore("horse", score);
                        
                        restart();
                    }
                    
                    if(oldTime > 0)
                        setInstructions(instructions.text + "\nClick to retry");
                }
            }
        }
    }
    
    function setInstructions(msg:String)
    {
        instructions.text = msg;
        instructions.screenCenter(X);
    }
    
    function showScore()
    {
        var dis = FlxVector.get(nick.x - tail.x, nick.y - tail.y);
        score = Math.floor(dis.length * 5);
        setInstructions("Distance: " + score);
    }
    
    function restart()
    {
        score = 0;
        nick.reset(FlxG.width / 2, FlxG.height / 2);
        state = Unstarted;
        FlxG.mouse.visible = false;
    }
    
    override function close()
    {
        super.close();
        FlxG.mouse.visible = true;
    }
}

private class Nick extends FlxSprite
{
    public var bounds = FlxRect.get();
    public var rect = FlxRect.get();
    public var targetPos = FlxPoint.get();
    
    public function new()
    {
        super(FlxG.width / 2, FlxG.height / 2, "assets/images/horse/nick.png");
        
        loadGraphic(graphic.key, true, frameWidth >> 2, frameHeight);
        offset.set(540, 215);
        origin.copyFrom(offset);
        scale.scale(1 / 4);
        maxVelocity.set(100, 100);
        
        clipRect = FlxRect.get();
        rect.set
            ( -offset.x * scale.x
            , -offset.y * scale.y
            ,  width    * scale.x
            ,  height   * scale.y
            );
        
        // updateHitbox();
    }
    
    override function draw()
    {
        clipToBounds();
        super.draw();
    }
    
    override function reset(x, y)
    {
        super.reset(x, y);
        targetPos.set(x, y);
    }
    
    public function moveRandomly()
    {
        final margin = 50;
        if (Math.abs(targetPos.x - x) < 10)
            targetPos.x = bounds.x + margin + FlxG.random.float(0, bounds.width - margin * 2);
        if (Math.abs(targetPos.y - y) < 10)
            targetPos.y = bounds.y + margin + FlxG.random.float(0, bounds.height - margin * 2);
        
        final maxSpeed = maxVelocity.x;
        acceleration.x = (targetPos.x > x ? 1 : -1) * maxSpeed;
        acceleration.y = (targetPos.y > y ? 1 : -1) * maxSpeed;
    }
    
    public function stop()
    {
        velocity.set(0, 0);
        acceleration.set(0, 0);
    }
    
    public function setMaskfrom(sprite:FlxSprite)
    {
        sprite.getHitbox(bounds);
    }
    
    function clipToBounds()
    {
        var rectCopy = FlxRect.get().copyFrom(rect);
        rectCopy.x += x;
        rectCopy.y += y;
        rectCopy.intersection(bounds, clipRect);
        rectCopy.put();
        clipRect.x = (clipRect.x - x) / scale.x + offset.x;
        clipRect.y = (clipRect.y - y) / scale.y + offset.y;
        clipRect.width  /= scale.x;
        clipRect.height /= scale.y;
        clipRect = clipRect;
    }
    
    override function destroy()
    {
        super.destroy();
        bounds.put();
        rect.put();
        targetPos.put();
    }
}

private enum State
{
    Unstarted;
    HidingMouse;
    Playing;
    Results;
    Fail;
}