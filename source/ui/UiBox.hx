package ui;

import flixel.FlxG;
import flixel.FlxSprite;

using flixel.util.FlxSpriteUtil;

@:forward
abstract UiBox(FlxSprite) to FlxSprite
{
    inline static var DEFAULT_BUFFER = 6.0;
    
    public var right (get, never):Float; inline function get_right () return this.x + this.width;
    public var left  (get, never):Float; inline function get_left  () return this.x;
    public var bottom(get, never):Float; inline function get_bottom() return this.y + this.height;
    public var top   (get, never):Float; inline function get_top   () return this.y;
    
    public function new(x, y, width, height)
    {
        var oldQuality = FlxG.stage.quality;
        FlxG.stage.quality = LOW;
        this = new FlxSprite(Std.int(x), Std.int(y));
        this.makeGraphic(Std.int(width), Std.int(height), 0, true, "prompt-bg");
        this.drawRoundRect(
            0,
            0,
            this.graphic.width,
            this.graphic.height,
            8,
            8,
            0xFF52294b,
            { color:0xFF928fb8, thickness:1 },
            { smoothing: false }
        );
        this.scrollFactor.set();
        FlxG.stage.quality = oldQuality;
    }
    
    inline static public function toStageCentered(width:Float, height:Float)
    {
        return toStageXYMargin((FlxG.width - width) / 2, (FlxG.height - height) / 2);
    }
    
    inline static public function toStageBuffered(buffer = DEFAULT_BUFFER)
    {
        return toStageXYMargin(buffer, buffer);
    }
    
    static public function toStageXYMargin(xMargin = DEFAULT_BUFFER, yMargin = DEFAULT_BUFFER)
    {
        return new UiBox(xMargin, yMargin, FlxG.width - xMargin * 2, FlxG.height - yMargin * 2);
    }
}