package props;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;

typedef InfoBox = TypedInfoBox<FlxSprite>;

class TypedInfoBox<T:FlxSprite> extends FlxTypedSpriteGroup<T>
{
    inline static var BUFFER = 2;
    inline static var BOB_DIS = 4;
    inline static var BOB_PERIOD = 2.0;
    inline static var INTRO_TIME = 0.5;
    
    public var callback:Null<Void->Void>;
    public var timer = 0.0;
    public var introTime = 0.0;
    public var hoverDis = 20;
    
    public var sprite(get, never):T;
    inline function get_sprite() return members[0];
    
    public function new (?sprite:T, ?callback:Void->Void, x = 0.0, y = 0.0)
    {
        super(0, 0, 1);
        this.callback = callback;
        this.x = x;
        this.y = y;
        #if FLX_DEBUG
        ignoreDrawDebug = true;
        #end
        
        if (sprite != null)
        {
            add(sprite);
            #if FLX_DEBUG
            sprite.ignoreDrawDebug = true;
            #end
        }
        
        scale.y = 0;
        alive = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        offset.y = Math.round(FlxMath.fastCos(timer / BOB_PERIOD * Math.PI) * BOB_DIS);
        timer += elapsed;
        
        if (alive && introTime < 1)
            introTime += elapsed / INTRO_TIME;
        else if (!alive && introTime > 0)
            introTime -= elapsed / INTRO_TIME;
        
        scale.y = FlxEase.backOut(introTime);
        visible = scale.y > 0;
    }
    
    public function interact():Void
    {
        if (callback != null)
            callback();
    }
    
    public function updateFollow(target:FlxObject):Void
    {
        x = Math.max(width / 2, target.x + target.width / 2);
        y = target.y - hoverDis;
    }
}

class InfoTextBox extends TypedInfoBox<FlxBitmapText>
{
    public function new (text:String, ?callback:Void->Void, x = 0.0, y = 0.0, border = 1)
    {
        var info:FlxBitmapText = null;
        if (text != null)
        {
            info = new FlxBitmapText();
            info.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
            info.autoSize = true;
            info.text = text;
            info.x -= info.width / 2;
        }
        
        super(info, callback, x, y);
    }
}