package props;

import data.Save;
import flixel.FlxSprite;
import states.OgmoState;

typedef PresentValues = { id:String }

@:forward
class Present extends flixel.FlxSprite
{
    inline static var CONFETTI_PATH = "assets/images/props/confetti/confetti.png";
    inline static var CONFETTI_FRAMES = 8;
    
    public final id:String;
    public var isOpen(get, never):Bool;
    inline public function get_isOpen() return animation.name == "opened";
    
    public var contents:FlxSprite;
    
    var confetti:FlxSprite;
    
    public function new (id:String, x = 0.0, y = 0.0)
    {
        this.id = id;
        super(x, y);
        loadGraphic('assets/images/props/presents/${id}.png', true, 32, 34);
        animation.add("closed", [0]);
        animation.add("opened", [1]);
        animation.add("opening", [1]);
        animation.play(Save.hasOpenedPresent(id) ? "opened" : "closed");
        graphic.bitmap.fillRect(new openfl.geom.Rectangle(32, 0, 32, 2), 0x0);
        
        (this:OgmoDecal).setBottomHeight(this.frameHeight >> 1);
        drag.set(5000, 5000);
        
        confetti = new FlxSprite(CONFETTI_PATH);
        confetti.loadGraphic(CONFETTI_PATH, true, Math.floor(confetti.width / CONFETTI_FRAMES), Std.int(confetti.height));
        confetti.offset.x = 10;
        confetti.offset.y = -(height - frameHeight - confetti.height + 20);
        confetti.animation.add("idle", [0]);
        confetti.animation.add("anim", [for (i in 0...CONFETTI_FRAMES) i], 10, false);
        confetti.kill();
    }
    
    public function animateOpen(callback:()->Void)
    {
        if (isOpen)
        {
            callback();
            return;
        }
        
        animation.play("opening");
        confetti.revive();
        confetti.animation.play("anim", true);
        confetti.animation.finishCallback = function(name)
        {
            confetti.kill();
            open();
            callback();
        }
    }
    
    inline public function open() animation.play("opened");
    inline public function close() animation.play("closed");
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (confetti.exists && confetti.active)
            confetti.update(elapsed);
    }
    
    override function draw()
    {
        super.draw();
        if (confetti.visible && confetti.exists)
        {
            confetti.x = x;
            confetti.y = y;
            confetti.draw();
        }
    }
    
    static public function fromEntity(data:OgmoEntityData<PresentValues>)
    {
        var present = new Present(data.values.id, data.x - 16, data.y - 17);
        data.applyToSprite(present);
        return present;
    }
}