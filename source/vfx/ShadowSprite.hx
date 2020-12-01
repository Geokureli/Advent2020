package vfx;

class DitherSprite extends flixel.FlxSprite
{
    public var dither(default, null):DitherShader;
    
    public function new (x = 0.0, y = 0.0, ?graphic, pixelSize = 1)
    {
        dither = new DitherShader(pixelSize, 0x0, true);
        super(x, y, graphic);
    }
    
    override function graphicLoaded()
    {
        super.graphicLoaded();
        if (shader == null)
            shader = dither;
    }
}