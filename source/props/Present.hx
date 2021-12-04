package props;

import data.Content;
import data.NGio;
import data.Save;
import states.OgmoState;

import flixel.FlxSprite;

typedef PresentValues = { id:String }

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
        var path = 'assets/images/props/presents/${id}.png';
        if (!data.Manifest.exists(path, IMAGE))
            path = 'assets/images/props/presents/debug.png';
        
        var opened = Save.hasOpenedPresent(id);
        // We made day 1 unlock on any advent day, so close up their present if they didn't get it.
        // if (NGio.isLoggedIn)
        //     opened = NGio.hasDayMedal(Content.getPresentIndex(id));
        
        loadGraphic(path, true, 32, 34);
        animation.add("closed", [0]);
        animation.add("opened", [1]);
        animation.add("opening", [1]);
        animation.play(opened ? "opened" : "closed");
        graphic.bitmap.fillRect(new openfl.geom.Rectangle(32, 0, 32, 2), 0x0);
        scale.set(0.5, 0.5);
        offset.x = 8;
        offset.y = -8;
        
        width = frameWidth / 2;
        (this:OgmoDecal).setBottomHeight(this.frameHeight >> 2);
        drag.set(5000, 5000);
        
        confetti = new FlxSprite(CONFETTI_PATH);
        confetti.loadGraphic(CONFETTI_PATH, true, Math.floor(confetti.width / CONFETTI_FRAMES), Std.int(confetti.height));
        confetti.offset.x = 20;
        confetti.offset.y = -(height - frameHeight - confetti.height + 20);
        confetti.animation.add("idle", [0]);
        confetti.animation.add("anim", [for (i in 0...CONFETTI_FRAMES) i], 10, false);
        confetti.kill();
    }
    
    /** Yes, this is a Simpsons reference */
    public function embiggen()
    {
        scale.set(1, 1);
        width *= 2;
        offset.x -= 4;
        immovable = true;
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
        // data.applyToSprite(present);
        return present;
    }
}