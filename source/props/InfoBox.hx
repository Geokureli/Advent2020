package props;

import vfx.Inline;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.text.FlxBitmapText;

typedef InfoBox = TypedInfoBox<FlxSprite>;

class TypedInfoBox<T:FlxSprite> extends FlxObject
{
    inline static var BUFFER = 2;
    inline static var BOB_DIS = 4;
    inline static var BOB_PERIOD = 2.0;
    inline static var INTRO_TIME = 0.5;
    
    static var outlineShader = new Inline();
    
    public var callback:Null<Void->Void>;
    public var timer = 0.0;
    public var introTime = 0.0;
    public var hoverDis = 20;
    
    public var target(default, null):FlxSprite;
    public var sprite(default, null):T;
    public var hitbox(default, null):FlxObject;
    public var canInteract(get, never):Bool;
    public function get_canInteract()
    {
        return (target is IInteractable) == false || (cast target:IInteractable).canInteract;
    }
    
    public function new (target:FlxSprite, ?sprite:T, ?callback:Void->Void, hoverDis = 20)
    {
        this.callback = callback;
        this.target = target;
        this.hitbox = target;
        this.sprite = sprite;
        this.hoverDis = hoverDis;
        if (target is IInteractable)
        {
            var interactable:IInteractable = cast target;
            if (interactable.hitTarget != null)
                this.hitbox = interactable.hitTarget;
        }
        super(hitbox.x, hitbox.y, hitbox.width, hitbox.height);
        #if FLX_DEBUG
        ignoreDrawDebug = true;
        #end
        
        if (sprite != null)
        {
            #if FLX_DEBUG
            sprite.ignoreDrawDebug = true;
            #end
            sprite.scale.y = 0;
        }
        
        alive = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (sprite != null && sprite.active && sprite.exists)
        {
            sprite.update(elapsed);
            sprite.offset.y = Math.round(FlxMath.fastCos(timer / BOB_PERIOD * Math.PI) * BOB_DIS);
            timer += elapsed;
            
            if (alive && introTime < 1)
                introTime += elapsed / INTRO_TIME;
            else if (!alive && introTime > 0)
                introTime -= elapsed / INTRO_TIME;
            
            sprite.scale.y = FlxEase.backOut(introTime);
            sprite.visible = sprite.scale.y > 0;
        }
    }
    
    override function draw()
    {
        super.draw();
        
        if (sprite != null && sprite.visible && sprite.exists)
        {
            // sprite.x = Math.max(sprite.width / 2, target.x + target.width / 2);
            sprite.x = target.x + (target.width - sprite.width) / 2;
            sprite.y = target.y - sprite.height - hoverDis;
            sprite.draw();
        }
    }
    
    public function interact():Void
    {
        if (callback != null)
            callback();
    }
    
    public function select()
    {
        alive = true;
        target.shader = outlineShader;
    }
    
    public function deselect()
    {
        alive = false;
        target.shader = null;
    }
    
    public function updateFollow():Void
    {
        x = hitbox.x;
        y = hitbox.y;
        width = hitbox.width;
        height = hitbox.height;
    }
}

class InfoTextBox extends TypedInfoBox<FlxBitmapText>
{
    public function new (target:FlxSprite, text:String, ?callback:Void->Void, hoverDis = 20, xOffset = 0)
    {
        var info:FlxBitmapText = null;
        if (text != null)
        {
            info = new FlxBitmapText();
            info.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            info.autoSize = true;
            info.text = text;
            info.offset.x = -xOffset;
        }
        
        super(target, info, callback, hoverDis);
    }
}